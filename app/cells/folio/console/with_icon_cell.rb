# frozen_string_literal: true

class Folio::Console::WithIconCell < Folio::ConsoleCell
  class_name "f-c-with-icon", :href, :small, :reversed, :muted

  def tag
    h = { class: class_name, tag: :div }

    if options[:href]
      h[:tag] = :a
      h[:href] = options[:href]
    end

    h
  end

  def mi_class_name
    if options[:mi] && options[:size]
      "mi--#{options[:size]}"
    end
  end

  def fa_class_name
    str = "fa-#{options[:fa]}"

    if options[:size]
      str += " fa--#{options[:size]}"
    end

    str
  end
end
