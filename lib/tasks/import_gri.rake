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

    work_pages = work.pages.to_a

    (2..sheet.last_row).each do |i|
      row_values = sheet.row(i)
      row = Hash[headers.zip(row_values)]
      
      # Parse stock_book_page from FTP_Page Title
      # Input format: "Box 97, Page 312 (gri_2017_m_38_b97_0312)"
      # Extract: "gri_2017_m_38_b97_0312"
      ftp_page_title = row['FTP_Page Title']
      stock_book_page = ftp_page_title.to_s.match(/\(([^)]+)\)/)&.captures&.first
      
      next if stock_book_page.nil?
      
      # Check if stock_book_page matches any page title before adding to hash
      page_exists = work_pages.any? do |p|
        p.title == stock_book_page ||
          File.basename(p.base_image.to_s, File.extname(p.base_image.to_s)) == stock_book_page
      end
      
      next unless page_exists
      
      data[stock_book_page] << row
    end

    data.each do |stock_book_page, rows|
      page = work_pages.find do |p|
        p.title == stock_book_page ||
          File.basename(p.base_image.to_s, File.extname(p.base_image.to_s)) == stock_book_page
      end

      unless page
        puts "Page not found for Stock Book Page #{stock_book_page}"
        next
      end

      headers_out = [
        'Row',
        'Inventory<br/>Number',
        'Verbatim Description',
        'Object Type(s)',
        'Culture(s)',
        'Culture(s) Authority',
        'Location(s)',
        'Associated Name(s)',
        'Right<br/>Margin<br/>Price'
      ]

      lines = []
      lines << '| ' + headers_out.join(' | ') + ' |'
      lines << '| ' + headers_out.map { '---' }.join(' | ') + ' |'

      # Sort rows by Row Number order per page
      sorted_rows = rows.sort_by { |row| row['Row'].to_i }

      sorted_rows.each do |row|
        location = wiki_link(row['Location(s) Authority'], row['Location(s)'])
        assoc = multi_wiki_link(row['Associated Name(s)_Authoritative'], row['Associated Name(s)'])
        # Replace < and > with HTML entities to avoid HTML validation issues
        verbatim_desc = row['Verbatim Description'].to_s.gsub('<', '&lt;').gsub('>', '&gt;')
        values = [
          row['Row'],
          row['Inventory Number'],
          verbatim_desc,
          row['Object Type(s)'],
          row['Culture(s)'],
          row['Culture(s) Authority'],
          location,
          assoc,
          row['Right Margin Price']
        ]
        lines << '| ' + values.map { |v| v.to_s }.join(' | ') + ' |'
      end

      page.source_text = lines.join("\n")
      page.status = Page.statuses[:transcribed]
      begin 
        page.save
      rescue => ex
	      #binding.pry
      end
      puts "Updated page #{page.title} with #{rows.length} rows"
    end
  end

  def wiki_link(tag, value)
    if tag.present? && value.present?
      # If tag doesn't contain square brackets, return plain value
      return value.to_s unless tag.to_s.include?('[[') || tag.to_s.include?(']]')
      
      # Strip square brackets from tag if present
      cleaned_tag = tag.to_s.gsub(/^\[\[|\]\]$/, '')
      "[[#{cleaned_tag}|#{value}]]"
    else
      value.to_s
    end
  end

  def multi_wiki_link(tags, values)
    return values.to_s if tags.blank? || values.blank?
    
    tag_array = tags.split(';').map(&:strip)
    value_array = values.split(';').map(&:strip)
    
    links = tag_array.zip(value_array).map do |tag, value|
      if tag.present? && value.present?
        # Strip square brackets from tag if present
        cleaned_tag = tag.to_s.gsub(/^\[\[|\]\]$/, '')
        "[[#{cleaned_tag}|#{value}]]"
      else
        value.to_s
      end
    end
    
    links.join('; ')
  end
end
