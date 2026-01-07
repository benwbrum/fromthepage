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
    Current.user = work.collection.owner
    sheet = Roo::Spreadsheet.open(spreadsheet_path).sheet(0)
    headers = sheet.row(1)

    data = Hash.new { |h, k| h[k] = [] }

    (2..sheet.last_row).each do |i|
      row_values = sheet.row(i)
      row = Hash[headers.zip(row_values)]
      stock_book = row['Stock Book ID']
      # check to see whether work.pages.where(title: stock_book).count == 0 or don't add (actually use logic below on 31-32)
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
        # in the new spreadsheet, culture, and location is pair of columns.  The "Authority" column sometimes (but not always) contains semi-valid FtP wikilinks.  We will need to strip these out and use the value as the canonical name.
        # an exception to this is the case where two different tags exist.  We are waiting on clairification tehre.
        culture = wiki_link(row['Culture/Origin [tag]'], row['Culture/Origin'])
        location = wiki_link(row['Location [tag]'], row['Location'])
        # We will need to separate out column M and N based on semicolons to handle the two names and two links in e.g line 2082
        assoc = wiki_link(row['Associated name [tag]'], row['Associated Name'])
        values = [
          row['Row Number'],
          # Inventory Number (probably replaces Stock Number) appears to contain valid wikilinks.  We might consider pre-creating them to associate them with a category, otherwise we may need a second pass to categorize any uncategorized subjects.  (That might be easier)
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
      page.status = Page.statuses[:transcribed]
      page.save
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
