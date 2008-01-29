class CreateComments < ActiveRecord::Migration
	def self.up
		create_table :comments do |t|
			t.column :parent_id, :integer
			t.column :user_id, :integer
			t.column :created_at, :datetime, :null => false
			t.column :commentable_id, :integer, :null => false
			t.column :commentable_type, :string, :null => false
			t.column :depth, :integer
			t.column :title, :string
			t.column :body, :text
		end
	end
	
	def self.down
		drop_table :comments
	end
end
