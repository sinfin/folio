# frozen_string_literal: true

if Rails.env.development?
  Dir[
    Folio::Engine.root.join('app/models/folio/atom/**/*.rb'),
    Rails.root.join('app/models/**/atom/**/*.rb')
  ].each do |file|
    require_dependency file
  end
end

module Folio
  module Atom
    def self.types
      Base.recursive_subclasses
    end
  end
end
