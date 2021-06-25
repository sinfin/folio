# frozen_string_literal: true

module Dummy::Menu::Base
  extend ActiveSupport::Concern

  class_methods do
    def rails_paths
      Dummy.rails_paths
    end
  end

  def available_targets
    Folio::Page.all.to_a.select { |p| p.class.public? }
  end
end
