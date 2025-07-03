# frozen_string_literal: true

class Folio::Tiptap::Content::FolioTiptapNodeComponent < ApplicationComponent
  def initialize(record:, prose_mirror_node:)
    @record = record
    @prose_mirror_node = prose_mirror_node

    @node = Folio::Tiptap::Node.new_from_attrs(ActionController::Parameters.new(@prose_mirror_node["attrs"]))
  end
end
