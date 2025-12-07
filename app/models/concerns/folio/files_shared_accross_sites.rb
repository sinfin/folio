# frozen_string_literal: true

module Folio::FilesSharedAccrossSites
  extend ActiveSupport::Concern

  included do
    before_validation :set_correct_site

    scope :by_site, -> (site) { where(site: correct_site(site)) }

    def self.correct_site(requested_site)
      if Rails.application.config.folio_shared_files_between_sites
        Folio::Current.main_site
      else
        requested_site
      end
    end
  end

  private
    def set_correct_site
      self.site = self.class.correct_site(self.site)
    end
end
