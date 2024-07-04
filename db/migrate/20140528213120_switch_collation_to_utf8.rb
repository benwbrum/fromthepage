class SwitchCollationToUtf8 < ActiveRecord::Migration[5.0]

  def change
    ActiveRecord::Base.connection.tables.each do |table|
      puts "Converting #{table} to UTF-8"
      ActiveRecord::Base.connection.execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8")
    end

    Article.where("title regexp '[^a-zA-Z0-9[:space:][:punct:]]' = 1").each { |a| print "Subject #{a.id}, #{a.title} needs title review\n" }
    Article.where("xml_text regexp '[^a-zA-Z0-9[:space:][:punct:]]' = 1").each do |a|
      print "Subject #{a.id}, #{a.title} needs content review\n"
    end
    Page.where("xml_text regexp '[^a-zA-Z0-9[:space:][:punct:]]' = 1").each do |a|
      print "Page #{a.id}, #{a.work.title}: #{a.title} needs content review\n"
    end
  end

end
