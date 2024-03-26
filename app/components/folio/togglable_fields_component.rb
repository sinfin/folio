# frozen_string_literal: true

class Folio::TogglableFieldsComponent < Folio::ApplicationComponent
  def initialize(f:, attribute:, label: nil)
    @f = f
    @attribute = attribute
    @label = label
  end
end
