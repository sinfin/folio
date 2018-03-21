# frozen_string_literal: true

module Folio
  module Console::MenusHelper
    def menu_types_for_select
      Menu.subclasses.map do |type|
        [type.model_name.human, type]
      end
    end
  end
end
