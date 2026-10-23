#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'rbconfig'

options = {
  output_root: 'C:/Users/benwb/Documents/ApertureCards',
  dry_run: false,
  overwrite: false
}

OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage: ruby script/zip_aperture_card_subfolders.rb --root "D:/ApertureCards"

    For each box folder under --root, zip each immediate child subfolder
    and write zip files into --output-root/<box_folder>/.
  BANNER

  opts.on('--root ROOT_PATH', 'Root directory containing box folders (required).') do |value|
    options[:root] = value
  end

  opts.on('--output-root OUTPUT_PATH', 'Destination for zip files (default: C:/Users/benwb/Documents/ApertureCards).') do |value|
    options[:output_root] = value
  end

  opts.on('--overwrite', 'Overwrite existing zip files.') do
    options[:overwrite] = true
  end

  opts.on('--dry-run', 'Print planned actions without creating zip files.') do
    options[:dry_run] = true
  end

  opts.on('-h', '--help', 'Show this help message.') do
    puts opts
    exit
  end
end.parse!

abort('ERROR: --root is required. Use --help for usage.') unless options[:root]

unless RbConfig::CONFIG['host_os'].downcase.include?('mswin') || RbConfig::CONFIG['host_os'].downcase.include?('mingw')
  abort('ERROR: This script is intended to run on Windows (uses PowerShell Compress-Archive).')
end

root = File.expand_path(options[:root])
output_root = File.expand_path(options[:output_root])

abort("ERROR: Root path does not exist: #{root}") unless Dir.exist?(root)

box_dirs = Dir.children(root)
              .map { |entry| File.join(root, entry) }
              .select { |path| File.directory?(path) }
              .sort

if box_dirs.empty?
  puts "No box folders found in #{root}. Nothing to do."
  exit
end

puts "Root: #{root}"
puts "Output root: #{output_root}"
puts "Box folders found: #{box_dirs.length}"
puts "Dry run: #{options[:dry_run]}"
puts "Overwrite: #{options[:overwrite]}"
puts

zip_count = 0
skip_count = 0

box_dirs.each do |box_dir|
  box_name = File.basename(box_dir)
  subfolders = Dir.children(box_dir)
                  .map { |entry| File.join(box_dir, entry) }
                  .select { |path| File.directory?(path) }
                  .sort

  if subfolders.empty?
    puts "[SKIP] #{box_name}: no subfolders found."
    next
  end

  box_output_dir = File.join(output_root, box_name)
  FileUtils.mkdir_p(box_output_dir) unless options[:dry_run]

  puts "[PROCESS] #{box_name}: #{subfolders.length} subfolder(s)"

  subfolders.each do |subfolder_path|
    subfolder_name = File.basename(subfolder_path)
    zip_path = File.join(box_output_dir, "#{subfolder_name}.zip")

    if File.exist?(zip_path) && !options[:overwrite]
      puts "  [SKIP] Zip exists: #{zip_path} (use --overwrite to replace)"
      skip_count += 1
      next
    end

    puts "  Zip: #{subfolder_name} -> #{zip_path}"
    next if options[:dry_run]

    escaped_subfolder = subfolder_path.gsub("'", "''")
    escaped_zip = zip_path.gsub("'", "''")
    force_part = options[:overwrite] ? ' -Force' : ''
    ps_command = "Compress-Archive -LiteralPath '#{escaped_subfolder}' -DestinationPath '#{escaped_zip}' -CompressionLevel Optimal#{force_part}"

    success = system('powershell', '-NoProfile', '-Command', ps_command)
    abort("ERROR: Failed to zip folder: #{subfolder_path}") unless success

    zip_count += 1
  end
end

puts
puts "Done. Zips created: #{zip_count}. Skipped existing: #{skip_count}."
puts 'Dry run only; no zip files were created.' if options[:dry_run]
