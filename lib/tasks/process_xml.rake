namespace :fromthepage do
  desc "take the ryan white metadata xml file and generate names and descriptions"
  task process_xml: :environment do
    doc = File.open("tmp/RWL-box24.xml") { |f| Nokogiri::XML(f) }
    errfile = File.new("tmp/rwl4/image_processing_errors.log", 'w')
    # for each record 
    doc.xpath("//record").each_with_index do |record, i|
      # get a work name
      name = record.xpath("title").text
      # create a directory with the work name
      prefix = (i / 100).to_s.rjust(6, '0') 
      directory = "tmp/rwl/" + prefix + "/" + name
      # if directory exists, break out of loop
      if Dir.glob("*/#{name}").count > 0
        break
      else
        directory = "tmp/rwl4/" + prefix + "/" + name
      end
      begin
        FileUtils.mkdir_p(directory)
      rescue => e
        print "\n#{e}"
        directory = "#{directory}.dupe"
        FileUtils.mkdir_p(directory)
      end
      file = File.new(directory + "/metadata.yaml", 'w')
      # get the metadata and write it to a yaml file.
      created = record.xpath("created").text
      metadata = {}
      metadata["identifier"] = name
      metadata["created_on_date"] = created
      author = record.xpath("creator").min_by {|a| a.text.size}.text + " "
      author = author.gsub ";", ","
      metadata["author"] = author
      metadata["description"] = record.xpath("extent").text
      metadata["permission_description"] = "http://rightsstatements.org/page/InC-EDU/1.0/?language=en"
      recipient_orig = record.xpath("unmapped")[1]
      split_recipients = recipient_orig.text.split(";")
      recipients=[]
      for r in split_recipients
        if r.include? ","
          recipients << "#{r.split(", ")[1].strip} #{r.split(", ")[0].strip}"
        else
          recipients << "#{r}"
        end
      end
      if recipients.empty?
        recipients << "[unamed recipient]"
      end
      if author.strip.empty?
        author = "[unamed sender] "
      end
      title = author.truncate(35, separator: ' ') +  "to " + recipients.join(", ")
      unless created.blank?
        if (/^\d{4}\-\d{1,2}\-\d{1,2}$/.match(created))
          title << " on #{Date.parse(created).strftime("%B %d, %Y")}"
        elsif (/^\d{4}\-\d{1,2}\$/.match(created))
          title << " on #{Date.strptime(created, "%Y-%m").strftime("%B %Y")}"
        else
          title << " on #{created}"
        end
      end
      metadata["title"] = title
  
      spatial = record.xpath("spatial").text
      metadata["location_of_composition"] = spatial
      location_set = ""
      if spatial.include? "Indiana" then
        location_set = "Indiana"
      elsif spatial.include? "United States" then
        location_set = "United States"
      else
        location_set = "Other"
      end
    
      date_set = ""
      if created.blank? 
        date_set = "undated"
      elsif (m = /^\d{4}/.match(created)) 
        date_set = m.to_s
      else
        date_set = "undated"
      end 
      metadata['document_set'] = [location_set, date_set]
      file.write(metadata.to_yaml)
      file.close
      # get each page for the work
      # for each page
      record.xpath("structure/page").each do |page|
        # get the filename for the page 
         pageptr = page.xpath("pageptr").first.text #filename, sorta
         # get the page name 
         # add 1 to pageptr slap a .jp2 on the end
         filename = "#{(pageptr.to_i + 1).to_s}"
         # convert the image file to the page_name.jpg in the directory above
         # convert images/10099.jp2 -quality 20 directory/10099.jpg
         convertcommand = "convert RWL-IL-Images/#{filename}.jp2 -quality 20 #{directory}/#{filename}.jpg"
         unless system(convertcommand)
            #write diretory name/id to a file
            errfile.write("bad directory #{name}\n")
            errfile.write("bad image #{filename}\n")
            #delete directory
            system("rm -r #{directory}")
            #break out of each
            break
           end
      end #end page
    end #end record
    errfile.close
  end #end task
end #end namespace