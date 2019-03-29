# frozen_string_literal: true

module Folio::HasVersions
  extend ActiveSupport::Concern

  module ClassMethods
    def has_folio_versions(opts = {})
      opts[:versions] = { class_name: 'Folio::Version' }
      has_paper_trail opts
    end
  end
end
