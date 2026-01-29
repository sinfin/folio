# frozen_string_literal: true

module Folio
  module Mcp
    module Serializers
      class Record
        def initialize(record, config)
          @record = record
          @config = config
        end

        def as_json
          hash = {
            id: @record.id,
            type: @record.try(:type) || @record.class.name,
            created_at: @record.created_at&.iso8601,
            updated_at: @record.updated_at&.iso8601
          }

          # Add configured fields
          @config[:fields]&.each do |field|
            hash[field] = @record.try(field)
          end

          # Add tiptap fields
          @config[:tiptap_fields]&.each do |field|
            hash[field] = @record.try(field)
          end

          # Add cover if configured
          if @config[:cover_field]
            cover = @record.try(@config[:cover_field])
            if cover
              hash[:cover] = {
                id: cover.id,
                url: cover.file&.url,
                thumbnail_url: cover.try(:thumb, "800x600")&.url,
                alt: cover.alt
              }
            end
          end

          hash
        end
      end
    end
  end
end
