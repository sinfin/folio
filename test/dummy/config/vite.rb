# frozen_string_literal: true

ViteRuby.env["APP_COMPONENTS_PATH"] = File.expand_path("../app/components", __dir__)

folio_spec = Gem.loaded_specs["folio"]

ViteRuby.env["FOLIO_ROOT_PATH"] = folio_spec.full_gem_path
ViteRuby.env["FOLIO_IMAGES_PATH"] = "#{folio_spec.full_gem_path}/app/frontend/images"
ViteRuby.env["FOLIO_STYLESHEETS_PATH"] = "#{folio_spec.full_gem_path}/app/frontend/stylesheets"
ViteRuby.env["FOLIO_JAVASCRIPTS_PATH"] = "#{folio_spec.full_gem_path}/app/frontend/javascripts"
ViteRuby.env["FOLIO_COMPONENTS_PATH"] = "#{folio_spec.full_gem_path}/app/components/folio"
ViteRuby.env["FOLIO_CELLS_PATH"] = "#{folio_spec.full_gem_path}/app/cells/folio"
ViteRuby.env["FOLIO_VENDOR_PATH"] = "#{folio_spec.full_gem_path}/vendor/assets"
