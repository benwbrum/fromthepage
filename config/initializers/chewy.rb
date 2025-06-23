# frozen_string_literal: true

cloud_id = Settings.elasticsearch.cloud_id

Chewy.settings = if cloud_id.present?
                   {
                     cloud_id: cloud_id,
                     api_key: Settings.elasticsearch.api_key,
                     prefix: Settings.elasticsearch.prefix
                   }
                 else
                   {
                     host: Settings.elasticsearch.host,
                     prefix: Settings.elasticsearch.prefix
                   }
                 end

Chewy.root_strategy = :atomic
