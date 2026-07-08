# frozen_string_literal: true

class Folio::Ai::CurrentFormSnapshot
  class << self
    def call(snapshot:, record_class:, limit: nil)
      new(snapshot:,
          record_class:,
          limit:).call
    end
  end

  def initialize(snapshot:,
                 record_class:,
                 limit: nil)
    @snapshot = snapshot
    @record_class = record_class
    @limit = limit
  end

  def call
    entries.each_with_object({}) do |(key, value), sanitized|
      key = key.to_s
      path = key_path(key)

      next if path.blank?
      next if destroyed_path?(path)
      next if destroy_field_path?(path)
      next unless allowed_path?(path)

      sanitized_value = sanitize_value(value, path:)
      sanitized[key] = sanitized_value unless sanitized_value.nil?
    end
  end

  private
    attr_reader :snapshot,
                :record_class,
                :limit

    def normalized_snapshot
      return {} if snapshot.blank?

      return snapshot.to_unsafe_h if snapshot.respond_to?(:to_unsafe_h)
      return snapshot if snapshot.is_a?(Hash)

      {}
    end

    def entries
      @entries ||= begin
        ary = normalized_snapshot.to_a
        limit ? ary.first(limit) : ary
      end
    end

    def allowed_path?(path)
      field_path?(path) ||
        tiptap_path?(path) ||
        atom_path?(path) ||
        file_placement_text_path?(path)
    end

    def field_path?(path)
      path.one? && field_roots.include?(path.first)
    end

    def tiptap_path?(path)
      path.one? && tiptap_roots.include?(path.first)
    end

    def atom_path?(path)
      atom_attribute_roots.include?(path.first) &&
        path.length >= 3
    end

    def file_placement_text_path?(path)
      file_placement_attribute_roots.include?(path.first) &&
        file_placement_text_keys.include?(path.last)
    end

    def destroyed_path?(path)
      destroyed_prefixes.any? do |prefix|
        path.take(prefix.length) == prefix
      end
    end

    def destroyed_prefixes
      @destroyed_prefixes ||= entries.filter_map do |(key, value)|
        path = key_path(key)

        next unless destroy_field_path?(path)
        next unless destroy_value?(value)

        path[0...-1]
      end
    end

    def destroy_field_path?(path)
      path.last == "_destroy"
    end

    def destroy_value?(value)
      if value.is_a?(Array)
        value.any? { |item| destroy_scalar_value?(item) }
      else
        destroy_scalar_value?(value)
      end
    end

    def destroy_scalar_value?(value)
      value == true || value.to_s == "1" || value.to_s.casecmp?("true")
    end

    def sanitize_value(value, path:)
      if value.is_a?(Array)
        value.filter_map { |item| sanitize_scalar_value(item, path:) }
      else
        sanitize_scalar_value(value, path:)
      end
    end

    def sanitize_scalar_value(value, path:)
      case value
      when String
        tiptap_path?(path) ? Folio::Tiptap::PlainText.from_value(value) : value
      when Numeric, TrueClass, FalseClass
        value.to_s
      end
    end

    def key_path(key)
      parts = key.to_s.scan(/[^\[\]]+/)
      return [] if parts.blank?
      return parts.drop(1) if form_object_roots.include?(parts.first)

      parts
    end

    def form_object_roots
      return [] unless record_class&.respond_to?(:model_name)

      [
        record_class.model_name.param_key,
        record_class.model_name.singular,
        record_class.model_name.singular_route_key,
        record_class.model_name.route_key,
        record_class.name.underscore.tr("/", "_"),
      ].compact.map(&:to_s).uniq
    end

    def tiptap_roots
      return [] unless record_class&.respond_to?(:folio_tiptap_fields)

      Array(record_class.folio_tiptap_fields).map(&:to_s)
    end

    def atom_attribute_roots
      atom_roots.map { |key| "#{key}_attributes" }
    end

    def atom_roots
      return [] unless record_class&.respond_to?(:atom_keys)

      Array(record_class.atom_keys).map(&:to_s)
    end

    def file_placement_attribute_roots
      file_placement_roots.map { |key| "#{key}_attributes" }
    end

    def file_placement_roots
      return [] unless record_class&.respond_to?(:folio_attachment_keys)

      record_class.folio_attachment_keys.values.flatten.map(&:to_s)
    end

    def field_roots
      Folio::Ai.config.current_form_snapshot_field_roots
    end

    def file_placement_text_keys
      Folio::Ai.config.current_form_snapshot_file_placement_text_keys
    end
end
