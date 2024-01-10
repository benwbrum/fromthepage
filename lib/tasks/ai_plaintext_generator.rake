require 'alto_transformer'
require 'openai/text_normalizer'
require 'diff_tools'
namespace :fromthepage do

  desc "Generate AI Plaintext for Pages from ALTO XML"
  task :generate_ai_plaintext, [:work_id, :diff_level] => :environment do |t,args|
    diff_level=:none
    if !args.diff_level.nil?
      diff_level = args.diff_level.to_sym
    end

    # take a work ID/slug as an argument
    if args.work_id.match(/^\d+$/)
      work = Work.find args.work_id.to_i
    else
      work = Work.find_by_slug args.work_id
    end

    work.pages.each do |page|
      # check to see if ALTO XML exists
      if page.has_alto?
        # if it does, read the ALTO XML and generate AI Plaintext
        raw_alto = page.alto_xml
        plaintext = generate_plaintext(raw_alto, diff_level)
        if !plaintext.blank?
          # save the plaintext
          page.ai_plaintext = generate_plaintext(raw_alto, diff_level)
          page.save!
        end
      end
    end
  end

  desc "Update initial transcriptions from Alto XML"
  task :update_transcription_from_alto, [:work_id, :diff_level] => :environment do |t,args|
    diff_level=:none
    if !args.diff_level.nil?
      diff_level = args.diff_level.to_sym
    end

    # take a work ID/slug as an argument
    if args.work_id.match(/^\d+$/)
      work = Work.find args.work_id.to_i
    else
      work = Work.find_by_slug args.work_id
    end

    work.pages.each do |page|
      # check to see if ALTO XML exists
      if page.has_alto?
        # if it does, read the ALTO XML and generate AI Plaintext
        raw_alto = page.alto_xml
        # convert the alto to plaintext, using the same method as when we ingest XML files
        plaintext = generate_plaintext(raw_alto, diff_level)
        # do any additional processing here
        # save the plaintext without creating derivatives
        if !plaintext.blank?
          page.update_column(:source_text, plaintext)
        end
      end
    end
  end

  def generate_plaintext(raw_alto, diff_level)
    # convert the alto to plaintext, using the same method as when we ingest XML files
    plaintext = AltoTransformer.plaintext_from_alto_xml(raw_alto)
    # some pages are blank, so they will have no word characters in the plaintext
    # we want to skip those pages
    return nil if !plaintext.match(/\w/m)

    # do any additional processing here
    if diff_level != :none
      # normalize the plaintext
      normalized_plaintext = TextNormalizer.normalize_text(plaintext)
      # generate the diff
      new_plaintext = DiffTools.diff_and_replace(plaintext, normalized_plaintext, "🤔")
      if diff_level == :word
        new_plaintext.gsub!(/\b\w+🤔\w+\b/m, '🤔')
      end
      # replace the existing AI plaintext with the new plaintext
      plaintext = new_plaintext
    end
    plaintext
  end


end
