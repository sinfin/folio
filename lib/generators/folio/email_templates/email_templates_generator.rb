# frozen_string_literal: true

class Folio::EmailTemplatesGenerator < Rails::Generators::Base
  desc "Seeds basic email templates"
  source_root File.expand_path("templates", __dir__)

  def seed_records
    path = File.expand_path("templates/email_templates_data.yml", __dir__)
    yaml_data = YAML.load_file(path)

    yaml_data.each do |raw|
      data = raw.slice(*Folio::EmailTemplate.column_names)
      et = Folio::EmailTemplate.find_or_initialize_by(mailer: data["mailer"],
                                                      action: data["action"])

      default_locale = Rails.application.config.folio_console_locale
      data["title"] = raw["title_#{default_locale}"].presence
      data["title"] ||= data["title_en"]

      et.update!(data)
    end
  end
end
