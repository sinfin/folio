# frozen_string_literal: true

module Folio
  module Mcp
    module Serializers
      class RecordList
        def initialize(records, config)
          @records = records
          @config = config
        end

        def as_json
          @records.map do |record|
            Record.new(record, @config).as_json
          end
        end
      end
    end
  end
end
