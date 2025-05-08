namespace :fromthepage do
  namespace :cwgk do

    desc "Create sample set of documents and entities"
    task :create_sample_set, [:source_dir,:target_dir,:number] => :environment do |t,args|
      source_dir = args.source_dir
      target_dir = args.target_dir
      number = args.number.to_i

      # find all the files in the source dir matching KYR*.xml
      all_document_files = Dir.glob(File.join(source_dir, "KYR*.xml"))
      # sample only the number we care about
      document_files = all_document_files.sample(number)
      # for each document file, copy it to the target dir
      document_files.each do |file|
        # copy the file to the target dir
        FileUtils.cp(file, target_dir)
      end

      # loop through the document files, and for each one, find the corresponding entity files
      # that start with the same prefix and end with .xml
      document_files.each do |file|
        # read the document file into a nokogiri object
        doc = Nokogiri::XML(File.read(file))
        body = doc.search('body').first
        ['placeName', 'persName', 'orgName', 'geographicalFeature'].each do |type|
          body.search(type).each do |element|
            # get the id of the element
            ref = element.attribute('ref').value
            # strip the "cwgk: prefix from the id"
            id = ref.sub('cwgk:', '')
            # compose a filename from the id
            filename = File.join(source_dir, "#{id}.xml")
            FileUtils.cp(filename, target_dir)
          end
        end
      end
      


    end


    # code to migrate data from CWGK XML files and Mashbill to FromThePage
    desc "Import CWGK XML files"
    task :import_cwgk_xml, [:xml_directory, :collection_slug] => :environment do |t,args|
      xml_directory = args.xml_directory
      collection_slug = args.collection_slug
      collection = Collection.find_by(slug: collection_slug)
      User.current_user = collection.owner
      if xml_directory.nil? || collection_slug.nil?
        puts "Usage: rake fromthepage:import_cwgk_xml[xml_directory,collection_slug]"
        puts "  xml_directory: path to the directory containing CWGK XML files"
        puts "  collection_slug: slug of the collection to import into"
        exit
      end

      id_to_title_map = {}
      valid_ids=[]
      geographic_feature = Category.create(title: "Geographic Features",collection: collection)
      organization = Category.create(title: "Organizations",collection: collection)
      people = collection.categories.find_by(title: "People")
      places = collection.categories.find_by(title: "Places")

      # We want to create subject articles from entity files; 
      # these are XML files in the directory that begin with the letters O,N,P,G
      # and end with .xml
      Dir.glob(File.join(xml_directory, "[NOPG]*.xml")).each do |file|
        id = File.basename(file).sub('.xml','')

        # first read the XML file
        file_contents = File.read(file)
        # then parse the XML file
        # use nokogiri to parse the file contents
        doc = Nokogiri::XML(file_contents)

        article = doc.search('body')
        # break each paragraph into a new line
        paras = article.search("p")
        formatted = paras.map { |p| p.text.strip.gsub(/\s+/m, ' ') }.join("\n\n")
        # TODO: test with O001001.xml

        # TODO: Sometimes bibliography is in TEI with hi and links -- we didn't implement it that way in FromThePage, so what do we do?      
        bibliography = doc.search("bibl").text.strip
        # example
  #       <bibl><hi rend="italic">Eighth Manuscript Census of the United States</hi> (1860), Population Schedules, Kentucky, Pulaski County, Somerset, District No. 1, p. 12.<lb/>
  # <hi rend="italic">Eighth Manuscript Census of the United States</hi> (1860), Slave Schedules, Kentucky, Pulaski County, Somerset, District No. 1, p. 3.<lb/>
  # <hi rend="italic">Kentucky Birth, Marriage and Death Records – Microfilm (1852-1910)</hi>, KDLA, Pulaski County Marriages, Kentucky, p. 136.<lb/>
  # "An Act to Incorporate the Buck Creek Bridge Company," <hi rend="italic">Acts of the General Assembly of the Commonwealth of Kentucky</hi>, vol. 1 (Frankfort, Ky.: A. G. Hodges, Public Printer, 1858), 169-170.<lb/>
  # "An Act for the benefit of the Somerset Academy," <hi rend="italic">Acts of the General Assembly of the Commonwealth of Kentucky</hi>, vol. 1 (Frankfort, Ky.: Wm. E. Hughes, State Printer, 1864), 463.<lb/>
  # Lewis Collins and Richard H. Collins, <hi rend="italic">Collins' Historical Sketches of Kentucky</hi>,  (Louisville: Richard H. Collins, 1877), 683.<lb/>
  # Rodger D. Tate, "Pulaski County" in <hi rend="italic">The Kentucky Encyclopedia</hi>, ed. John E. Kleber, (Lexington: University Press of Kentucky, 1992), 748.<lb/>
  # <hi rend="italic">Cyrenius Wait Papers, 1790-1950, bulk 1830-1859</hi>, University of Kentucky Special Collections, https://nyx.uky.edu/fa/findingaid/?id=xt7sn00zq188 (accessed on March 29, 2018).<lb/>
  # <hi rend="italic">Find A Grave</hi>, "Cyrenius Wait (1791-1868)," Memorial #17731805, https://www.findagrave.com/memorial/17731805/cyrenius-wait (accessed March 29, 2018).
  # </bibl>


        # type may be Person, Place, Organization, or Geographical Feature
        type = doc.search("term[type=type]").text

        if type == "Person"
          # the title is the persName element of the person element
          title = doc.search("person/persName").text.strip.gsub(/\s+/m, ' ')
          # parse out birth and death dates from event elements of the person element
          birth_date = raw_date_to_edtf(doc.search("person/event[@type='birth']")&.text.strip)
          death_date = raw_date_to_edtf(doc.search("person/event[@type='death']")&.text.strip)
          # parse out race and sex from trait elements of the person element
          gender = doc.search("person/trait[type=gender]").attr("subtype")&.text
          race = doc.search("person/trait[type=race]").attr("subtype")&.text
        elsif type == "Place"
          title = doc.search("place/placeName/location/settlement")&.text.strip.gsub(/\s+/m, ' ')
          geo = doc.search("place/placeName/location/geo")&.text.strip.gsub(/\s+/m, ' ')
          # parse out latitude and longitude from the geo element
          lat, lon = geo.split(/\s+/).map(&:strip)
        elsif type == "Organization"
          title = doc.search("org/orgName").text.strip.gsub(/\s+/m, ' ')
          begun = raw_date_to_edtf(doc.search("org/event[@type='begun']")&.text.strip)
          ended = raw_date_to_edtf(doc.search("org/event[@type='ended']")&.text.strip)
        end

        id_to_title_map[id] = title        
        valid_ids << [id.sub(/^[A-Z]0+/, '').to_i, type.downcase]

        article = Article.new
        article.title = title
        article.collection = Collection.find_by(slug: collection_slug)
        article.source_text = formatted
        article.bibliography = bibliography
        article.uri = id
        article.birth_date = birth_date if birth_date.present?
        article.death_date = death_date if death_date.present?
        article.sex = gender if gender.present?
        article.race_description = race if race.present?
        article.latitude = lat if lat.present?
        article.longitude = lon if lon.present?
        article.begun = begun if begun.present?
        article.ended = ended if ended.present?

        # then create a new subject article
        # then save the subject article
        article.save!

        if type == "Person"
          # assign the article to the People category
          article.categories << people
        elsif type == "Place"
          # assign the article to the Places category
          article.categories << places
        elsif type == "Organization"
          # assign the article to the Organizations category
          article.categories << organization
        else
          # assign the article to the Geographic Features category
          article.categories << geographic_feature
        end
      end

  
      # now load the relationships file
      relationships = YAML.load_file(File.join(xml_directory, "mashbill_relationships.yml"))

      # for each entity in the id map
      id_to_title_map.each do |raw_id, title|
        article = collection.articles.find_by(uri: raw_id)
        # strip the leading letter and zeroes from the ID
        id = raw_id.sub(/^[A-Z]0+/, '').to_i
        entity_type=article.categories.first.title.downcase.singularize
        # find the relationships in which the left entity has a matching ID
        left_relationships = relationships.select{|r| r[:left][:id] == id && r[:left][:type] == entity_type}
        # prune the right relationships to only ones that are in the list of valid IDs
        right_relationships = left_relationships.select{|r| valid_ids.include?([r[:right][:id], r[:right][:type]])}
        # now pull the relationship type and title from the right entity
        unique_relationships = right_relationships.map{|r| {type: r[:type], entity: r[:right]} }.uniq
        # for each unique relationship, write a text line with a wikilink to the entity
        lines = unique_relationships.map do |r| 
          if r[:entity][:type] == "person"
            "#{r[:type].titleize}: [[#{r[:entity][:name]} (#{r[:entity][:disambiguator]})]]"
          else
            "#{r[:type].titleize}: [[#{r[:entity][:name]}]]"
          end
        end

        if lines.count > 0
          article.source_text << "\n\nRelationships\n"
          article.source_text << lines.join("\n")
          # save the article
          article.save!
        end
      end



      temporary_path = "cwgk_import_#{Time.now.strftime('%Y%m%d%H%M%S')}"
      temp_dir = File.join('/tmp', temporary_path)
      FileUtils.mkdir_p(temp_dir)
      # we want to loop through the document files which start with CWGK
      Dir.glob(File.join(xml_directory, "KYR*.xml")).each do |file|
        id = File.basename(file).sub('.xml','')
        pdf_file = "#{id}.pdf"
        pdf_url = "http://discovery.civilwargovernors.org/files/pdf/#{pdf_file}"
        path = File.join(temp_dir, pdf_file)
        # import the work, based on examples in the document_upload methods in ingestor.rake
        # download the PDF file from the web to the temporary directory
        download = URI.open(pdf_url)
        IO.copy_stream(download, path)

        destination = ImageHelper.extract_pdf(path, false)

        # now parse the XML file for title and other attributes
        # first read the XML file
        file_contents = File.read(file)
        doc = Nokogiri::XML(file_contents)
        title=doc.search('titleStmt/title[type=main]').text
        parallel_title=doc.search('titleStmt/title[type=parallel]').text
        # TODO: parse respStmt into metadata fields
        # TODO: parse msIdentifier into metadata fields
        label_values = {}
        doc.search('respStmt').each do |respStmt|
          label_values[respStmt.search('resp').text] = respStmt.search('name').text
        end
        label_values['Parallel Title'] = parallel_title if parallel_title.present?
        creation=doc.search('profileDesc/creation')
        creation_place=creation.search('placeName').text
        creation_date=creation.search('date')
        genre=doc.search('profileDesc//term[type=genre]').text

        permission_description="This image and transcription is publicly accessible. The image appears courtesy of the repository named in the Source Description. The transcription and annotation were undertaken by Kentucky Historical Society staff, volunteers, and interns. If referencing this document title, accession number, and permanent URL."
        source_block=doc.search('msIdentifier')
        source_location=source_block.search('repository').text
        source_collection_name=source_block.search('collection').text
        source_box_folder=source_block.search('idno').text


        
        # TODO: prune cruft
        work = Work.new
        # set title and other attributes appropriately
        work.collection=collection
        work.owner=collection.owner
        work.title=title
        work.identifier=id
        work.in_scope=true
        work.location_of_composition=creation_place if creation_place.present?
        work.document_date=date_element_to_edtf(creation_date) if creation_date.present?
        work.genre=genre if genre.present?
        work.permission_description=permission_description
        work.source_location=source_location if source_location.present?
        work.source_collection_name=source_collection_name if source_collection_name.present?
        work.source_box_folder=source_box_folder if source_box_folder.present?

        work.uploaded_filename = File.basename(pdf_file)
    
        work.save!
    
        new_dir_name = File.join(Rails.root,
                                "public",
                                "images",
                                "uploaded",
                                work.id.to_s)
        print "\tconvert_to_work creating #{new_dir_name}\n"
    
        FileUtils.mkdir_p(new_dir_name)
        clean_dir=File.join(File.dirname(path),id)
        FileUtils.cp(Dir.glob(File.join(clean_dir, "*.jpg")), new_dir_name)
        Dir.glob(File.join(clean_dir, "*.jpg")).sort.each { |fn| print "\t\t\tcp #{fn} to #{new_dir_name}\n" }
    
        # at this point, the new dir should have exactly what we want-- only image files that are adequately compressed.
        filenames = Dir.glob(File.join(new_dir_name, "*")).sort
        replace_entities_with_wikilinks(doc.search('body').first, id_to_title_map)
        page_array = body_array(doc)
        text_array = []
        page_array.each do |page_elements|
          # first prune the empty elements
          text_paragraphs = []
          page_elements.keep_if{|e| e.present?}
          page_elements.each do |e|
            e.xpath('.//text()').each do |text_node|
              # remove text nodes that contain a newline character and no other text
              if text_node.content.strip.empty? && text_node.content.include?("\n")
                text_node.remove
              end
            end
            text_paragraphs << e.children.to_a.select{|n| n.present?}.map{|n| n.name=='lb' ? "\n" : n.to_s}.join("").gsub(/\n+/,"\n").strip
          end
          text_array << text_paragraphs.join("\n\n")
        end


        GC.start
        filenames.each_with_index do |image_fn,i|
          page = Page.new
          print "\t\tconvert_to_work created new page\n"
    
          page.title = "#{i+1}"
    

          # TODO -- resume clean-up
          page.base_image = image_fn
          print "\t\tconvert_to_work before Magick call \n"
          image = Magick::ImageList.new(image_fn)
          GC.start
          print "\t\tconvert_to_work calculating base and height \n"
          page.base_height = image.rows
          page.base_width = image.columns

          image = nil
          GC.start
          work.pages << page
          print "\t\tconvert_to_work added #{image_fn} to work as page #{page.title}, id=#{page.id}\n"
        end
        work.save!


        # we want to assign the last element of text_array to the last page
        last_page = work.pages.last
        last_page.source_text = text_array.last
        last_page.status = Page.statuses[:transcribed]
        last_page.save!


        # get the remaining pages excluding the last
        remaining_pages = work.pages[0..-2]

        # some of our application logic is based on a page having multiple versions, so let's add the text in a separate step
        remaining_pages.each_with_index do |page, i|
          if i <= text_array.length - 2
            # add the text to the page
            page.source_text = text_array[i]
            page.status = Page.statuses[:transcribed]
            page.save!
          end
        end
    
        work.pages.each_with_index do |page, i|
          if page.page_article_links.count > 0
            page.update_attribute(:status, Page.statuses[:indexed])
          end
        end
        work.update_statistic

        



      end
    end


    def split_doc_on_pb(doc)
      page_number = 1

      # Loop while there are still <pb/>s in the document
      while (pb = doc.at('pb'))
        parent = pb.parent
        next unless parent

        # Create two new elements of the same name and copy attributes
        node1 = Nokogiri::XML::Node.new(parent.name, doc)
        node2 = Nokogiri::XML::Node.new(parent.name, doc)
        parent.attribute_nodes.each do |attr|
          node1[attr.name] = attr.value
          node2[attr.name] = attr.value
        end

        # Add page number as an attribute (you can customize this)
        node1['data-page'] = page_number.to_s
        node2['data-page'] = (page_number + 1).to_s

        # Split children
        before = true
        parent.children.each do |child|
          if child == pb
            before = false
            next  # skip the <pb/>
          end
          (before ? node1 : node2).add_child(child.dup)
        end

        # Replace the parent with the two new nodes
        parent.add_next_sibling(node2)
        parent.add_next_sibling(node1)
        parent.remove

        page_number += 1
      end
    end

    def replace_entities_with_wikilinks(body, id_to_title_map)
      # for the element types placeName persName orgName geographicalFeature
      # find all elements of that type
      ['placeName', 'persName', 'orgName', 'geographicalFeature'].each do |type|
        body.search(type).each do |element|
          # get the text of the element
          text = element.text.strip
          # get the id of the element
          ref = element.attribute('ref').value
          # strip the "cwgk: prefix from the id"
          id = ref.sub('cwgk:', '')
          # get the title from the id_to_title_map
          title = id_to_title_map[id]
          # create a new text node
          text = "[[#{title}|#{text}]]"
          text_node = Nokogiri::XML::Text.new(text, body)
          # replace the element with the text node
          element.replace(text_node)
        end
      end
    end
          
          

          

    def body_array(doc)
      pages=[]
      split_doc_on_pb(doc)
      current_page_number = 1
      page = []
      doc.search('body').each do |body|
        body.children.each do |node|
          this_page_number = node.attribute('data-page')&.value
          if this_page_number && this_page_number.to_i > current_page_number
            current_page_number = this_page_number.to_i
            pages << page
            page = []
          end
          page << node
        end
      end
      pages << page
      pages
    end

    def date_element_to_edtf(date_element)
      date_element.attr('when')&.text
    end
    
    def raw_date_to_edtf(raw_date)
      # Convert a raw date string to an EDTF date string
      # This is a simplified example; you may need to adjust the parsing logic
      if raw_date.start_with?('c')
        return "#{raw_date[1..-1]}?"
      else
        return raw_date
      end
    end
  end
end
