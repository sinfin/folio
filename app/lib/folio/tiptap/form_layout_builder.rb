# frozen_string_literal: true

class Folio::Tiptap::FormLayoutBuilder
  def self.call(klass:, structure:, form_layout:)
    new(klass:, structure:, form_layout:).call
  end

  def initialize(klass:, structure:, form_layout:)
    @klass = klass
    @structure = structure
    @form_layout = form_layout
  end

  def call
    case @form_layout
    when nil, :aside_attachments
      @form_layout
    when Hash
      normalize_node(@form_layout).tap do |normalized|
        validate_custom_fields!(normalized)
      end
    else
      fail ArgumentError, "Expected form_layout to be nil, :aside_attachments, or a Hash"
    end
  end

  private
    def normalize_node(node)
      case node
      when Hash
        normalize_hash(node)
      when Symbol, String
        normalize_field(node)
      else
        fail ArgumentError, "Expected form_layout item to be a field, rows hash, or columns hash"
      end
    end

    def normalize_hash(hash)
      has_rows = hash.key?(:rows) || hash.key?("rows")
      has_columns = hash.key?(:columns) || hash.key?("columns")

      if has_rows == has_columns
        fail ArgumentError, "Expected form_layout hash to include either :rows or :columns"
      end

      if has_rows
        rows = hash.key?(:rows) ? hash[:rows] : hash["rows"]

        { rows: normalize_collection(rows, :rows) }
      else
        columns = hash.key?(:columns) ? hash[:columns] : hash["columns"]

        { columns: normalize_collection(columns, :columns) }
      end
    end

    def normalize_collection(collection, key)
      unless collection.is_a?(Array) && collection.present?
        fail ArgumentError, "Expected form_layout #{key} to be a non-empty Array"
      end

      collection.map { |node| normalize_node(node) }
    end

    def normalize_field(field)
      normalized = field.to_sym

      unless @structure.key?(normalized)
        fail ArgumentError, "Unknown field `#{field}` in form_layout for #{@klass.name || @klass}"
      end

      normalized
    end

    def validate_custom_fields!(form_layout)
      keys = field_keys(form_layout)
      duplicates = keys.tally.select { |_key, count| count > 1 }.keys
      missing = @structure.keys - keys

      if duplicates.present?
        fail ArgumentError, "Duplicate fields in form_layout: #{duplicates.join(', ')}"
      end

      if missing.present?
        fail ArgumentError, "Missing fields in form_layout: #{missing.join(', ')}"
      end
    end

    def field_keys(node)
      case node
      when Hash
        Array(node[:rows] || node[:columns]).flat_map { |item| field_keys(item) }
      else
        [node]
      end
    end
end
