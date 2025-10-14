# frozen_string_literal: true

module Folio::Console::Component::IndexFilters
  def index_filters
    if controller.respond_to?(:index_filters, true)
      controller.send(:index_filters)
    end
  end

  def index_filters_hash
    @index_filters_hash ||= begin
      h = {}

      if index_filters
        index_filters.each do |key, config|
          if config == :date_range
            h[key] = { as: :date_range }
          elsif config.is_a?(Array)
            h[key] = { as: :collection, collection: config }
          elsif config.is_a?(String)
            h[key] = { as: :autocomplete, url: config }
          elsif config.is_a?(Hash)
            h[key] = config
          else
            raise "Invalid index filter type - #{key}"
          end
        end
      end

      h
    end
  end

  def filtered?
    return @filtered unless @filtered.nil?

    @filtered = index_filters_hash.any? do |key, _config|
      filtered_by?(key)
    end
  end

  def filtered_by?(key)
    config = index_filters_hash[key]

    if config[:as] == :hidden
      false
    elsif config[:as] == :numeric_range
      controller.params["#{key}_from"].present? || controller.params["#{key}_to"].present?
    else
      controller.params[key].present?
    end
  end

  def select2_select(f, key, data, url:)
    collection = []

    if controller.params[key].present?
      klass = data[:klass].constantize
      klass = klass.by_site(Folio::Current.site) if klass.try(:has_belongs_to_site?) && Folio::Current.site.present?

      if data[:id_method] && klass.column_names.include?(data[:id_method].to_s)
        record = klass.find_by(data[:id_method] => controller.params[key])
        collection << [record.to_console_label, record.send(data[:id_method]), selected: true] if record
      elsif data[:slug]
        record = klass.find_by_slug(controller.params[key])
        collection << [record.to_console_label, record.slug, selected: true] if record
      else
        record = klass.find_by_id(controller.params[key])
        collection << [record.to_console_label, record.id, selected: true] if record
      end
    end

    f.input key, collection:,
                 force_collection: true,
                 label: false,
                 remote: url,
                 include_blank: "#{label_for_key(key)}...",
                 wrapper_html: { class: "input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 clear_button: controller.params[key].present?
  end
end
