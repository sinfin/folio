# frozen_string_literal: true

def get_subclasses(node)
  [node] + node.subclasses.map { |subclass| get_subclasses(subclass) }
end

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
      new_button(new_console_node_path(parent: parent.id),
                 label: Folio::Node.model_name.human)
    end

    def node_preview_button(node, opts = {})
      ico = icon 'eye'
      path = nested_page_path(node, add_parents: true)

      opts.reverse_merge!(class: 'btn btn-info', target: :_blank)

      link_to(ico, path, opts).html_safe
    end

    def node_types_for_select(node)
      for_select = []
      if node && !node.class.allowed_child_types.nil?
        node.class.allowed_child_types.each do |type|
          for_select << [
             type.model_name.human,
             type.to_s
          ]
        end
      else
        get_subclasses(Node).flatten.each do |type|
          for_select << [type.model_name.human, type] if type.view_name
        end
      end
      for_select
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
