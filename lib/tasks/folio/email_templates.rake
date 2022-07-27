# frozen_string_literal: true

namespace :folio do
  namespace :email_templates do
    task idp_seed: :environment do
      Rails.logger.silence do
        records = []

        [
          Folio::Engine.root.join("data/email_templates_data.yml"),
          Rails.root.join("data/email_templates_data.yml"),
        ].each do |path|
          next unless File.exist?(path)
          yaml_data = YAML.load_file(path)
          next unless yaml_data
          records += yaml_data
        end

        Folio::Site.find_each do |site|
          records.each do |raw|
            msg_action = "Adding"

            next if raw["site_class"] && raw["site_class"] != site.class.to_s

            find_by = { mailer: raw["mailer"], action: raw["action"] }

            unless Rails.application.config.folio_site_is_a_singleton
              find_by[:site] = site
            end

            if em = Folio::EmailTemplate.find_by(find_by)
              if raw["destroy"]
                msg_action = "Destroying"
                em.destroy!
              elsif ENV["FORCE"]
                msg_action = "Overwriting (FORCE=1)"
                em.destroy!
              else
                unless Rails.env.test?
                  puts "Skipping existing email template for #{raw["mailer"]}##{raw["action"]} for site #{site.to_label}"
                end
                next
              end
            end

            unless Rails.env.test?
              puts "#{msg_action} email template for #{raw["mailer"]}##{raw["action"]} for site #{site.to_label}"
            end

            next if raw["destroy"]

            data = raw.slice(*Folio::EmailTemplate.column_names)

            default_locale = Rails.application.config.folio_console_locale
            data["title"] = raw["title_#{default_locale}"].presence
            data["title"] ||= data["title_en"]

            unless Rails.application.config.folio_site_is_a_singleton
              data["site"] = site
            end

            Folio::EmailTemplate.create!(data)
          end
        end
      end
    end
  end
end
