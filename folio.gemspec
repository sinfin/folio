$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "folio/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "folio"
  s.version     = Folio::VERSION
  s.authors     = ["Sinfin"]
  s.email       = ["info@sinfin.cz"]
  s.homepage    = "http://sinfin.digital"
  s.summary     = "Summary of Folio."
  s.description = "Description of Folio."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.2"
  s.add_dependency "pg"
  s.add_dependency "pg_search"
  s.add_dependency "friendly_id", '~> 5.1.0'
  s.add_dependency "ancestry"
  s.add_dependency "annotate"
  s.add_dependency "carrierwave"
  s.add_dependency "mini_magick"
  s.add_dependency "slim"
  s.add_dependency "simple_form"

  s.add_development_dependency "byebug"#, platforms: [:mri, :mingw, :x64_mingw]
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "pry-remote"
  s.add_development_dependency 'capybara', '~> 2.13'
  s.add_development_dependency 'selenium-webdriver'
end
