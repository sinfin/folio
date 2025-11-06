# frozen_string_literal: true

class Folio::Console::Ui::WithIconCell < Folio::ConsoleCell
  class_name "f-c-ui-with-icon"

  def tag
    h = options[:tag] || {}

    h[:class] = "#{class_name} #{options[:class]}"
    h[:data] ||= {}
    h[:tag] ||= :span

    if options[:href]
      h[:tag] = :a
      h[:target] = options[:target]
      h[:href] = options[:href]
      h[:data][:method] = options[:method]
    end

    if options[:form_modal].present?
      h[:data] = stimulus_merge(h[:data], stimulus_console_form_modal_trigger(options[:form_modal], title: options[:form_modal_title]))
    end

    h
  end
end
