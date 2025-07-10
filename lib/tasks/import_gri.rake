namespace :fromthepage do
  desc 'Import GRI spreadsheet and update pages with markdown tables'
  task :import_GRI, [:spreadsheet_path, :work_id] => :environment do |t, args|
    require 'roo'
    spreadsheet_path = args[:spreadsheet_path]
    work_id = args[:work_id]
    if spreadsheet_path.nil? || work_id.nil?
      puts 'Usage: rake fromthepage:import_GRI[spreadsheet_path,work_id]'
      next
    end

    work = Work.find(work_id)
    sheet = Roo::Spreadsheet.open(spreadsheet_path).sheet(0)
    headers = sheet.row(1)

    data = Hash.new { |h, k| h[k] = [] }

    (2..sheet.last_row).each do |i|
      row_values = sheet.row(i)
      row = Hash[headers.zip(row_values)]
      stock_book = row['Stock Book ID']
      data[stock_book] << row
    end

    work_pages = work.pages.to_a

    data.each do |stock_book_id, rows|
      page = work_pages.find do |p|
        p.title == stock_book_id ||
          File.basename(p.base_image.to_s, File.extname(p.base_image.to_s)) == stock_book_id
      end

      unless page
        puts "Page not found for Stock Book ID #{stock_book_id}"
        next
      end

      headers_out = [
        'Row Number',
        'Stock Number',
        'Verbatim Object Description',
        'Object Type',
        'Culture/Origin',
        'Location',
        'Associated Name',
        'Right Margin Price'
      ]

      lines = []
      lines << '| ' + headers_out.join(' | ') + ' |'
      lines << '| ' + headers_out.map { '---' }.join(' | ') + ' |'

      rows.each do |row|
        culture = wiki_link(row['Culture/Origin [tag]'], row['Culture/Origin'])
        location = wiki_link(row['Location [tag]'], row['Location'])
        assoc = wiki_link(row['Associated name [tag]'], row['Associated Name'])
        values = [
          row['Row Number'],
          row['Stock Number'],
          row['Verbatim Object Description'],
          row['Object Type'],
          culture,
          location,
          assoc,
          row['Right Margin Price']
        ]
        lines << '| ' + values.map { |v| v.to_s }.join(' | ') + ' |'
      end

      page.source_text = lines.join("\n")
      if !page.save 
	binding.pry 
      end
      puts "Updated page #{page.title} with #{rows.length} rows"
    end
  end

  def wiki_link(tag, value)
    if tag.present? && value.present?
      "[[#{tag}|#{value}]]"
    else
      value.to_s
    end
  end
end
