# frozen_string_literal: true

class Folio::Console::Show::HeaderCell < Folio::ConsoleCell
  def edit_url
    options[:edit_url] || url_for([:edit, :console, model])
  rescue NoMethodError
  end

  def edit_class_name
    options[:edit_class_name] || 'btn btn-outline'
  end

  def destroy_url
    options[:destroy_url]
  end

  def destroy_class_name
    options[:destroy_class_name] || 'btn btn-outline-danger'
  end
end
