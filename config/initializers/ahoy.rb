class Ahoy::Store < Ahoy::DatabaseStore
  def visit_model
    Visit
  end
end

Ahoy.user_agent_parser = :legacy
