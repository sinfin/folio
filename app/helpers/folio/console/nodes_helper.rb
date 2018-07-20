# frozen_string_literal: true

module Folio
  module Console::NodesHelper
    def node_breadcrumbs(ancestors)
      unless ancestors.nil?
        links = ancestors.collect do |node|
          link_to(node.title, edit_console_node_path(node))
        end
        links.join(' / ')
      end
    end

    def new_child_node_button(parent)
      new_button(
        new_console_node_path(parent: parent.id),
        label: Node.model_name.human,
        title: t('folio.console.nodes.node_row.add_child_node')
      )
    end

    def node_preview_button(node, opts = {})
      path = nested_page_path(node, add_parents: true)
      custom_icon_button(path,
                         'eye',
                         title: t('folio.console.nodes.node_row.preview'),
                         target: :_blank)
    end

    def node_types_for_select(node)
      if node.is_a?(NodeTranslation)
        return [
          [NodeTranslation.model_name.human, 'Folio::NodeTranslation']
        ]
      end

      if node.present? && node.class.allowed_child_types.present?
        node.class.allowed_child_types.map do |klass|
          if klass.console_selectable? || node.instance_of?(klass)
            [klass.model_name.human, klass]
          end
        end.compact
      else
        Node.recursive_subclasses(include_self: false).map do |klass|
          if klass.console_selectable? || node.instance_of?(klass)
            [klass.model_name.human, klass]
          end
        end.compact
      end
    end

    def node_type_select(f)
      if f.object.is_a?(NodeTranslation)
        f.input :type, collection: node_types_for_select(f.object),
                       readonly: true,
                       disabled: true
      else
        f.input :type, collection: node_types_for_select(f.object),
                       include_blank: false
      end
    end

    def render_additional_form_fields(f)
      if f.object.type == 'Folio::NodeTranslation'
        # render node original class additional form fields
        f.object = f.object.cast
        content_tag :fieldset, data: { type: 'Folio::NodeTranslation' } do
          render 'folio/console/nodes/additional_form_fields',
            f: f,
            additional_params: f.object.class.additional_params,
            disabled: false
        end
      else
        if f.object.parent.present?
          types = f.object.parent.class.allowed_child_types
        else
          types = Node.recursive_subclasses
        end
        original_type = f.object.class

        return nil if types.blank?

        fields = types.map do |type|
          unless type.additional_params.blank?
            f.object = f.object.becomes(type)
            disabled = type != original_type
            content_tag :fieldset, data: { type: type.to_s }, style: ('display:none' if disabled) do
              render 'folio/console/nodes/additional_form_fields',
                f: f,
                additional_params: type.additional_params,
                disabled: disabled
            end
          end
        end.join('').html_safe

        f.object = f.object.becomes(original_type)

        fields
      end
    end

    def arrange_nodes_with_limit(nodes, limit)
      arranged = ActiveSupport::OrderedHash.new
      min_depth = Float::INFINITY
      index = Hash.new { |h, k| h[k] = ActiveSupport::OrderedHash.new }

      nodes.each do |node|

        children = index[node.id]
        index[node.parent_id][node] = children

        depth = node.depth
        if depth < min_depth
          min_depth = depth
          arranged.clear
        end

        break if !node.root? && index[node.parent_id].count >= limit

        arranged[node] = children if depth == min_depth
      end
      arranged
    end
  end
end
