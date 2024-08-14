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

    desc "split users to separate site-link-binded records when switching from crossdomain to user-per-site"
    task idp_split_users_to_sites: :environment do
      batches = Folio::User.pluck(:id).to_a.in_groups_of(1000)
      batches.each do |batch|
        Folio::User.find(batch).each do |user|
          puts("Spliting user #{user.id}")
          user.make_clones_to_all_linked_sites!
          # user.destroy if !user.superadmin? && user.auth_site_id == Folio.main_site.id
        end
      end
    end
  end
end
