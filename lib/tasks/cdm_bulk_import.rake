namespace :fromthepage do
  desc 'Import several CONTENTdm compound objects'
  task :bulk_import_cdm, [:cdm_bulk_import_id] => :environment do |t, args|
    bulk_import = CdmBulkImport.find(args.cdm_bulk_import_id.to_i)

    collection_or_set = bulk_import.collection_or_document_set
    if collection_or_set.is_a? DocumentSet
      collection = collection_or_set.collection
      document_set = collection_or_set
    else
      collection = collection_or_set
      document_set = nil
    end

    errors = {}
    imported_work_ids = []
    cdm_urls = bulk_import.cdm_urls.split(/\s/m)

    cdm_urls.each_with_index do |cdm_url, index|
      begin
        cdm_url.strip!
        print "\n[#{index+1}/#{cdm_urls.count}] attempting #{cdm_url}\n"
        at_id = ContentdmTranslator.cdm_url_to_iiif(cdm_url)
        print "\n[#{index+1}/#{cdm_urls.count}] importing #{at_id}\n"
        sc_manifest = ScManifest.manifest_for_at_id(at_id)
        work = nil
        work = sc_manifest.convert_with_collection(bulk_import.user, collection)
        if document_set
          document_set.works << work
        end
        imported_work_ids << work.id if work
        puts "#{work.title} has been imported"
        unless work.errors.blank?
          error.update(work.errors)
        end
        if ContentdmTranslator.iiif_manifest_is_cdm? at_id
          puts "Updating #{work.title} from CONTENTdm"
          ContentdmTranslator.update_work_from_cdm(work, bulk_import.ocr_correction)
        end
      rescue Exception => e
        puts "#{e.message}"
        errors.store(at_id, e.message)
        #        errors.store(at_id, e.backtrace.join("\n"))
      end
    end

    # Trigger AI Draft generation if requested
    if bulk_import.generate_ai_draft && !imported_work_ids.empty?
      puts "\n\n=== Starting AI Draft Text Generation ==="
      imported_work_ids.each do |work_id|
        work = Work.find(work_id)
        puts "Generating AI Draft text for work: #{work.title} (ID: #{work.id})"

        success_count = 0
        error_count = 0

        work.pages.each_with_index do |page, page_index|
          print "[#{page_index + 1}/#{work.pages.count}] Page #{page.id} (#{page.title}): "

          begin
            create_result = AiTranscription::Create.new(
              page: page,
              user: bulk_import.user,
              retranscribe: true
            ).call

            raise create_result.full_errors unless create_result.success?

            AiTranscription::GenerateJob.perform_now(
              user_id: bulk_import.user.id,
              ai_transcription_id: create_result.ai_transcription.id,
              page_id: create_result.ai_transcription.page_id
            )

            print "SUCCESS\n"
            success_count += 1
          rescue StandardError => e
            print "ERROR - #{e}\n#{e.message}"
            error_count += 1
          end

          # Small delay to avoid rate limiting
          sleep(0.5)
        end

        puts "AI Draft generation completed for #{work.title}: #{success_count} successful, #{error_count} errors"
      end
      puts "=== AI Draft Text Generation Complete ===\n\n"
    end

    if SMTP_ENABLED
      begin
        if errors.blank?
          AdminMailer.cdm_bulk_import_succeeded(bulk_import).deliver!
        else
          AdminMailer.cdm_bulk_import_failed(bulk_import, errors).deliver!
        end
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end

    # TODO: This patches CDM imports. It would be good to refactor it into interactor to make testing easier
    Elasticsearch::Collection::SyncJob.perform_now(
      user_id: nil,
      collection_id: collection_or_set.id,
      type: collection_or_set.is_a?(DocumentSet) ? :document_set : :collection,
      skip_collection: false
    )

    puts "CONTENTdm bulk import has completed with these errors: \n#{errors.flatten.join("\n")}"
  end
end
