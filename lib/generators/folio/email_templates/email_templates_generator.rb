# frozen_string_literal: true

class Folio::EmailTemplatesGenerator < Rails::Generators::Base
  desc "Seeds basic email templates"
  source_root File.expand_path("templates", __dir__)

  def seed_records
    [
      Rails.root.join("data/email_templates_data.yml"),
      File.expand_path("templates/email_templates_data.yml", __dir__),
    ].each do |path|
      next unless File.exist?(path)
      yaml_data = YAML.load_file(path)
      next unless yaml_data

      yaml_data.each do |raw|
        if Folio::EmailTemplate.exists?(mailer: raw["mailer"], action: raw["action"])
          puts "Skipping existing email template for #{raw["mailer"]}##{raw["action"]}"
          next
        end

        puts "Adding email template for #{raw["mailer"]}##{raw["action"]}"

        data = raw.slice(*Folio::EmailTemplate.column_names)

        default_locale = Rails.application.config.folio_console_locale
        data["title"] = raw["title_#{default_locale}"].presence
        data["title"] ||= data["title_en"]

        Folio::EmailTemplate.create!(data)
      end
    end
  end
end
