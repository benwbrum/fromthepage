# frozen_string_literal: true

Chewy.settings = if Rails.env.development? || Rails.env.test?
                   {
                     host: Settings.elasticsearch.host,
                     prefix: Settings.elasticsearch.prefix
                   }
                 else
                   {
                     cloud_id: Settings.elasticsearch.cloud_id,
                     api_key: Settings.elasticsearch.api_key,
                     prefix: Settings.elasticsearch.prefix
                   }
                 end

Chewy.root_strategy = :atomic
