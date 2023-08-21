# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::AssetsGenerator < Rails::Generators::Base
  include Folio::GeneratorBase

  desc "Creates folio default assets"

  source_root File.expand_path("templates", __dir__)

  TEMPLATES = %w[
    app/assets/javascripts/application.js
    app/assets/javascripts/folio/console/atoms/previews/main_app.coffee
    app/assets/javascripts/folio/console/main_app.coffee
    app/assets/stylesheets/_custom_bootstrap.sass
    app/assets/stylesheets/_fonts.scss
    app/assets/stylesheets/_icons.scss
    app/assets/stylesheets/_print.sass
    app/assets/stylesheets/_variables.sass
    app/assets/stylesheets/application.sass
    app/assets/stylesheets/folio/console/_main_app.sass
    app/assets/stylesheets/modules/_atoms.sass
    app/assets/stylesheets/modules/_rich-text.sass
    app/assets/stylesheets/modules/_turbolinks.sass
    app/assets/stylesheets/modules/_with-icon.sass
    app/assets/stylesheets/modules/bootstrap-overrides/**/*.sass
    bin/icons
    package.json
  ]

  FILES = %w[
    app/cells/folio/.keep
    app/cells/folio/console/.keep
    data/icons.yaml
    data/icons/*.svg
    public/*
    public/fonts/*
  ]

  def rm_rails_new_stuff
    [
      "app/assets/stylesheets/application.css",
    ].each do |path|
      full_path = Rails.root.join(path)
      ::File.delete(full_path) if ::File.exist?(full_path)
    end
  end

  def copy_templates
    TEMPLATES.each { |f| template "#{f}.tt", f }
  end

  def copy_files
    base = ::Folio::Engine.root.join("lib/generators/folio/assets/templates/").to_s

    FILES.each do |key|
      Dir[::Folio::Engine.root.join(key)].each do |full_path|
        path = full_path.to_s.gsub(base, "")
        copy_file path, path
      end
    end
  end

  def chmod_files
    [
      "bin/icons",
    ].each do |file|
      ::File.chmod(0775, Rails.root.join(file))
    end
  end
end
