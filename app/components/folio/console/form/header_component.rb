# frozen_string_literal: true

class Folio::Console::Form::HeaderComponent < Folio::Console::ApplicationComponent
  def initialize(f:,
                title:,
                title_class_name: nil,
                subtitle: nil,
                left: nil,
                right: nil,
                sti_badge: false,
                tabs: nil,
                hide_fix_error_btn: false)
    @f = f
    @title = title
    @title_class_name = title_class_name
    @subtitle = subtitle
    @left = left
    @right = right
    @sti_badge = sti_badge
    @tabs = tabs
    @hide_fix_error_btn = hide_fix_error_btn
  end

  private
    def record
      return @record if defined?(@record)

      @record = if @f.try(:object).is_a?(ActiveRecord::Base)
        @f.object
      end
    end
end
