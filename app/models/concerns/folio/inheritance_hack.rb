# frozen_string_literal: true

# ActiveRecord::SubclassNotFound workaround, see
# https://github.com/spree/spree/blob/b2563446a3ba828fd867699bbaca8bdaba15f937/core/app/models/spree/image.rb#L6
#
# In Rails 5.x class constants are being undefined/redefined during the code reloading process
# in a rails development environment, after which the actual ruby objects stored in those class constants
# are no longer equal (subclass == self) what causes error ActiveRecord::SubclassNotFound
# Invalid single-table inheritance type: Spree::Image is not a subclass of Spree::Image.
# The line below prevents the error.
module Folio::InheritanceHack
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = nil

    after_initialize do
      self.type = self.class.to_s unless self.class.to_s.end_with?('Base')
    end
  end
end
