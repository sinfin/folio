# frozen_string_literal: true

module Folio
  module ReferencedFromMenuItems
    extend ActiveSupport::Concern

    included do
      has_many :menu_items, class_name: 'Folio::MenuItem',
                            as: :target,
                            dependent: :destroy
    end
  end
end
