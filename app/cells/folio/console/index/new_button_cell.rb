# frozen_string_literal: true

class Folio::Console::Index::NewButtonCell < Folio::ConsoleCell
  def show
    render if can_now?(:new, model[:klass]) && button_model.present?
  end

  def button_model
    h = {
      variant: :success,
      icon: :plus,
      label:,
    }

    if model[:popover]
      h["data-controller"] = "f-c-popover"
      h["data-f-c-popover-content-value"] = model[:popover]
      h["data-f-c-popover-placement-value"] = "bottom"
      h["data-f-c-popover-trigger-value"] = "focus"

      h
    elsif model[:file_list_uppy]
      h[:data] = stimulus_click_trigger(".f-file-list-trigger")
      h
    elsif new_dropdown_links.present?
      if new_dropdown_links.size == 1
        h[:href] = new_dropdown_links.first[:url]
      end

      h
    else
      url = model[:url] || (model[:new_path_name] ? send(model[:new_path_name]) : default_url)

      if url
        h[:href] = url

        h
      end
    end
  end

  def default_url
    through_aware_console_url_for(model[:klass], action: :new, safe: true)
  end

  def new_dropdown_links
    @new_dropdown_links ||= if model[:new_dropdown_links].present?
      model[:new_dropdown_links]
    elsif model[:types].present?
      model[:types].map do |klass, icon|
        {
          title: klass.model_name.human,
          url: through_aware_console_url_for(model[:klass], action: :new, hash: { type: klass.to_s }, safe: true),
          icon:
        }
      end
    end
  end

  def label
    t(".add")
  end
end
