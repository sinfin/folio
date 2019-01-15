# frozen_string_literal: true

module Folio::MimeTypeDetection
  extend ActiveSupport::Concern

  include Folio::Shell

  private

    def get_mime_type(file)
      shell('file', '--brief', '--mime-type', file.path)
    end
end
