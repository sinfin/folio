# frozen_string_literal: true

class Folio::TracoGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def add_traco_gem
    gem 'traco'
  end

  def add_migrations
    [
      'config/initializers/folio_using_traco.rb',
      'db/migrate/20190207101928_add_page_translations.rb',
      'db/migrate/20200310101928_add_content_template_translations.rb',
    ].each { |f| template "#{f}.erb", f }
  end
end
