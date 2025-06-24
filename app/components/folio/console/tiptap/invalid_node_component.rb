# frozen_string_literal: true

class Folio::Console::Tiptap::InvalidNodeComponent < Folio::Console::ApplicationComponent
  def initialize(node:, error: nil)
    @node = node
    @error = error
  end
end
