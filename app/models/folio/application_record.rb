# frozen_string_literal: true

class Folio::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Folio::ClearsPageCache
  include Folio::Filterable
  include Folio::NillifyBlanks
  include Folio::RecursiveSubclasses
  include Folio::Sortable

  def to_label
    try(:title).presence ||
    try(:name).presence ||
    self.class.model_name.human
  end
end
