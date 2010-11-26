class CreatePageBlocks < ActiveRecord::Migration
  def self.up
    create_table :page_blocks do |t|
      t.string  :controller
      t.string  :view
      t.string  :tag
      t.string  :description
      t.text    :html
      t.timestamps
    end
    
    add_index :page_blocks, [:controller, :view]
    
    populate
  end

  def self.down
    remove_index :page_blocks, [:controller, :view]
    drop_table :page_blocks
  end
  
  # display blocks on each screen
  # if the user is an admin, add an edit help link to the display
  def self.populate
    make_block "account", "login", "Account Login Help"
    make_block "account", "signup", "Account Sign-up Help"
    
    make_block "admin", "edit_user", "Admin Edit User Help"
    make_block "admin", "error_list", "Admin Error List Help", "top"
    make_block "admin", "interaction_list", "Admin Interaction List Help", "top"
    make_block "admin", "session_list", "Admin Session List Help", "top"
    make_block "admin", "tail_logfile", "Admin Tail Logfile Help", "top"
    
    make_block "article", "edit", "Article Edit Help"
    make_block "article", "graph", "Article Graph Help"
    make_block "article", "list", "Article List Help"
    make_block "article", "show", "Article Display Help"

    make_block "article_version", "show", "Article Version Display Help"
    make_block "article_version", "list", "Article Version List Help"
    
    make_block "category", "manage", "Category Management Help"
    
    make_block "collection", "edit", "Collection Editing Help"
    make_block "collection", "new", "Collection Creation Help"
    make_block "collection", "show", "Collection Viewing Help"
    
    make_block "dashboard", "main_dashboard", "Dashboard Help (Left Side)", "left" 
    make_block "dashboard", "main_dashboard", "Dashboard Help (Right Side)" 
    
    make_block "deed", "list", "Deed (User Activity) List Help"
    
    make_block "display", "display_page", "Single Page Reading Help (Left Side)", "left"
    make_block "display", "display_page", "Single Page Reading Help (Right Side)"
    make_block "display", "list_pages", "Work Table of Contents Help"
    make_block "display", "search", "Search Help"

    make_block "ia", "import_work", "Internet Archive Import Book Help"
    make_block "ia", "manage", "Internet Archive Manage Book Help"
  
    make_block "oai", "record_list", "OAI Record List Help"
    make_block "oai", "repository_list", "OAI Repository List Help"
    make_block "oai", "set_list", "OAI Set List Help"

    make_block "page", "edit", "Single Page Settings Help"
    make_block "page", "new", "Single Page Creation Help"
    make_block "page", "image_tab", "Single Page Image Help"

    make_block "page_block", "list", "Page Block List Help"
    make_block "page_block", "edit", "Page Block Edit Help"

    make_block "page_version", "list", "Single Page Version List Help"
    make_block "page_version", "show", "Single Page Version Display Help"
    
    make_block "static", "splash", "Splash Page Left Block", "left"
    make_block "static", "splash", "Splash Page Right Block"

    make_block "transcribe", "assign_categories", "Assign Categories Help (Left Side)", "left"
    make_block "transcribe", "assign_categories", "Assign Categories Help (Right Side)"
    make_block "transcribe", "display_page", "Transcription Page Help (Right Side)"
    make_block "transcribe", "display_page", "Transcription Page Help (Left Side)", "left"
    
    make_block "user", "profile", "User Profile View Help"
    make_block "user", "update_profile", "User Profile Edit Help"
    make_block "user", "versions", "User Edit List Help"
    
    make_block "work", "edit", "Work Settings Help"
    make_block "work", "new", "Work Creation Help"
    make_block "work", "pages_tab", "Work Page List Help"
    make_block "work", "scribes_tab", "Work Access Help"
    make_block "work", "show", "Work About Help"
    make_block "work", "versions", "Work Versions Help"
    
  end
  
  def self.make_block(controller, view, description, tag="right", default=nil)
    pb = PageBlock.new
    pb.controller=controller
    pb.view=view
    pb.tag=tag
    pb.description=description
    pb.html=default
    pb.save!
  end
end
