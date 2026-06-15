# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::Form::LayoutComponent < Folio::Console::ApplicationComponent
  def initialize(f:, node:)
    @f = f
    @node = node
  end

  private
    def layout
      @node.class.form_layout
    end

    def render_layout
      case layout
      when nil
        render_flat_layout
      when :aside_attachments
        render_aside_attachments_layout
      when Hash
        render_custom_layout(layout)
      else
        fail ArgumentError, "Unsupported Tiptap form layout: #{layout.inspect}"
      end
    end

    def render_flat_layout
      render_row([
        {
          fields: structure.keys,
        },
      ])
    end

    def render_aside_attachments_layout
      rows = []
      before_attachment_fields = []
      single_attachment_fields = []
      after_attachment_fields = []
      multi_attachment_fields = []
      seen_single_attachment = false

      structure.each do |key, attr_config|
        if single_attachment?(attr_config)
          single_attachment_fields << key
          seen_single_attachment = true
        elsif multi_attachment?(attr_config)
          multi_attachment_fields << key
        elsif seen_single_attachment
          after_attachment_fields << key
        else
          before_attachment_fields << key
        end
      end

      rows << [{ fields: before_attachment_fields }] if before_attachment_fields.present?

      if single_attachment_fields.present?
        rows << [
          { fields: single_attachment_fields },
          { fields: after_attachment_fields },
        ].reject { |column| column[:fields].blank? }
      elsif after_attachment_fields.present?
        rows << [{ fields: after_attachment_fields }]
      end

      rows << [{ fields: multi_attachment_fields }] if multi_attachment_fields.present?

      safe_join(rows.map { |columns| render_row(columns) })
    end

    def render_custom_layout(layout_node)
      if layout_node[:rows]
        safe_join(layout_node[:rows].map { |row| render_custom_row(row) })
      elsif layout_node[:columns]
        render_custom_row(layout_node)
      else
        fail ArgumentError, "Unsupported Tiptap form layout node: #{layout_node.inspect}"
      end
    end

    def render_custom_row(layout_node)
      if layout_node.is_a?(Hash) && layout_node[:columns]
        render_row(layout_node[:columns].map { |column| { node: column } })
      else
        render_row([{ node: layout_node }])
      end
    end

    def render_custom_node(layout_node)
      if layout_node.is_a?(Hash)
        render_custom_layout(layout_node)
      else
        render_input(layout_node)
      end
    end

    def render_row(columns)
      content_tag(:div, class: "f-c-tiptap-overlay-form-layout__row") do
        safe_join(columns.map { |column| render_column(column) })
      end
    end

    def render_column(column)
      content_tag(:div, class: "f-c-tiptap-overlay-form-layout__col") do
        if column[:fields]
          safe_join(column[:fields].map { |key| render_input(key) })
        else
          render_custom_node(column[:node])
        end
      end
    end

    def render_input(key)
      render(Folio::Console::Tiptap::Overlay::Form::InputComponent.new(
        f: @f,
        key:,
        attr_config: structure.fetch(key),
      ))
    end

    def single_attachment?(attr_config)
      attr_config[:type] == :folio_attachment && !attr_config[:has_many]
    end

    def multi_attachment?(attr_config)
      attr_config[:type] == :folio_attachment && attr_config[:has_many]
    end

    def structure
      @node.class.structure
    end
end
