# namespace 'views' do
  desc 'Renames all your rhtml views to erb'

  task :rename => :environment do
  # task 'rename' do
    Dir.glob('app/views/**/*.rhtml').each do |file|
      puts `cp -v #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end
  end

desc 'Remove erb files'
task :removeerb => :environment do
  Dir.glob('app/views/**/*.erb').each do |file|
    puts `git rm #{file}`
    puts "removing #{file}"
  end
end




# end
