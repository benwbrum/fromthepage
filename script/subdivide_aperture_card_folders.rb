#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'

options = {
  files_per_folder: 100,
  dry_run: false,
  extensions: %w[.jpg .jpeg]
}

OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage: ruby script/subdivide_aperture_card_folders.rb --root "D:/ApertureCards"

    Moves image files in each immediate child directory of --root into subfolders of --files-per-folder.
    Each subfolder is named as: PARENT_000001_to_000100 (using filename index when available).
  BANNER

  opts.on('--root ROOT_PATH', 'Root directory containing parent folders (required).') do |value|
    options[:root] = value
  end

  opts.on('--files-per-folder N', Integer, 'Number of files per subfolder (default: 100).') do |value|
    options[:files_per_folder] = value
  end

  opts.on('--extensions x,y,z', Array, 'Comma-separated file extensions to include (default: .jpg,.jpeg).') do |value|
    options[:extensions] = value.map { |ext| ext.start_with?('.') ? ext.downcase : ".#{ext.downcase}" }
  end

  opts.on('--dry-run', 'Print planned moves without changing files.') do
    options[:dry_run] = true
  end

  opts.on('-h', '--help', 'Show this help message.') do
    puts opts
    exit
  end
end.parse!

abort('ERROR: --root is required. Use --help for usage.') unless options[:root]
abort('ERROR: --files-per-folder must be greater than 0.') unless options[:files_per_folder].positive?

root = File.expand_path(options[:root])
abort("ERROR: Root path does not exist: #{root}") unless Dir.exist?(root)

# Returns the trailing numeric index from a filename (without extension), if present.
def extract_index(filename)
  base = File.basename(filename, File.extname(filename))
  match = base.match(/(\d+)$/)
  match && match[1]
end

# Returns a range token using filename indices when present.
def range_token(files, start_seq)
  first_idx = extract_index(files.first)
  last_idx = extract_index(files.last)

  if first_idx && last_idx
    width = [first_idx.length, last_idx.length].max
    [first_idx.rjust(width, '0'), last_idx.rjust(width, '0')]
  else
    width = 6
    start_num = start_seq
    end_num = start_seq + files.length - 1
    [start_num.to_s.rjust(width, '0'), end_num.to_s.rjust(width, '0')]
  end
end

parent_dirs = Dir.children(root)
                 .map { |entry| File.join(root, entry) }
                 .select { |path| File.directory?(path) }
                 .sort

if parent_dirs.empty?
  puts "No directories found in #{root}. Nothing to do."
  exit
end

puts "Root: #{root}"
puts "Parent folders found: #{parent_dirs.length}"
puts "Files per subfolder: #{options[:files_per_folder]}"
puts "Dry run: #{options[:dry_run]}"
puts

moved_count = 0
created_count = 0

parent_dirs.each do |parent_dir|
  parent_name = File.basename(parent_dir)
  files = Dir.children(parent_dir)
             .select do |entry|
               full_path = File.join(parent_dir, entry)
               File.file?(full_path) && options[:extensions].include?(File.extname(entry).downcase)
             end
             .sort

  if files.empty?
    puts "[SKIP] #{parent_name}: no matching files at top level."
    next
  end

  puts "[PROCESS] #{parent_name}: #{files.length} file(s)"

  files.each_slice(options[:files_per_folder]).with_index do |slice, group_index|
    start_seq = group_index * options[:files_per_folder] + 1
    first_token, last_token = range_token(slice, start_seq)
    child_name = "#{parent_name}_#{first_token}_to_#{last_token}"
    child_dir = File.join(parent_dir, child_name)

    unless Dir.exist?(child_dir)
      puts "  Create: #{child_name}"
      FileUtils.mkdir_p(child_dir) unless options[:dry_run]
      created_count += 1
    end

    slice.each do |file_name|
      from = File.join(parent_dir, file_name)
      to = File.join(child_dir, file_name)

      if File.exist?(to)
        puts "  [SKIP] Destination exists: #{to}"
        next
      end

      puts "  Move: #{file_name} -> #{child_name}/"
      FileUtils.mv(from, to) unless options[:dry_run]
      moved_count += 1
    end
  end
end

puts
puts "Done. Subfolders created: #{created_count}. Files moved: #{moved_count}."
puts 'Dry run only; no changes made.' if options[:dry_run]
