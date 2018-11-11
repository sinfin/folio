# frozen_string_literal: true

class Folio::Console::ReactSelectCell < FolioCell
  BASE = nil

  def show
    render
  end

  def f
    model
  end

  def title
    return options[:title] if options[:title].present?

    if options[:cover]
      if model.is_a?(Folio::Atom::Base)
        t('.title_single')
      else
        t('.title_cover')
      end
    else
      if options[:multi]
        t('.title_multi')
      else
        t('.title_single')
      end
    end
  end

  def render_fields
    render(:fields)
  end

  def form_errors
    if f.object.errors.include?(key)
      f.object.errors[key]
    end
  end

  def has_one?
    false
  end
end
