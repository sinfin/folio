# frozen_string_literal: true

class Folio::EmailTemplatesGenerator < Rails::Generators::Base
  desc "Seeds basic email templates"
  source_root File.expand_path("templates", __dir__)

  def seed_records
    records = []

    [
      File.expand_path("templates/email_templates_data.yml", __dir__),
      Rails.root.join("data/email_templates_data.yml"),
    ].each do |path|
      next unless File.exist?(path)
      yaml_data = YAML.load_file(path)
      next unless yaml_data
      records += yaml_data
    end

    records.each do |raw|
      msg_action = "Adding"

      if em = Folio::EmailTemplate.find_by(mailer: raw["mailer"], action: raw["action"])
        if raw["destroy"]
          msg_action = "Destroying"
          em.destroy!
        elsif ENV["FORCE"]
          msg_action = "Overwriting (FORCE=1)"
          em.destroy!
        else
          unless Rails.env.test?
            puts "Skipping existing email template for #{raw["mailer"]}##{raw["action"]}"
          end
          next
        end
      end

      unless Rails.env.test?
        puts "#{msg_action} email template for #{raw["mailer"]}##{raw["action"]}"
      end

      next if raw["destroy"]

      data = raw.slice(*Folio::EmailTemplate.column_names)

      default_locale = Rails.application.config.folio_console_locale
      data["title"] = raw["title_#{default_locale}"].presence
      data["title"] ||= data["title_en"]

      Folio::EmailTemplate.create!(data)
    end
  end
end
