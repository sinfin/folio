# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::FormComponent < Folio::Console::ApplicationComponent
  def initialize(node:)
    @node = node
  end

  private
    def data
      stimulus_controller("f-c-tiptap-overlay-form")
    end

    def render_input(f:, key:, type:)
      case type
      when :string, :text, :url_json, :rich_text
        send("render_input_#{type}", f:, key:)
      when :image, :document, :video, :audio
        render_file_picker(f:, key:, type:)
      when :images, :documents
        render_react_files(f:, key:, type:)
      when Hash
        render_relation_select(f:, key:, type:)
      else
        raise ArgumentError, "Unsupported input type: #{type}"
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

    def render_file_picker(f:, key:, type:)
      helpers.file_picker(f:,
                          placement_key: "#{key}_placement",
                          file_type: Folio::Tiptap::NodeBuilder.folio_attachments_file_class(type:).to_s)
    end

    def render_react_files(f:, key:, type:)
      if type == :images
        helper_name = :react_images
        Folio::FilePlacement::Image
      elsif type == :documents
        helper_name = :react_documents
        Folio::FilePlacement::Document
      else
        fail ArgumentError, "Unsupported type for react files: #{type}"
      end

      selected_placements = @node.send("#{key.to_s.singularize}_placements")

      helpers.send(helper_name,
                   selected_placements,
                   attachmentable: simple_form_as,
                   type: "#{key.to_s.singularize}_placements")
    end

    def render_relation_select(f:, key:, type:)
      class_name = type[:class_name]

      unless class_name && class_name.constantize < ActiveRecord::Base
        fail ArgumentError, "Missing class_name for relation select"
      end

      if type[:has_many]
        render_relation_select_for_has_many(f:, key:, type:, class_name:)
      else
        render_relation_select_for_single(f:, key:, type:, class_name:)
      end
    end

    def render_relation_select_for_has_many(f:, key:, type:, class_name:)
      input_name = "#{key}_ids"

      collection = @node.send(key).map do |record|
        [record.to_console_label, record.id, selected: true]
      end

      f.input input_name,
              input_html: { value: collection.map(&:first).join(", ") },
              hint: "TODO with a better remote multi-select"
    end

    def render_relation_select_for_single(f:, key:, type:, class_name:)
      input_name = "#{key}_id"
      collection = []
      record = @node.send(key)
      collection << [record.to_console_label, record.id, selected: true] if record.present?

      f.input input_name,
              collection:,
              remote: true,
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
