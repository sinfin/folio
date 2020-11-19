# frozen_string_literal: true

class Folio::Console::Show::HeaderCell < Folio::ConsoleCell
  class_name "f-c-show-header", :no_border

  def edit_url
    options[:edit_url] || url_for([:edit, :console, model])
  rescue NoMethodError
  end

  def edit_class_name
    options[:edit_class_name] || "btn btn-secondary"
  end

  def preview_url
    options[:preview_url]
  end

  def destroy_url
    options[:destroy_url]
  end

  def destroy_class_name
    options[:destroy_class_name] || "btn btn-danger"
  end
end
