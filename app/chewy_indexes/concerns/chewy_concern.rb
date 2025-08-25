module ChewyConcern
  extend ActiveSupport::Concern

  class_methods do
    def formatted_index_name(name)
      [ name, Settings.elasticsearch.suffix ].select(&:present?).join('_')
    end
  end
end
