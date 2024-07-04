module StaticSiteExporter

  include AbstractXmlHelper

  def export_static_site(dirname:, out:, collection:)
    write_gemfile(dirname, out, collection)
    write_subject_layout(dirname, out, collection)
    write_work_layout(dirname, out, collection)
    write_listing_layout(dirname, out, collection)
    write_tree_include(dirname, out, collection)
    write_footer_include(dirname, out, collection)
    write_index_markdown(dirname, out, collection)
    write_config_yaml(dirname, out, collection)
    write_navigation_yaml(dirname, out, collection)
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

  GEMFILE_CONTENTS = <<~EOF
    source "https://rubygems.org"

    gem "github-pages"

    # If you want to use GitHub Pages, remove the "gem "jekyll"" above and
    # uncomment the line below. To upgrade, run `bundle update github-pages`.
    # gem "github-pages", group: :jekyll_plugins
    # If you have any plugins, put them here!
    group :jekyll_plugins do
      gem "jekyll-feed", "~> 0.12"
      gem "jekyll-remote-theme"
    end

    gem "jekyll-include-cache", group: :jekyll_plugins

  EOF

  SUBJECT_LAYOUT_CONTENTS = <<~EOF_LAYOUT
    ---
    layout: archive
    ---

    {{ content }}

    <ul>
      {% for page_link in page.page_links %}
        <li>
          <a href="{{page_link.work_url  | relative_url}}REPLACEME{{page_link.page_anchor}}">{{ page_link.work_title }} {{ page_link.page_title }}</a>#{' '}
        </li>
      {% endfor %}
    </ul>
  EOF_LAYOUT

  WORK_LAYOUT_CONTENTS = <<~EOF_WORK_LAYOUT
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

  LISTING_LAYOUT_CONTENTS = <<~EOF_LISTING_LAYOUT
    ---
    layout: archive
    ---

    {{ content }}


    {% assign tree = page.listing %}
    {% include tree.html %}

  EOF_LISTING_LAYOUT

  TREE_INCLUDE_CONTENTS = <<~EOF_TREE_INCLUDE
    <ul>
      {% for item in tree %}
        <li>
          {% if item.url %}
            <a href="{{ item.url | relative_url }}">
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

  FOOTER_INCLUDE_CONTENTS = <<~EOF_FOOTER_INCLUDE
    <div class="page__footer-follow">
      <ul class="social-icons">
        {% if site.data.ui-text[site.locale].follow_label %}
          <li><strong>{{ site.data.ui-text[site.locale].follow_label }}</strong></li>
        {% endif %}

        {% if site.footer.links %}
          {% for link in site.footer.links %}
            {% if link.label and link.url %}
              <li><a href="{{ link.url }}" rel="nofollow noopener noreferrer"><i class="{{ link.icon | default: 'fas fa-link' }}" aria-hidden="true"></i> {{ link.label }}</a></li>
            {% endif %}
          {% endfor %}
        {% endif %}
      </ul>
    </div>


    <div class="page__footer-copyright">Project by {{ site.owner }}.  {{ site.data.ui-text[site.locale].powered_by | default: "Powered by" }} <a href="https://fromthepage.com/">FromThePage</a>, <a href="https://jekyllrb.com" rel="nofollow">Jekyll</a> &amp; <a href="https://mademistakes.com/work/minimal-mistakes-jekyll-theme/" rel="nofollow">Minimal Mistakes</a>.</div>

  EOF_FOOTER_INCLUDE

  def category_to_tree(category)
    element = {}
    element['title'] = category.title
    element['has_children'] = true if category.children.any? || category.articles.any?
    children = category.children.map do |child|
      category_to_tree(child)
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

  def write_gemfile(dirname, out, _collection)
    path = File.join dirname, 'Gemfile'
    out.put_next_entry(path)
    out.write(GEMFILE_CONTENTS)
  end

  def write_work_layout(dirname, out, _collection)
    path = File.join dirname, '_layouts', 'work.html'
    out.put_next_entry(path)
    out.write(WORK_LAYOUT_CONTENTS)
  end

  def write_subject_layout(dirname, out, _collection)
    path = File.join dirname, '_layouts', 'subject.html'
    out.put_next_entry(path)
    out.write(SUBJECT_LAYOUT_CONTENTS.gsub('REPLACEME', '#'))
  end

  def write_listing_layout(dirname, out, _collection)
    path = File.join dirname, '_layouts', 'listing.html'
    out.put_next_entry(path)
    out.write(LISTING_LAYOUT_CONTENTS)
  end

  def write_tree_include(dirname, out, _collection)
    path = File.join dirname, '_includes', 'tree.html'
    out.put_next_entry(path)
    out.write(TREE_INCLUDE_CONTENTS)
  end

  def write_footer_include(dirname, out, _collection)
    path = File.join dirname, '_includes', 'footer.html'
    out.put_next_entry(path)
    out.write(FOOTER_INCLUDE_CONTENTS)
  end

  def write_config_yaml(dirname, out, collection)
    path = File.join dirname, '_config.yml'
    out.put_next_entry(path)
    site_config = {
      'title' => collection.title,
      'email' => collection.owner.email,
      'owner' => collection.owner.display_name,
      'description' => collection.intro_block,
      'plugins' => ['jekyll-feed', 'jekyll-remote-theme', 'jekyll-include-cache'],
      'remote_theme' => 'mmistakes/minimal-mistakes',
      'defaults' => [
        {
          'scope' =>
                    {
                      'path' => ''
                    },
          'values' =>
          {
            'layout' => 'archive'
          }
        }
      ]
    }
    out.write(site_config.to_yaml)
  end

  def write_index_markdown(dirname, out, collection)
    path = File.join dirname, 'index.md'
    out.put_next_entry(path)
    out.write("---\n#{collection.intro_block}")
  end

  def write_navigation_yaml(dirname, out, collection)
    path = File.join dirname, '_data', 'navigation.yml'
    out.put_next_entry(path)

    work_nav = collection.works.sort.map do |work|
      {
        'title' => work.title,
        'url' => "/pages/works/#{work.slug}"
      }
    end

    subject_nav = collection.articles.sort.map do |subject|
      {
        'title' => subject.title,
        'url' => "/pages/subjects/#{subject.id}"
      }
    end

    nav_contents = [
      {
        'title' => 'Works',
        'url' => '/pages/work-list',
        'children' => work_nav
      }
    ]

    unless subject_nav.empty?
      nav_contents <<
        {
          'title' => 'Subjects',
          'url' => '/pages/subject-list',
          'children' => subject_nav
        }
    end

    nav_contents <<
      {
        'title' => 'Contributors',
        'url' => '/pages/about'
      }

    navigation = {
      'main' => nav_contents
    }
    out.write(navigation.to_yaml)
  end

  def write_work_listing(dirname, out, collection)
    path = File.join dirname, 'pages', 'work-list.md'
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
    out.write("#{work_listing_frontmatter.to_yaml}\n---\n")
  end

  def write_subject_listing(dirname, out, collection)
    path = File.join dirname, 'pages', 'subject-list.md'
    out.put_next_entry(path)
    subject_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Subjects'
    }
    tree = collection.categories.map do |category|
      category_to_tree(category)
    end

    uncategorized_articles = collection.articles.where.not(id: collection.articles.joins(:categories).pluck(:id))
    if uncategorized_articles.count > 0
      children = uncategorized_articles.map do |subject|
        {
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
    out.write("#{subject_listing_frontmatter.to_yaml}\n---\n")
  end

  def write_contributor_page(dirname, out, collection)
    path = File.join dirname, 'pages', 'about.md'
    out.put_next_entry(path)
    contributor_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Contributors'
    }
    contributor_ids = collection.deeds.group(:user_id).count.sort { |a, b| b[1] <=> a[1] }.pluck(0)
    listing = []
    contributor_ids.each do |user_id|
      user = User.find(user_id)
      if user.real_name.blank?
        listing << { 'title' => user.display_name }
      else
        listing << { 'title' => user.real_name }
      end
    end
    contributor_listing_frontmatter['listing'] = listing
    out.write("#{contributor_listing_frontmatter.to_yaml}\n---\n")
  end

  def write_work_page(dirname, out, _collection, work)
    path = File.join dirname, 'pages', 'works', "#{work.slug}.md"
    out.put_next_entry path

    metadata = work.merge_metadata

    frontmatter = {
      'title' => work.title,
      'layout' => 'work',
      'metadata' => metadata
    }

    text = ApplicationController.new.render_to_string(
      template: 'export/show',
      formats: [:html],
      work_id: work.id,
      layout: false,
      encoding: 'utf-8',
      assigns: {
        collection: work.collection,
        work:,
        export_user: nil,
        target: :jekyll
      }
    )
    text.gsub!(/^\s+/, '')
    markdown = "#{frontmatter.to_yaml}\n---\n#{text}"
    out.write(markdown)
  end

  def write_subject_page(dirname, out, collection, subject)
    path = File.join dirname, 'pages', 'subjects', "#{subject.id}.md"
    out.put_next_entry path

    text = xml_to_html(subject.xml_text, false, :jekyll, collection) # TODO: convert to HTML
    page_links = subject.page_article_links.map do |link|
      {
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

    markdown = "#{frontmatter.to_yaml}\n---\n#{text}"
    out.write(markdown)
  end

end
