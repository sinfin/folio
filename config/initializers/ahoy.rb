# frozen_string_literal: true

class Ahoy::Store < Ahoy::DatabaseStore
  def visit_model
    Visit
  end
end

Ahoy.api = true
Ahoy.geocode = :async
Ahoy.quiet = true
Ahoy.server_side_visits = :when_needed
