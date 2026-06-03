# frozen_string_literal: true

module Folio::Video::Providers
  Error = Class.new(StandardError)
  UnknownProviderError = Class.new(Error)
  UnavailableProviderError = Class.new(Error)
end
