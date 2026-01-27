# frozen_string_literal: true

namespace :packwerk do
  desc "Run packwerk check (validates package dependencies)"
  task :check do
    dummy_app = Folio::Engine.root.join("test", "dummy")

    unless dummy_app.exist?
      abort "Error: test/dummy app not found. Packwerk requires a Rails application context."
    end

    Dir.chdir(dummy_app) do
      system("bundle", "exec", "packwerk", "check") || exit(1)
    end
  end

  desc "Run packwerk validate (validates configuration)"
  task :validate do
    dummy_app = Folio::Engine.root.join("test", "dummy")

    unless dummy_app.exist?
      abort "Error: test/dummy app not found. Packwerk requires a Rails application context."
    end

    Dir.chdir(dummy_app) do
      system("bundle", "exec", "packwerk", "validate") || exit(1)
    end
  end

  desc "Run packwerk update-todo (updates violation list)"
  task :update_todo do
    dummy_app = Folio::Engine.root.join("test", "dummy")

    unless dummy_app.exist?
      abort "Error: test/dummy app not found. Packwerk requires a Rails application context."
    end

    Dir.chdir(dummy_app) do
      system("bundle", "exec", "packwerk", "update-todo") || exit(1)
    end
  end
end
