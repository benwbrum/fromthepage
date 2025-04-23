require 'alto_transformer'
namespace :fromthepage do
  desc "convert quartex xml to alto xml"
  task :quartex_to_alto, [:quartex_xml] => :environment do |t,args|
    if File.file?(args.quartex_xml)
      # read the quartex xml file
      quartex_xml = File.read(args.quartex_xml)
      print AltoTransformer.alto_xml_from_quartex_xml(quartex_xml)
    elsif Dir.exist?(args.quartex_xml)
      # loop through all subdirectories and files
      Dir.glob(File.join(args.quartex_xml, '**', '*')).each do |file|
        output_filename= File.join(File.dirname(file), File.basename(file, File.extname(file)) + '.alto.xml')
        if File.file?(file) && File.extname(file) == '.xml'
          # read the quartex xml file
          quartex_xml = File.read(file)
          # convert the quartex xml to alto xml
          alto_xml = AltoTransformer.alto_xml_from_quartex_xml(quartex_xml)
          # write the alto xml to a file
          File.open(output_filename, 'w') do |f|
            f.write(alto_xml)
          end
        end
      end
    end
  end



  def add_alto_xml_to_pages(collection)
    path = File.join('/tmp/', 'eehff')
    collection.works.order(:slug).each do |work|
      dirname = work.slug.gsub('-', '.').upcase
      # check to see if ALTO XML exists
      dir = File.join(path, dirname)
      if File.directory?(dir)
        work.pages.each do |page|
          # zero pad the page position to four digits
          page_position = page.position.to_s.rjust(4, '0')
          filename = "#{page_position}.alto.xml"
          if File.file?(File.join(dir, filename))
            # read the ALTO XML file
            alto_xml = File.read(File.join(dir, filename))
            # convert the alto to plaintext, using the same method as when we ingest XML files
            page.alto_xml = alto_xml
          else
            print "\n#{filename} does not exist"
          end            
        end
      else
        print "\n#{dir} does not exist"
      end
    end
  end
end
