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

  s.add_development_dependency "sqlite3"
end
