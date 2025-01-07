# frozen_string_literal: true

module Folio::Console::Clonable
  extend ActiveSupport::Concern

  DEFAULT_RESET_ATTRIBUTES = [:published_at, :published]

  included do
    def after_clone
    end
  end

  class_methods do
    def is_clonable?
      Rails.application.config.folio_console_clonable_enabled
    end

    def clonable_ignored_associations
      []
    end

    def clonable_referenced_associations
      []
    end

    def clonable_reset_attributes
      []
    end
  end
end
