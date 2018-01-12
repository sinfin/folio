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
      new_button new_console_node_path(parent: parent.id),
        label: t('node_names.Folio::Node')
    end

    def node_types_for_select(node)
      for_select = []
      if node && !node.class.allowed_child_types.nil?
        node.class.allowed_child_types.each do |type|
          for_select << [
             t("node_names.#{type}"),
             type.to_s
          ]
        end
      else
        get_subclasses(Folio::Node).flatten.each do |type|
          for_select << [t("node_names.#{type}"), type] if type.view_name
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
