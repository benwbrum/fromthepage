class SwitchCollationToUtf8 < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.tables.each do |table|
      puts "Converting #{table} to UTF-8"
      ActiveRecord::Base.connection.execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8")
    end
    
    Article.where("title regexp '[^a-zA-Z0-9[:space:][:punct:]]' = 1").each { |a| print "Subject #{a.id}, #{a.title} needs title review\n" }
    Article.where("xml_text regexp '[^a-zA-Z0-9[:space:][:punct:]]' = 1").each { |a| print "Subject #{a.id}, #{a.title} needs content review\n" }
    Page.where("xml_text regexp '[^a-zA-Z0-9[:space:][:punct:]]' = 1").each { |a| print "Page #{a.id}, #{a.work.title}: #{a.title} needs content review\n" }

  end
end
