# frozen_string_literal: true

class Dummy::Ui::BreadcrumbsComponent < ApplicationComponent
  bem_class_name :share

  def initialize(breadcrumbs:, share: nil, single: true)
    @breadcrumbs = breadcrumbs
    @share = share
    @single = single
  end

  def single?
    @single
  end

  def breadcrumb
    if @breadcrumbs.present? && @breadcrumbs.length > 1
      @breadcrumbs[-2] || @breadcrumbs[0]
    end
  end

  def breadcrumbs_ary
    if @breadcrumbs.present?
      @breadcrumbs
    end
  end

  def render?
    return false if @breadcrumbs.blank?

    if single?
      breadcrumb
    else
      breadcrumbs_ary
    end
  end
end
