# frozen_string_literal: true

module Folio
  module EnvFlags
    FLAGS = {
      "FOLIO_DEBUG_TIPTAP_NODES" => "Raises tiptap node errors in development (causes tests to fail)",
      "FOLIO_DEBUG_ATOMS" => "Raises atom errors in development",
      "FOLIO_API_DONT_RESCUE_ERRORS" => "Disables error rescue in API controllers",
      "FOLIO_TIPTAP_DEV" => "Uses development tiptap iframe with wildcard origin",
      "FOLIO_SKIP_METADATA_EXTRACTION" => "Skips metadata extraction in tests",
      "FOLIO_MAINTENANCE" => "Enables maintenance mode middleware",
      "REACT_DEV" => "React development mode (loads React from dev server)",
      "FORCE_MINI_PROFILER" => "Force enable mini profiler",
      "DEV_TESTING_PRODUCTION" => "Testing production-like behavior in development",
      "SKIP_FOLIO_FILE_AFTER_SAVE_JOB" => "Skips file after-save job processing"
    }.freeze

    def self.present_flags
      FLAGS.keys.select { |key| ENV[key].present? }
    end

    def self.warn_if_present
      flags = present_flags

      return unless flags.present?

      puts "\nFolio ENV flags detected:"
      flags.each do |flag|
        puts "  #{flag}: #{FLAGS[flag]}"
      end
      puts ""
    end
  end
end
