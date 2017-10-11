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

    def node_types_for_select
      for_select = []
      get_subclasses(Folio::Node).flatten.each do |type|
        for_select << [t("node_names.#{type}"), type] if type.partial
      end
      for_select
    end
  end
end
