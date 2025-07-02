# frozen_string_literal: true

class Folio::Tiptap::Content::FolioTiptapNodeComponent < ApplicationComponent
  def initialize(record:, prosemirror_node:)
    @record = record
    @prosemirror_node = prosemirror_node

    @node = Folio::Tiptap::Node.new_from_attrs(ActionController::Parameters.new(@prosemirror_node["attrs"]))
  end
end
