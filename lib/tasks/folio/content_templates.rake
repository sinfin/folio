# frozen_string_literal: true

namespace :folio do
  namespace :content_templates do
    desc "Migrate existing content templates without a site to be scoped per site"
    task idp_migrate_to_per_site: :environment do
      Rails.logger.silence do
        site_ids = Folio::Site.pluck(:id)

        site_ids.each do |site_id|
          Folio::ContentTemplate.where(site_id: nil).pluck(:type).uniq.each do |type|
            existing_templates = Folio::ContentTemplate.where(site_id:, type:)

            if existing_templates.empty?
              Folio::ContentTemplate.where(site_id: nil, type:).find_each do |template_to_duplicate|
                content_template = template_to_duplicate.dup

                content_template.site_id = site_id
                content_template.created_at = nil
                content_template.updated_at = nil

                content_template.save!
              end
            end
          end
        end

        Rails.logger.info "Content templates have been successfully duplicated for each site. Run `rake folio:content_templates:remove_siteless` to remove the siteless content templates."
      end
    end

    desc "Remove siteless content templates"
    task remove_siteless: :environment do
      Folio::ContentTemplate.where(site_id: nil).destroy_all

      Rails.logger.info "Siteless content templates have been removed."
    end
  end
end
