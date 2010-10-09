class PopulateOaiRepositories < ActiveRecord::Migration
  def self.up
    ia = OaiRepository.new
    ia.url = 'http://www.archive.org/services/oai.php'
    ia.save

  end

  def self.down
  end
end
