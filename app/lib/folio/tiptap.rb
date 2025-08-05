# frozen_string_literal: true

module Folio
  module Tiptap
    ALLOWED_URL_JSON_KEYS = %w[href label title rel target record_id record_type]

    def self.config
      @config ||= Folio::Tiptap::Config.new
    end

    def self.configure
      yield(config)
    end
  end
end
