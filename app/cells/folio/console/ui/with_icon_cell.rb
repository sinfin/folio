# frozen_string_literal: true

class Folio::Console::Ui::WithIconCell < Folio::ConsoleCell
  class_name "f-c-ui-with-icon"

  def tag
    h = options[:tag] || {}

    h[:class] = "#{class_name} #{options[:class]}"
    h[:tag] ||= :span
    h[:data] = options[:data]

    if options[:block]
      h[:class] += " d-flex"
    end

    if options[:href]
      h[:tag] = :a
      h[:target] = options[:target]
      h[:href] = options[:href]
    end

    h
  end
end
