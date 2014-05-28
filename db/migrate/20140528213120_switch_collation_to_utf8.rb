class SwitchCollationToUtf8 < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.tables.each do |table|
      puts "Converting #{table} to UTF-8"
      ActiveRecord::Base.connection.execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8")
    end
  end
end
