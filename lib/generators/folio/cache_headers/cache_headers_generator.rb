# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::CacheHeadersGenerator < Rails::Generators::Base
  include Folio::GeneratorBase

  desc "Creates cache headers initializer for your application"

  source_root File.expand_path("templates", __dir__)

  def create_cache_headers_initializer
    # Config files don't go into packs
    template "cache_headers_initializer.rb.tt", "config/initializers/cache_headers.rb"
  end
end
