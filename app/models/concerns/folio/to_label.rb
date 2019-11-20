# frozen_string_literal: true

module Folio::ToLabel
  extend ActiveSupport::Concern

  def to_label
    try(:title).presence ||
    try(:name).presence ||
    self.class.model_name.human
  end

  def to_console_label
    to_label
  end

  def to_autocomplete_label
    to_label
  end
end
