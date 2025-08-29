# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::FormComponent < Folio::Console::ApplicationComponent
  def initialize(node:)
    @node = node
  end

  private
    def data
      stimulus_controller("f-c-tiptap-overlay-form",
                          values: {
                            autoclick_cover: should_autoclick_cover?,
                          })
    end

    def should_autoclick_cover?
      @node.class.tiptap_config[:autoclick_cover] == true
    end

    def render_input(f:, key:, attr_config:)
      case attr_config[:type]
      when :string, :text, :integer, :url_json, :rich_text
        send("render_input_#{attr_config[:type]}", f:, key:)
      when :folio_attachment
        if attr_config[:has_many]
          render_react_files(f:, key:, attr_config:)
        else
          render_file_picker(f:, key:, attr_config:)
        end
      when :collection
        render_collection_select(f:, key:, attr_config:)
      when :relation
        render_relation_select(f:, key:, attr_config:)
      else
        raise ArgumentError, "Unsupported input type: #{attr_config[:type]}"
      end
    end

    def simple_form_as
      "tiptap_node_attrs[data]"
    end

    def form(&block)
      opts = {
        url: "#form",
        method: :post,
        as: simple_form_as,
        html: {
          class: "f-c-tiptap-overlay-form__form",
          data: stimulus_action(submit: "onFormSubmit")
        },
      }

      helpers.simple_form_for(@node, opts, &block)
    end

    def render_input_string(f:, key:)
      f.input key,
              as: :string,
              character_counter: true
    end

    def render_input_integer(f:, key:)
      f.input key,
              as: :integer,
              input_html: {
                step: 1,
                value: f.object.send(key) || f.object.class.structure[key][:default],
                min: f.object.class.structure[key][:minimum],
                max: f.object.class.structure[key][:maximum]
              }
    end

    def render_input_text(f:, key:)
      f.input key,
              as: :text,
              autosize: true,
              character_counter: true
    end

    def render_input_url_json(f:, key:)
      f.input key,
              as: :url_json
    end

    def render_input_rich_text(f:, key:)
      f.input key,
              as: :tiptap
    end

    def render_file_picker(f:, key:, attr_config:)
      content_tag(:div, class: "f-c-tiptap-overlay-form__react-file-picker f-c-tiptap-overlay-form__react-file-picker--#{key}") do
        helpers.file_picker(f:,
                            placement_key: attr_config[:placement_key],
                            file_type: attr_config[:file_type])
      end
    end

    def render_react_files(f:, key:, attr_config:)
      if attr_config[:file_type] == "Folio::File::Image"
        helper_name = :react_images
      elsif attr_config[:file_type] == "Folio::File::Document"
        helper_name = :react_documents
      else
        fail ArgumentError, "Unsupported type for react files: #{type}"
      end

      selected_placements = @node.send(attr_config[:placement_key])

      content_tag(:div, class: "f-c-tiptap-overlay-form__react-files form-group") do
        helpers.send(helper_name,
                     selected_placements,
                     attachmentable: simple_form_as,
                     type: "#{key.to_s.singularize}_placements")
      end
    end

    def render_relation_select(f:, key:, attr_config:)
      class_name = attr_config[:class_name]

      unless class_name && class_name.constantize < ActiveRecord::Base
        fail ArgumentError, "Missing class_name for relation select"
      end

      if attr_config[:has_many]
        render_relation_select_for_has_many(f:, key:, class_name:)
      else
        render_relation_select_for_single(f:, key:, class_name:)
      end
    end

    def render_collection_select(f:, key:, attr_config:)
      collection = attr_config[:collection].map do |value|
        [@node.class.human_attribute_name("#{key}/#{value.nil? ? "nil" : value}"), value]
      end

      f.input key,
              collection: collection,
              include_blank: false
    end

    def render_relation_select_for_has_many(f:, key:, class_name:)
      input_name = "#{key}_ids"

      collection = @node.send(key).map do |record|
        [record.to_console_label, record.id, selected: true]
      end

      f.input input_name,
              input_html: { value: collection.map(&:first).join(", ") },
              hint: "TODO with a better remote multi-select"
    end

    def render_relation_select_for_single(f:, key:, class_name:)
      input_name = "#{key}_id"
      collection = []
      record = @node.send(key)
      collection << [record.to_console_label, record.id, selected: true] if record.present?

      f.input input_name,
              collection:,
              remote: true,
              label: @node.class.human_attribute_name(key),
              reflection_class_name: class_name
    end

    def buttons_model
      [
        {
          variant: :primary,
          type: :submit,
          label: t(".submit"),
        },
        {
          icon: :close,
          variant: :icon,
          data: stimulus_action(click: "onCancelClick"),
        },
      ]
    end

    def form_rows
      single_attachments = {}
      multi_attachments = {}
      rest = {}

      @node.class.structure.each do |key, type|
        if type.in?([:image, :document, :video, :audio])
          single_attachments[key] = type
        elsif type.in?([:images, :documents])
          multi_attachments[key] = type
        else
          rest[key] = type
        end
      end

      rows = []

      if single_attachments.present?
        rows << { columns: [
          { structure: single_attachments, bem_modifier: "single-attachments" },
          { structure: rest, bem_modifier: "main" },
        ] }
      else
        rows << { columns: [ { structure: rest } ] }
      end

      if multi_attachments.present?
        rows << { columns: [ structure: multi_attachments, bem_modifier: "multi-attachments" ] }
      end

      rows
    end
end
