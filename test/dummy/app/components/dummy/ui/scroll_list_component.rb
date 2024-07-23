# frozen_string_literal: true

class Dummy::Ui::ScrollListComponent < ApplicationComponent
  def initialize(components: nil, html: nil, gap: 3, mobile_gap: nil)
    @components = components
    @html = html
    @gap = gap
    @mobile_gap = mobile_gap || gap
  end

  def data
    stimulus_controller("d-ui-scroll-list",
                        values: { touch: false })
  end

  def data_for_outer
    stimulus_data(target: "outer",
                  action: "scroll:debouncedOnScroll")
  end
end
