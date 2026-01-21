# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::AssetsGenerator < Rails::Generators::Base
  include Folio::GeneratorBase

  desc "Creates folio default assets"

  source_root File.expand_path("templates", __dir__)

  TEMPLATES = %w[
    app/assets/javascripts/application.js
    app/assets/javascripts/folio/console/atoms/previews/main_app.js
    app/assets/javascripts/folio/console/main_app.js
    app/assets/stylesheets/_custom_bootstrap.sass
    app/assets/stylesheets/_fonts.scss
    app/assets/stylesheets/_icons.scss
    app/assets/stylesheets/_print.sass
    app/assets/stylesheets/_variables.sass
    app/assets/stylesheets/_variables-colors.sass
    app/assets/stylesheets/_root.sass
    app/assets/stylesheets/application.sass
    app/assets/stylesheets/folio/console/_main_app.sass
    app/assets/stylesheets/modules/_atoms.sass
    app/assets/stylesheets/modules/_rich-text.sass
    app/assets/stylesheets/modules/_turbolinks.sass
    app/assets/stylesheets/modules/_with-icon.sass
    bin/icons
    package.json
  ]

  FILES = %w[
    app/cells/folio/.keep
    app/cells/folio/console/.keep
    app/components/folio/.keep
    app/components/folio/console/.keep
    data/icons.yaml
    data/icons/*.svg
    public/*
    public/fonts/*
  ]

  KEEP_FILES = %w[
    app/cells/application_namespace_path/.keep
    app/cells/folio/.keep
    app/cells/folio/console/.keep
    app/components/folio/.keep
    app/components/folio/console/.keep
    app/components/application_namespace_path/.keep
  ]

  def rm_rails_new_stuff
    [
      "app/assets/stylesheets/application.css",
    ].each do |path|
      full_path = folio_generators_root.join(path)
      ::File.delete(full_path) if ::File.exist?(full_path)
    end
  end

  def copy_templates
    TEMPLATES.each do |f|
      # Only apply pack prefix to app/ paths, not config/ or root paths
      target = f.start_with?("app/") ? "#{pack_path_prefix}#{f}" : f
      template "#{f}.tt", target
    end
  end

  def copy_bootstrap_overrides
    Dir.glob(Folio::Engine.root.join("lib/generators/folio/assets/templates/app/assets/stylesheets/modules/bootstrap-overrides/**/*.sass.tt")).each do |path|
      clear_path = path.split("lib/generators/folio/assets/templates/", 2).last
      template clear_path, clear_path.delete_suffix(".tt")
    end
  end

  def copy_files
    base = ::Folio::Engine.root.join("lib/generators/folio/assets/templates/").to_s

    FILES.each do |key|
      Dir["#{base}#{key}"].each do |full_path|
        next if File.directory?(full_path)

        path = full_path.to_s.gsub(base, "")
        # Only apply pack prefix to app/ paths, not data/ or public/ paths
        target = path.start_with?("app/") ? "#{pack_path_prefix}#{path}" : path
        copy_file path, target
      end
    end
  end

  def add_keep_files
    KEEP_FILES.each do |key|
      target_key = key.gsub("application_namespace_path", application_namespace_path)
      # Only apply pack prefix to app/ paths
      final_key = target_key.start_with?("app/") ? "#{pack_path_prefix}#{target_key}" : target_key
      full_path = Rails.root.join(final_key).to_s
      FileUtils.mkdir_p(File.dirname(full_path))
      FileUtils.touch(full_path)
    end
  end

  def chmod_files
    [
      "bin/icons",
    ].each do |file|
      [
        folio_generators_root.join(file),
        file,
      ].each do |path|
        if File.exist?(path)
          ::File.chmod(0o775, path)
        end
      end
    end
  end
end
