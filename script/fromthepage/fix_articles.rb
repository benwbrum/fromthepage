#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../config/environment'
p 'FIX ARTICLES'
p '==================='
p 'STATS'
#what are we dealing with?
all_pages = Page.find :all
tbd_pages = all_pages.reject { |p| !p.source_text || !p.source_text.include?("DELETED") }
p "All Pages: #{all_pages.size}"
p "Pages containing TO_BE_DELETED in text: #{tbd_pages.size}"
p ""
User.current_user = User.find(14)
all_articles = Article.find :all
orphan_articles = 
  Article.find(:all, 
               { :joins => 'LEFT JOIN page_article_links pal on articles.id = pal.article_id',
                :conditions => 'pal.id is null' })
good_orphan_articles =
 orphan_articles.reject { |a| a.source_text.blank? }
tbd_articles = 
  Article.find(:all, :conditions => "title like 'TO_BE_DELETED%'")
good_tbd_articles =
 tbd_articles.reject { |a| a.source_text.blank? }
p "All Articles: #{all_pages.size}"
p "Orphan Articles: #{orphan_articles.size}"
p "Orphan Articles containing text: #{good_orphan_articles.size}"
p "Articles containing TO_BE_DELETED: #{tbd_articles.size}"
p "TBD Articles containing text: #{good_tbd_articles.size}"
p '==================='
p 'Orphans with text:'
good_orphan_articles.each do |a|
  p '-----------------'
  p a.source_text
end
p '==================='
p 'TBD with text:'
good_tbd_articles.each do |a|
  p '-----------------'
  p a.source_text
end

count_before_tbd_fix = Article.count
p '==================='
p 'FIXING'
p '==================='
p ''
p 'RENAMING TBD'
tbd_articles.each do |a|
  p '-----------------'
  versions = a.article_versions
  versions.reverse!
  p "investigating #{a.title} with #{versions.size} versions"
  if versions.size > 0
    versions.each do |v|
      if v.title.include? "TO_BE_DELETED"
        if v.version == 0
          # delete it anyway
          a.title = v.title.gsub "TO_BE_DELETED:", ""
          p "renaming to #{a.title}"
          a.save!
        else  
          p "skipping version #{v.version} with title #{v.title}"
        end
      else
        p "renaming to #{v.title} from version #{v.version}"
        a.title = v.title
        a.save!
        break
      end
    end #do
  else
    p "No version info for #{a.title}"
    a.title.gsub! "TO_BE_DELETED:", ""
    if a.title == "TO_"
      p "Deleting #{a.title}"
      if a.source_text.blank?
        a.destroy
      else
        p "Article has text -- save it instead"
        a.save!
      end
    else
      p "Retaining #{a.title}"
      a.save!
    end
  end 
end
p '==================='
p ''
p 'DELETING ORPHANS'

count_before_orphan_fix = Article.count
orphan_articles.each do |orphan| orphan 
  if orphan.source_text.blank?
    orphan.destroy
  end
end
p '==================='
p ''
p 'REGENERATING PAGES'
p '==================='
p ''
count_before_page_save = Article.count
all_pages.each do |page|
  page.source_text = page.source_text
  page.save!
end
count_after_page_save = Article.count
count_orphans_after_page_save = 
  Article.count(:all, 
               { :joins => 'LEFT JOIN page_article_links pal on articles.id = pal.article_id',
                :conditions => 'pal.id is null' })

p '==================='
p 'Article counts:'
p "Before TBD cleanup: #{count_before_tbd_fix}"
p "Before Orphan cleanup: #{count_before_orphan_fix}"
p "Before Page re-gen: #{count_before_page_save}"
p "After Page re-gen: #{count_after_page_save}"
p "Orphans After Page re-gen: #{count_orphans_after_page_save}"
p '==================='

#p 'CHECKING FOR NEW ORPHANS'
