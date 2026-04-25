# frozen_string_literal: true

namespace :packwerk do
  def packwerk_dummy_app_root
    Folio::Engine.root.join("test", "dummy")
  end

  def run_packwerk_command(*args)
    dummy_app = packwerk_dummy_app_root

    unless dummy_app.exist?
      abort "Error: test/dummy app not found. Packwerk requires a Rails application context."
    end

    Dir.chdir(dummy_app) do
      system("bundle", "exec", "packwerk", *args) || exit(1)
    end
  end

  desc "Run packwerk check (validates package dependencies)"
  task :check do
    run_packwerk_command("check")
  end

  desc "Run packwerk validate (validates configuration)"
  task :validate do
    run_packwerk_command("validate")
  end

  desc "Run packwerk update-todo (updates violation list)"
  task :update_todo do
    run_packwerk_command("update-todo")
  end
end
