# frozen_string_literal: true

module Dummy::Menu::Base
  extend ActiveSupport::Concern

  class_methods do
    def rails_paths
      Dummy.rails_paths
    end

    def styles
      %w[cookie_consent]
    end
  end

  def available_targets
    Folio::Page.by_site(site).to_a.select { |p| p.class.public? }
  end
end
