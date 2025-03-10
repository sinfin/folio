# frozen_string_literal: true

module Folio::Autosave::Model
  extend ActiveSupport::Concern

  def folio_autosave_enabled?
    true
  end
end
