# frozen_string_literal: true

class Folio::Console::Files::Show::MetadataComponent < Folio::Console::ApplicationComponent
  DATA = YAML.load_file(Folio::Engine.root.join("app/components/folio/console/files/show/metadata_component_data.yml")).freeze

  def initialize(file:)
    @file = file
  end

  def render?
    @file.respond_to?(:mapped_metadata)
  end

  private
    def table_groups
      @table_groups ||= begin
        ary = []

        DATA.each do |group|
          rows = []

          group["fields"].each do |field|
            raw_value = @file.mapped_metadata[field["key"].to_sym]

            if raw_value.present?
              value = begin
                if field["type"] == "array"
                  raw_value.join(", ")
                elsif field["type"] == "number"
                  number_with_delimiter(raw_value, precision: field["decimals"] || 2)
                else
                  raw_value
                end
              rescue StandardError
                raw_value
              end

              rows << [
                field["label"][I18n.locale.to_s] || field["label"]["en"],
                value,
              ]
            end
          end

          if rows.present?
            ary << [
              group["label"][I18n.locale.to_s] || group["label"]["en"],
              rows,
            ]
          end
        end

        ary
      end
    end
end
