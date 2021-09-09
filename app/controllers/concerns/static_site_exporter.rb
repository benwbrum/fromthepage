module StaticSiteExporter
  include AbstractXmlHelper



  def export_static_site(dirname:, out:, collection:)
    write_gemfile(dirname,out,collection)
    write_subject_layout(dirname,out,collection)
    write_work_layout(dirname,out,collection)
    write_listing_layout(dirname,out,collection)
    write_tree_include(dirname,out,collection)
    write_index_markdown(dirname, out, collection)
    write_config_yaml(dirname, out, collection)
    write_work_listing(dirname, out, collection)
    write_subject_listing(dirname, out, collection)
    write_contributor_page(dirname, out, collection)

    collection.works.each do |work|
      write_work_page(dirname, out, collection, work)
    end

    collection.articles.each do |subject|
       write_subject_page(dirname, out, collection, subject)
    end
  end



private
  GEMFILE_CONTENTS = <<EOF
source "https://rubygems.org"
# Hello! This is where you manage which Jekyll version is used to run.
# When you want to use a different version, change it below, save the
# file and run `bundle install`. Run Jekyll with `bundle exec`, like so:
#
#     bundle exec jekyll serve
#
# This will help ensure the proper Jekyll version is running.
# Happy Jekylling!
gem "jekyll", "~> 4.0.1"
# This is the default theme for new Jekyll sites. You may change this to anything you like.
gem "minima", "~> 2.5"
gem "minimal-mistakes-jekyll"
# If you want to use GitHub Pages, remove the "gem "jekyll"" above and
# uncomment the line below. To upgrade, run `bundle update github-pages`.
# gem "github-pages", group: :jekyll_plugins
# If you have any plugins, put them here!
group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
install_if -> { RUBY_PLATFORM =~ %r!mingw|mswin|java! } do
  gem "tzinfo", "~> 1.2"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :install_if => Gem.win_platform?
EOF

  SUBJECT_LAYOUT_CONTENTS =<<EOF_LAYOUT
---
layout: archive
---

{{ content }}

<ul>
  {% for page_link in page.page_links %}
    <li>
      <a href="/{{page_link.work_url}}REPLACEME{{page_link.page_anchor}}">{{ page_link.work_title }} {{ page_link.page_title }}</a> 
    </li>
  {% endfor %}
</ul>
EOF_LAYOUT


  WORK_LAYOUT_CONTENTS =<<EOF_WORK_LAYOUT
---
layout: archive
---

{{ content }}

<dl>
  {% for metadata in page.metadata %}
    <dt class="fas">
      {{ metadata.label }}
    </dt>
    <dd>
      {{ metadata.value }}
    </dd>
  {% endfor %}
</dl>
EOF_WORK_LAYOUT

  LISTING_LAYOUT_CONTENTS =<<EOF_LISTING_LAYOUT
---
layout: archive
---

{{ content }}


{% assign tree = page.listing %}
{% include tree.html %}

EOF_LISTING_LAYOUT

  TREE_INCLUDE_CONTENTS =<<EOF_TREE_INCLUDE
<ul>
  {% for item in tree %}
    <li>
      {% if item.url %}
        <a href="{{ item.url }}">
          {{ item.title }}
        </a>
      {% else %}
          {{ item.title }}
      {% endif %}
    </li>

    {% if item.has_children %}
      {% assign tree = item.children %}
      {% include tree.html %}
    {% endif %}
  {% endfor %}
</ul>
EOF_TREE_INCLUDE

  def category_to_tree(category) 
    element = {}
    element['title'] = category.title
    children = []

    if category.children.any? || category.articles.any?
      element['has_children'] = true
    end
    category.children.each do |child|
      children << category_to_tree(child)
    end

    category.articles.each do |subject|
      node = {
        'title' => subject.title,
        'url' => "/pages/subjects/#{subject.id}"
      }
      children << node
    end

    element['children'] = children

    element
  end

  def write_gemfile(dirname, out, collection)
    path = File.join dirname, "Gemfile"
    out.put_next_entry(path)
    out.write(GEMFILE_CONTENTS)
  end

  def write_work_layout(dirname, out, collection)
    path = File.join dirname, '_layouts', 'work.html'
    out.put_next_entry(path)
    out.write(WORK_LAYOUT_CONTENTS)
  end

  def write_subject_layout(dirname, out, collection)
    path = File.join dirname, '_layouts', 'subject.html'
    out.put_next_entry(path)
    out.write(SUBJECT_LAYOUT_CONTENTS.gsub('REPLACEME', '#'))
  end

  def write_listing_layout(dirname, out, collection)
    path = File.join dirname, '_layouts', 'listing.html'
    out.put_next_entry(path)
    out.write(LISTING_LAYOUT_CONTENTS)
  end

  def write_tree_include(dirname, out, collection)
    path = File.join dirname, '_includes', 'tree.html'
    out.put_next_entry(path)
    out.write(TREE_INCLUDE_CONTENTS)
  end

  def write_config_yaml(dirname, out, collection)
    path = File.join dirname, "_config.yml"
    out.put_next_entry(path)
    site_config = {
      'title' => collection.title,
      'email' => collection.owner.email,
      'description' => collection.intro_block,
      'theme' => 'minimal-mistakes-jekyll',
      'plugins' => ['jekyll-feed'], # todo jekyll-remote-theme
      'defaults' => [
        { 'scope' => 
          { 
            'path' => ''
          },
          'values' => 
          { 
            'layout' => 'home', 
            'sidebar' => 
            { 
              'nav' => 'main'
            }
          }
        }
      ]
    }
    out.write(site_config.to_yaml)
  end

  def write_index_markdown(dirname, out, collection)
    path = File.join dirname, "index.md"
    out.put_next_entry(path)
    out.write("---\n"+collection.intro_block)
  end

  def write_navigation_yaml(dirname, out, collection)
    path = File.join dirname, "_data", "navigation.yml"
    out.put_next_entry(path)

    work_nav = []
    collection.works.sort.each do |work|
      work_nav << {
        'title' => work.title,
        'url' => "/pages/works/#{work.slug}"
      }
    end
 #   work_nav.sort!

    subject_nav = []
    collection.articles.sort.each do |subject|
      subject_nav << {
        'title' => subject.title,
        'url' => "/pages/subjects/#{subject.id}"
      }
    end
#    subject_nav.sort!

    navigation = {
      'main' =>
        [
          { 
            'title' => 'Works',
            'url' => '/pages/work-list',
            'children' => work_nav
          },
          {
            'title' => 'Subjects',
            'url' => '/pages/subject-list',
            'children' => subject_nav
          },
          {
            'title' => 'About',
            'url' => '/pages/about'
          }
        ]
    }
    out.write(navigation.to_yaml)
  end

  def write_work_listing(dirname, out, collection)
    path = File.join dirname, "pages", "work-list.md"
    out.put_next_entry(path)
    work_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Works'
    }
    work_listing_frontmatter['listing'] = collection.works.map do |work| 
      { 
        'title' => work.title, 
        'url' => "/pages/works/#{work.slug}"
      } 
    end
    out.write(work_listing_frontmatter.to_yaml+"\n---\n")
  end

  def write_subject_listing(dirname, out, collection)
    path = File.join dirname, "pages", "subject-list.md"
    out.put_next_entry(path)
    subject_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Subjects'
    }
    tree = []
    collection.categories.each do |category|
      tree << category_to_tree(category)
    end

    uncategorized_articles = collection.articles.where.not(:id => collection.articles.joins(:categories).pluck(:id))
    if uncategorized_articles.count > 0
      children = []
      uncategorized_articles.each do |subject|
        children << {
          'title' => subject.title,
         'url' => "pages/subjects/#{subject.id}"
         }
      end

      uncategorized = { 
        'title' => 'Uncategorized',
        'has_children' => true,
        'children' => children
      }
      tree << uncategorized
    end

    subject_listing_frontmatter['listing'] = tree
    out.write(subject_listing_frontmatter.to_yaml+"\n---\n")
  end

  def write_contributor_page(dirname, out, collection)
    path = File.join dirname, "pages", "about.md"
    out.put_next_entry(path)
    contributor_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Contributors'
    }
    contributor_ids = collection.deeds.group(:user_id).count.sort{|a,b| b[1] <=> a[1]}.map{|e| e[0]}
    listing = []
    contributor_ids.each do |user_id|
      user = User.find(user_id)
      if user.real_name.blank?
        listing << { 'title' => user.display_name}
      else
        listing << { 'title' => user.real_name}
      end
    end
    contributor_listing_frontmatter['listing'] = listing
    out.write(contributor_listing_frontmatter.to_yaml+"\n---\n")
  end

  def write_work_page(dirname, out, collection, work)
    path = File.join dirname, 'pages', 'works', "#{work.slug}.md"
    out.put_next_entry path

    metadata = []
    if work.original_metadata
      metadata += JSON[work.original_metadata]
    end
    work_metadata = work.attributes.except("id", "title", "next_untranscribed_page_id", "description","created_on", "transcription_version", "owner_user_id", "restrict_scribes", "transcription_version", "transcription_conventions", "collection_id", "scribes_can_edit_titles", "supports_translation", "translation_instructions", "pages_are_meaningful", "ocr_correction", "slug", "picture", "featured_page", "original_metadata", "in_scope").delete_if{|k,v| v.blank?}

    work_metadata.each_pair { |label,value| metadata << { "label" => label.titleize, "value" => value.to_s } }

    frontmatter = {
      'title' => work.title,
      'layout' => 'work',
      'metadata' => metadata
    }

    text = ApplicationController.new.render_to_string(
      :template => 'export/show', 
      :formats => [:html], 
      :work_id => work.id, 
      :layout => false, 
      :encoding => 'utf-8',
      :assigns => {
        :collection => work.collection,
        :work => work,
        :export_user => nil,
        :target => :jekyll
      }
    )
    text.gsub!(/^\s+/,'')
    markdown = frontmatter.to_yaml+"\n---\n"+text
    out.write(markdown)
  end

  def write_subject_page(dirname, out, collection, subject)
    path = File.join dirname, 'pages', 'subjects', "#{subject.id}.md"
    out.put_next_entry path

    text = xml_to_html(subject.xml_text, false, :jekyll, collection) # TODO convert to HTML
    page_links = []
    subject.page_article_links.each do |link|
      page_links << {
        'work_title' => link.page.work.title,
        'work_url' => "pages/works/#{link.page.work.slug}",
        'page_title' => link.page.title,
        'page_anchor' => "page-#{link.page_id}"
      }
    end
    frontmatter = {
      'title' => subject.title,
      'layout' => 'subject',
      'page_links' => page_links
    }


    markdown = frontmatter.to_yaml+"\n---\n"+text
    out.write(markdown)
  end




end