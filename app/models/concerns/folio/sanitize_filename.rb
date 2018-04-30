# frozen_string_literal: true

module Folio
  module SanitizeFilename
    extend ActiveSupport::Concern

    private

      def sanitize_filename
        # file name can be blank when assigning via file_url
        return if file.name.blank?
        self.file.name = file.name.split('.').map(&:parameterize).join('.')
      end
  end
end
