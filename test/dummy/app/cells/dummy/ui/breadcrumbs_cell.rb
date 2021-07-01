# frozen_string_literal: true

class Dummy::Ui::BreadcrumbsCell < ApplicationCell
  class_name "d-ui-breadcrumbs", :share

  def show
    render if breadcrumb
  end

  def breadcrumb
    @breadcrumb ||= model.present? && model.length > 0 && (model[-2] || model[0])
  end

  def pagy_page?
    breadcrumb.options && breadcrumb.options[:pagy_page]
  end
end
