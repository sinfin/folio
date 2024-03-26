# frozen_string_literal: true

namespace :folio do
  namespace :developer_tools do
    desc "Fill up Folio.main_site to records, where site is missing (and is required)"
    task idp_fill_up_site_to_folio_records: :environment do
      site = begin
        ::Folio.main_site
      rescue Folio::Singleton::MissingError
        nil
      end

      if site.blank?
        puts("!!! No main site found, skipping")
      else
        [
          ::Folio::Page,
          ::Folio::File,
          ::Folio::Lead,
          ::Folio::EmailTemplate,
          ::Folio::NewsletterSubscription,
          ::Folio::Menu
        ].each do |klass|
          if klass.new.attributes.key?("site_id")
            klass.where(site_id: nil).update_all(site_id: site.id)
            klass.where(site_id: 0).update_all(site_id: site.id)
          end
        end
      end
    end
  end
end
