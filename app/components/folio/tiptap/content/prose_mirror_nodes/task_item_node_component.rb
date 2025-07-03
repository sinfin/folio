# frozen_string_literal: true

class Folio::Tiptap::Content::ProseMirrorNodes::TaskItemNodeComponent < ApplicationComponent
  def initialize(record:, prose_mirror_node:)
    @record = record
    @prose_mirror_node = prose_mirror_node

    @checked = @prose_mirror_node.dig("attrs", "checked") || false
  end
end
