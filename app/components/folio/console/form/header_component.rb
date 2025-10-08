# frozen_string_literal: true

class Folio::Console::Form::HeaderComponent < Folio::Console::ApplicationComponent
  def initialize(model:,
                title:,
                title_class_name: nil,
                subtitle: nil,
                left: nil,
                right: nil,
                sti_badge: false,
                tabs: nil,
                hide_fix_error_btn: false)
    @model = model
    @title = title
    @title_class_name = title_class_name
    @subtitle = subtitle
    @left = left
    @right = right
    @sti_badge = sti_badge
    @tabs = tabs
    @hide_fix_error_btn = hide_fix_error_btn
  end

  def record
    @model.try(:object) || @model
  end

  # todo seems to be unused
  def translations
    cell("folio/console/pages/translations", record, as_pills: true)
  end
end
