class Ahoy::Store < Ahoy::Stores::ActiveRecordTokenStore
  Ahoy.geocode = :async
  Ahoy.track_visits_immediately = true
  Ahoy.quiet = false

  def track_visit(options)
    super do |visit|
      # FIXME
      @site = Folio::Site.first
      visit.site = @site
    end
  end
  # def track_event(name, properties, options)
  # end
  #
  # def current_visit
  # end
end
