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
  end
end
