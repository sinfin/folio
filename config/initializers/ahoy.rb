# frozen_string_literal: true

class Ahoy::Store < Ahoy::Stores::ActiveRecordTokenStore
  Ahoy.geocode = :async
  Ahoy.track_visits_immediately = true
  Ahoy.quiet = false

  # def track_event(name, properties, options)
  # end
  #
  # def current_visit
  # end
end
