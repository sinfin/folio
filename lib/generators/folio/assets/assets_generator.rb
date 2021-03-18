# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::AssetsGenerator < Rails::Generators::Base
  include Folio::GeneratorBase

  desc "Creates folio default assets"

  source_root File.expand_path("templates", __dir__)

  def rm_rails_new_stuff
    [
      "app/assets/stylesheets/application.css",
    ].each do |path|
      full_path = Rails.root.join(path)
      ::File.delete(full_path) if ::File.exist?(full_path)
    end
  end

  def copy_templates
    [
      "app/assets/javascripts/application.js",
      "app/assets/javascripts/folio/console/main_app.coffee",
      "app/assets/stylesheets/_custom_bootstrap.sass",
      "app/assets/stylesheets/_fonts.scss",
      "app/assets/stylesheets/_icons.scss",
      "app/assets/stylesheets/_print.sass",
      "app/assets/stylesheets/_variables.sass",
      "app/assets/stylesheets/application.sass",
      "app/assets/stylesheets/folio/console/_main_app.sass",
      "app/assets/stylesheets/icons/_data.scss",
      "app/assets/stylesheets/modules/_atoms.sass",
      "app/assets/stylesheets/modules/_bootstrap-overrides.sass",
      "app/assets/stylesheets/modules/_rich-text.sass",
      "app/assets/stylesheets/modules/_turbolinks.sass",
      "app/assets/stylesheets/modules/bootstrap-overrides/_buttons.sass",
      "app/assets/stylesheets/modules/bootstrap-overrides/_forms.sass",
      "app/assets/stylesheets/modules/bootstrap-overrides/_type.sass",
      "app/assets/stylesheets/modules/bootstrap-overrides/mixins/_type.sass",
      "app/cells/folio/console/atoms/previews/main_app.coffee",
    ].each { |f| template "#{f}.tt", f }
  end
end
