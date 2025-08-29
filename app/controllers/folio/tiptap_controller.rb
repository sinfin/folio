# frozen_string_literal: true

class Folio::TiptapController < ApplicationController
  before_action :set_layout_flags

  def block_editor
  end

  def rich_text_editor
  end

  private
    def set_layout_flags
      @folio_tiptap = true
    end
end
