# frozen_string_literal: true

if Rails.env.development?
  Dir[
    Folio::Engine.root.join('app/models/folio/atom/**/*.rb'),
    Rails.root.join('app/models/**/atom/**/*.rb')
  ].each do |file|
    require_dependency file
  end
end

def get_subclasses(node)
  [node] + node.subclasses.map { |subclass| get_subclasses(subclass) }
end

module Folio
  module Atom
    def self.types
      Base.subclasses.map { |sub| get_subclasses(sub) }.flatten
    end
  end
end
