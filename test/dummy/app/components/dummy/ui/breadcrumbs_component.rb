# frozen_string_literal: true

class Dummy::Ui::BreadcrumbsComponent < ApplicationComponent
  bem_class_name :share

  def initialize(breadcrumbs:, share: nil, single: false)
    @breadcrumbs = breadcrumbs
    @share = share
    @single = single
  end

  def single?
    @single || @breadcrumbs.length == 1
  end

  def breadcrumb
    if @breadcrumbs.present? && @breadcrumbs.length > 0
      @breadcrumbs[-2] || @breadcrumbs[0]
    end
  end

  def breadcrumbs_ary
    if @breadcrumbs.present? && @breadcrumbs.length > 1
      @breadcrumbs
    end
  end

  def render?
    breadcrumb || breadcrumbs_ary
  end
end
