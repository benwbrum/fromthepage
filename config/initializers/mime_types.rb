# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register 'text/vnd.graphviz', :dot
ActionView::Template.register_template_handler :erb, ActionView::Template::Handlers::ERB.new
