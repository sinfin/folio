# frozen_string_literal: true

class Dummy::Ui::BreadcrumbsComponent < ApplicationComponent
  bem_class_name :share

  def initialize(breadcrumbs:, pagy_page: false, share: nil)
    @breadcrumbs = breadcrumbs
    @pagy_page = pagy_page
    @share = share
  end

  def breadcrumbs
    @breadcrumbs.present? && @breadcrumbs.length > 0 && (@breadcrumbs[-2] || @breadcrumbs[0])
  end

  def data
    stimulus_controller("d-ui-breadcrumbs")
  end
end
