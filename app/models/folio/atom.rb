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

    def self.translations
      @translations ||= begin
        if Folio::Atom::Base.column_names.include?('title')
          nil
        else
          Folio::Atom::Base.column_names
                           .grep(/\Atitle_/)
                           .map { |t| t.gsub(/\Atitle_/, '') }
        end
      end
    end

    def self.text_fields
      @text_fields ||= begin
        if Folio::Atom::Base.column_names.include?('title')
          [:title, :content, :perex]
        else
          text_fields = []
          Folio::Atom::Base.column_names.each do |column|
            if column =~ /\A(title|content|perex)_/
              text_fields << column.to_sym
            end
          end
          text_fields
        end
      end
    end
  end
end
