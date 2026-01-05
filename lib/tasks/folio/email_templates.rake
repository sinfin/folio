# frozen_string_literal: true

namespace :folio do
  namespace :email_templates do
    task idp_seed: :environment do
      Folio::EmailTemplate.idp_seed
    end
  end
end
