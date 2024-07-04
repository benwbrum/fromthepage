module Api
  class ApiController < ApplicationController

    # real code should exist inside the versioned controllers -- this is just a helper guide
    def help
      api_routes = Rails.application.routes.routes.select { |r| r.path.spec.to_s.starts_with? '/api' }
      render plain: api_routes.map { |r| "#{r.verb}\t#{r.path.spec}" }.join("\n")
    end

  end
end
