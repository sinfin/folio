# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::Form::InputComponent < Folio::Console::ApplicationComponent
  def initialize(f:, key:, attr_config:)
    @f = f
    @key = key
    @attr_config = attr_config
  end

  private
    def input
      case @attr_config[:type]
      when :string, :text, :integer, :url_json, :rich_text
        send("render_input_#{@attr_config[:type]}")
      when :nested_nodes
        render(Folio::Console::Tiptap::Overlay::Form::NestedNodesComponent.new(
          f: @f,
          key: @key,
          attr_config: @attr_config,
        ))
      when :folio_attachment
        if @attr_config[:has_many]
          render_react_files
        else
          render_file_picker
        end
      when :collection
        render_collection_select
      when :relation
        render_relation_select
      when :embed
        render_embed_input
      else
        raise ArgumentError, "Unsupported input type: #{@attr_config[:type]}"
      end
    end

    def hint
      raw = @attr_config[:hint]
      return if raw.blank?

      raw.is_a?(Proc) ? raw.call(@f.object) : raw
    end

    def render_input_string
      @f.input @key,
               as: :string,
               character_counter: true,
               placeholder: default_value,
               hint:
    end

    def render_input_integer
      @f.input @key,
               as: :integer,
               hint:,
               input_html: {
                 step: 1,
                 value: @f.object.send(@key) || @f.object.class.structure[@key][:default],
                 min: @f.object.class.structure[@key][:minimum],
                 max: @f.object.class.structure[@key][:maximum]
               }
    end

    def render_input_text
      @f.input @key,
               as: :text,
               autosize: true,
               character_counter: true,
               hint:
    end

    def render_input_url_json
      @f.input @key,
               as: :url_json,
               hint:
    end

    def render_input_rich_text
      @f.input @key,
               as: :tiptap,
               hint:
    end

    def render_file_picker
      content_tag(:div, class: "f-c-tiptap-overlay-form__react-file-picker f-c-tiptap-overlay-form__react-file-picker--#{@key}") do
        helpers.file_picker(f: @f,
                            placement_key: @attr_config[:placement_key],
                            file_klass: @attr_config[:file_type].constantize)
      end
    end

    def render_react_files
      if @attr_config[:file_type] == "Folio::File::Image"
        helper_name = :react_images
      elsif @attr_config[:file_type] == "Folio::File::Document"
        helper_name = :react_documents
      else
        fail ArgumentError, "Unsupported type for react files: #{@attr_config[:file_type]}"
      end

      selected_placements = @f.object.send(@attr_config[:placement_key])

      content_tag(:div, class: "f-c-tiptap-overlay-form__react-files form-group") do
        helpers.send(helper_name,
                     selected_placements,
                     attachmentable: @f.object_name,
                     type: "#{@key.to_s.singularize}_placements")
      end
    end

    def render_relation_select
      class_name = @attr_config[:class_name]

      unless class_name && class_name.constantize < ActiveRecord::Base
        fail ArgumentError, "Missing class_name for relation select"
      end

      if @attr_config[:has_many]
        render_relation_select_for_has_many
      else
        render_relation_select_for_single(class_name)
      end
    end

    def render_collection_select
      collection = @attr_config[:collection].map do |value|
        [@f.object.class.human_attribute_name("#{@key}/#{value.nil? ? "nil" : value}"), value]
      end

      @f.input @key,
               collection:,
               include_blank: false,
               hint:
    end

    def render_relation_select_for_has_many
      input_name = "#{@key}_ids"

      collection = @f.object.send(@key).map do |record|
        [record.to_console_label, record.id, selected: true]
      end

      @f.input input_name,
               input_html: { value: collection.map(&:first).join(", ") },
               hint: hint.presence || "TODO with a better remote multi-select"
    end

    def render_relation_select_for_single(class_name)
      input_name = "#{@key}_id"
      collection = []
      record = @f.object.send(@key)
      collection << [record.to_console_label, record.id, selected: true] if record.present?

      @f.input input_name,
               collection:,
               remote: true,
               label: @f.object.class.human_attribute_name(@key),
               reflection_class_name: class_name,
               hint:
    end

    def render_embed_input
      @f.input @key,
               as: :embed,
               centered: true,
               hint:
    end

    def default_value
      return unless @attr_config.key?(:default)

      if @attr_config[:default].is_a?(Proc)
        @attr_config[:default].call(@f.object)
      else
        @attr_config[:default]
      end
    end
end
