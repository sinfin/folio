# frozen_string_literal: true

module Folio::MimeTypeDetection
  extend ActiveSupport::Concern

  private

    def get_mime_type(file)
      stdout, _status = Open3.capture2('file',
                                       '--brief',
                                       '--mime-type',
                                       file.path)
      stdout.chomp
    end
end
