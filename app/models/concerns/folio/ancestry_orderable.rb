# frozen_string_literal: true

module Folio::AncestryOrderable
  extend ActiveSupport::Concern

  def children_order_hash
    nil
  end
end
