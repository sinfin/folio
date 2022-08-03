# frozen_string_literal: true

namespace :folio do
  namespace :email_templates do
    task idp_seed: :environment do
      Rails.logger.silence do
        Folio::EmailTemplate.load_templates_from_yaml(Folio::Engine.root.join("data/email_templates_data.yml"))
        Folio::EmailTemplate.load_templates_from_yaml(Rails.root.join("data/email_templates_data.yml"))
      end
    end
  end
end
