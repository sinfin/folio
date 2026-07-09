# frozen_string_literal: true

require "uri"

# Turns raw console form snapshots into compact provider-safe AI context.
class Folio::Ai::FormSnapshotSanitizer
  IGNORED_KEYS = %w[
    _destroy
    _method
    action
    authenticity_token
    commit
    controller
    created_at
    format
    id
    lock_version
    position
    site_id
    updated_at
    utf8
  ].freeze

  ALLOWED_ATTRIBUTE_TYPES = %i[string text json jsonb].freeze
  DEFAULT_EXCLUDED_COLUMN_KEYS = %w[
    ancestry
    ancestry_slug
    slug
    state
    type
  ].freeze
  SENSITIVE_KEY_PATTERNS = [
    /\Akey\z/i,
    /access_key/i,
    /api_key/i,
    /credential/i,
    /encrypted/i,
    /password/i,
    /private_key/i,
    /secret/i,
    /token/i,
  ].freeze
  TEXT_METADATA_KEYS = %w[alt caption description label title].freeze
  URL_METADATA_KEYS = %w[href src url].freeze
  URL_JSON_KEYS = %w[href label title].freeze

  MAX_TEXT_LENGTH = 6_000
  MAX_ITEM_TEXT_LENGTH = 1_000
  MAX_COLLECTION_ITEMS = 30

  def self.call(record:, snapshot:)
    new(record:, snapshot:).call
  end

  def initialize(record:, snapshot:)
    @record = record
    @snapshot = snapshot
  end

  def call
    expanded_snapshot.each_with_object({}) do |(key, value), hash|
      attribute = attribute_name(key)
      next if ignored_key?(attribute)
      next unless allowed_context_root?(attribute)

      sanitized = sanitize_attribute(attribute, value)
      hash[attribute] = sanitized if context_present?(sanitized)
    end
  end

  private
    attr_reader :record,
                :snapshot

    def expanded_snapshot
      raw = raw_hash(snapshot)
      expanded = raw.keys.any? { |key| key.to_s.include?("[") } ? expand_bracketed_snapshot(raw) : raw

      root_key = record_root_keys.find { |key| expanded[key].is_a?(Hash) }

      if root_key
        expanded[root_key]
      else
        expanded
      end
    end

    def raw_hash(value)
      value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      value.respond_to?(:to_h) ? value.to_h : {}
    end

    def expand_bracketed_snapshot(raw)
      pairs = raw.flat_map do |key, value|
        Array(value).map { |item| [key.to_s, query_value(item)] }
      end

      Rack::Utils.parse_nested_query(URI.encode_www_form(pairs))
    end

    def query_value(value)
      value.is_a?(Hash) || value.is_a?(Array) ? value.to_json : value
    end

    def record_root_keys
      model_name = record&.class&.model_name
      return [] unless model_name

      [
        model_name.param_key,
        model_name.singular,
      ].compact_blank.uniq
    end

    def attribute_name(key)
      key.to_s.scan(/[^\[\]]+/).last.to_s
    end

    def allowed_context_root?(key)
      context_roots.include?(key.to_s)
    end

    def context_roots
      @context_roots ||= begin
        defaults = default_context_roots

        if record.respond_to?(:folio_ai_form_snapshot_context_keys)
          normalize_context_keys(record.folio_ai_form_snapshot_context_keys(default_keys: defaults))
        else
          defaults
        end
      end
    end

    def default_context_roots
      normalize_context_keys(
        registered_field_roots +
          allowed_attribute_roots +
          tiptap_roots +
          atom_attribute_roots +
          file_placement_attribute_roots
      )
    end

    def registered_field_roots
      return [] unless record_class&.respond_to?(:table_name)

      Folio::Ai.registry.record(record_class.table_name)&.dig(:fields)&.keys || []
    end

    def allowed_attribute_roots
      return [] unless record_class

      attribute_types = if record_class.respond_to?(:columns_hash)
        record_class.columns_hash
      elsif record_class.respond_to?(:attribute_types)
        record_class.attribute_types
      end

      return [] unless attribute_types

      attribute_types.filter_map do |key, type|
        next unless allowed_attribute_type?(type)
        next if excluded_default_column_key?(key)

        key
      end
    end

    def allowed_attribute_type?(type)
      type.respond_to?(:type) &&
        ALLOWED_ATTRIBUTE_TYPES.include?(type.type.to_sym)
    end

    def tiptap_roots
      return [] unless record_class&.respond_to?(:folio_tiptap_fields)

      record_class.folio_tiptap_fields
    end

    def atom_attribute_roots
      return [] unless record_class&.respond_to?(:atom_keys)

      record_class.atom_keys.map { |key| "#{key}_attributes" }
    end

    def file_placement_attribute_roots
      return [] unless record_class&.respond_to?(:folio_attachment_keys)

      record_class.folio_attachment_keys.values.flatten.map { |key| "#{key}_attributes" }
    end

    def normalize_context_keys(keys)
      Array(keys).filter_map { |key| key.to_s.strip.presence }.uniq
    end

    def excluded_default_column_key?(key)
      key = key.to_s

      DEFAULT_EXCLUDED_COLUMN_KEYS.include?(key) ||
        key.end_with?("_slug") ||
        ignored_key?(key)
    end

    def sanitize_attribute(attribute, value)
      if tiptap_field?(attribute)
        sanitize_tiptap_value(value)
      else
        sanitize_context_value(value)
      end
    end

    def tiptap_field?(attribute)
      tiptap_roots.include?(attribute.to_s)
    end

    def sanitize_tiptap_value(value)
      raw_value = parsed_json_string(value.to_s) if value.is_a?(String)
      result = Folio::Tiptap::Content.new(record:).convert_and_sanitize_value(value)
      return unless result[:ok] && result[:value].present?

      tiptap_context(result[:value], raw_value:)
    end

    def tiptap_context(value, raw_value: nil)
      context = {}
      text = truncate_text(Folio::Tiptap.extract_text(value))
      metadata = tiptap_metadata(value, raw_value:)

      context["text"] = text if text.present?
      metadata.each { |key, items| context[key] = items if items.present? }
      context
    end

    def tiptap_metadata(value, raw_value: nil)
      metadata = metadata_hash

      walk_tiptap_node(tiptap_content_node(value), metadata)
      walk_tiptap_node(tiptap_content_node(raw_value), metadata) if raw_value.present?

      metadata.transform_values { |items| deduplicate_items(items) }.compact_blank
    end

    def tiptap_content_node(value)
      content_key = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]
      value.is_a?(Hash) && value.key?(content_key) ? value[content_key] : value
    end

    def walk_tiptap_node(node, metadata)
      case node
      when Array
        node.first(MAX_COLLECTION_ITEMS).each { |child| walk_tiptap_node(child, metadata) }
      when Hash
        extract_link_marks(node, metadata)
        extract_tiptap_custom_node(node, metadata) if node["type"] == "folioTiptapNode"
        walk_tiptap_node(node["content"], metadata)
      end
    end

    def extract_link_marks(node, metadata)
      Array(node["marks"]).each do |mark|
        next unless mark.is_a?(Hash) && mark["type"] == "link"

        link = sanitize_url_hash(mark["attrs"].to_h.merge("label" => node["text"]))
        metadata["links"] << link if context_present?(link)
      end
    end

    def extract_tiptap_custom_node(node, metadata)
      attrs = node["attrs"]
      return unless attrs.is_a?(Hash)

      extract_tiptap_node_attrs(attrs, metadata)
    end

    def extract_tiptap_node_attrs(attrs, metadata)
      klass = attrs["type"].to_s.safe_constantize
      return unless klass && klass < Folio::Tiptap::Node

      data = attrs["data"]
      return unless data.is_a?(Hash)

      klass.structure.each do |key, config|
        extract_tiptap_node_value(key.to_s, data, config, metadata)
      end
    rescue ArgumentError
      nil
    end

    def extract_tiptap_node_value(key, data, config, metadata)
      value = data[key]

      case config[:type]
      when :url_json
        add_metadata_item(metadata, "links", sanitize_url_hash(value))
      when :embed
        add_metadata_item(metadata, "embeds", sanitize_embed_hash(value))
      when :folio_attachment
        extract_attachment_metadata(key, data, config, metadata)
      when :rich_text
        walk_tiptap_node(parsed_hash(value), metadata)
      when :nested_nodes
        extract_nested_node_metadata(value, metadata)
      end
    end

    def extract_attachment_metadata(key, data, config, metadata)
      placement_key = if config[:has_many]
        "#{key.singularize}_placements_attributes"
      else
        "#{key}_placement_attributes"
      end

      Array.wrap(data[placement_key]).each do |attrs|
        add_metadata_item(metadata, "attachments", sanitize_attachment_hash(attrs))
        add_metadata_item(metadata, "embeds", sanitize_embed_hash(attrs["folio_embed_data"])) if attrs.is_a?(Hash)
      end
    end

    def extract_nested_node_metadata(value, metadata)
      Array.wrap(value).first(MAX_COLLECTION_ITEMS).each do |attrs|
        extract_tiptap_node_attrs(attrs, metadata) if attrs.is_a?(Hash)
      end
    end

    def sanitize_context_value(value)
      case value
      when Hash
        sanitize_context_hash(value)
      when Array
        value.first(MAX_COLLECTION_ITEMS).filter_map { |item| sanitize_context_value(item) }
      else
        sanitize_scalar_value(value)
      end
    end

    def sanitize_context_hash(value)
      value = value.stringify_keys
      return tiptap_context(value) if tiptap_document_hash?(value)

      if embed_hash?(value)
        sanitize_embed_hash(value)
      elsif url_hash?(value)
        sanitize_url_hash(value)
      else
        value.each_with_object({}) do |(key, item), hash|
          next if ignored_key?(key)
          next if item.is_a?(Hash) && destroyed_hash?(item)

          sanitized = sanitize_context_value(item)
          hash[key.to_s] = sanitized if context_present?(sanitized)
        end
      end
    end

    def sanitize_scalar_value(value)
      return value if value.is_a?(Numeric)

      string = value.to_s.strip
      return if string.blank?

      parsed = parsed_json_string(string)
      return sanitize_context_value(parsed) if parsed

      truncate_text(text_with_link_destinations(string))
    end

    def parsed_json_string(string)
      return unless string.start_with?("{", "[")

      JSON.parse(string)
    rescue JSON::ParserError
      nil
    end

    def parsed_hash(value)
      if value.is_a?(Hash)
        value.stringify_keys
      elsif value.is_a?(String)
        parsed_json_string(value)
      end
    end

    def tiptap_document_hash?(value)
      content_key = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]
      value["type"] == "doc" || value.key?(content_key)
    end

    def embed_hash?(value)
      value.key?("active") && (value.key?("type") || value.key?("url") || value.key?("html"))
    end

    def url_hash?(value)
      (value.keys.map(&:to_s) & URL_METADATA_KEYS).present?
    end

    def sanitize_url_hash(value)
      hash = parsed_hash(value)
      return unless hash.is_a?(Hash)

      href = safe_href(hash["href"] || hash["url"] || hash["src"])
      result = {}
      URL_JSON_KEYS.each do |key|
        next if key == "href"

        text = truncate_text(text_with_link_destinations(hash[key].to_s), limit: MAX_ITEM_TEXT_LENGTH)
        result[key] = text if text.present?
      end
      result["href"] = truncate_text(href, limit: MAX_ITEM_TEXT_LENGTH) if href.present?
      result
    end

    def sanitize_embed_hash(value)
      normalized = Folio::Embed.sanitize_value(value)
      return unless normalized

      result = {}
      result["type"] = normalized["type"] if normalized["type"].present?
      result["url"] = truncate_text(normalized["url"], limit: MAX_ITEM_TEXT_LENGTH) if normalized["url"].present?

      if result["url"].blank? && normalized["html"].present?
        result["urls"] = urls_from_html(normalized["html"])
      end

      result
    end

    def sanitize_attachment_hash(value)
      return unless value.is_a?(Hash)

      value = value.stringify_keys

      TEXT_METADATA_KEYS.each_with_object({}) do |key, hash|
        text = truncate_text(text_with_link_destinations(value[key].to_s), limit: MAX_ITEM_TEXT_LENGTH)
        hash[key] = text if text.present?
      end
    end

    def text_with_link_destinations(string)
      return string.squish unless string.match?(/<[^>]+>/)

      fragment = Loofah.fragment(string)
      fragment.css("a[href]").each do |node|
        href = safe_href(node["href"])
        node.after(" (#{href})") if href.present?
      end
      fragment.text(encode_special_chars: false).squish
    end

    def urls_from_html(html)
      fragment = Loofah.fragment(html)

      fragment.css("[src], a[href]").filter_map do |node|
        safe_href(node["src"] || node["href"])
      end.uniq.first(MAX_COLLECTION_ITEMS)
    end

    def safe_href(value)
      Folio::HtmlSanitization::Sanitizer.sanitize_href(value.to_s)
    end

    def truncate_text(value, limit: MAX_TEXT_LENGTH)
      text = value.to_s.squish
      return if text.blank?
      return text if text.length <= limit

      "#{text.first(limit)}..."
    end

    def metadata_hash
      {
        "attachments" => [],
        "embeds" => [],
        "links" => [],
      }
    end

    def add_metadata_item(metadata, key, value)
      metadata[key] << value if context_present?(value)
    end

    def deduplicate_items(items)
      items.uniq.first(MAX_COLLECTION_ITEMS)
    end

    def context_present?(value)
      case value
      when Hash
        value.compact_blank.present?
      when Array
        value.compact_blank.present?
      else
        value.present?
      end
    end

    def ignored_key?(key)
      key = attribute_name(key)

      IGNORED_KEYS.include?(key) ||
        key.end_with?("_id") ||
        key.end_with?("_ids") ||
        sensitive_key?(key)
    end

    def sensitive_key?(key)
      SENSITIVE_KEY_PATTERNS.any? { |pattern| key.match?(pattern) }
    end

    def destroyed_hash?(value)
      value = value.stringify_keys
      destroy_value?(value["_destroy"])
    end

    def destroy_value?(value)
      value == true || value.to_s == "1" || value.to_s.casecmp?("true")
    end

    def record_class
      record&.class
    end
end
