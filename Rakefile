# frozen_string_literal: true

begin
  require "bundler/setup"
rescue LoadError => e
  abort <<~MESSAGE
    Bundler setup failed:
    #{e.class}: #{e.message}

    Run rake tasks through Bundler, for example:
      bundle exec rake app:packwerk:validate

    If dependencies are missing, run:
      bundle install
  MESSAGE
end

require "rdoc/task"

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "Folio"
  rdoc.options << "--line-numbers"
  rdoc.rdoc_files.include("README.md")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

APP_RAKEFILE = File.expand_path("../test/dummy/Rakefile", __FILE__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false
end

task default: :test
