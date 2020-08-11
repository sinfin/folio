# frozen_string_literal: true

class Folio::Console::WithIconCell < Folio::ConsoleCell
  class_name 'f-c-with-icon', :href, :small, :reversed, :muted

  def tag
    h = { class: class_name, tag: :div }

    if options[:href]
      h[:tag] = :a
      h[:href] = options[:href]
    end

    h
  end
end
