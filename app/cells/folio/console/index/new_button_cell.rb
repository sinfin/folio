# frozen_string_literal: true

class Folio::Console::Index::NewButtonCell < Folio::ConsoleCell
  def show
    render if button_model.present?
  end

  def button_model
    h = {
      variant: :success,
      icon: :plus,
      label:,
    }

    if model[:react]
      h["data-controller"] = "f-click-trigger"
      h["data-f-click-trigger-target-value"] = '.modal.show f-c-r-dropzone-trigger, .modal.show .f-c-file-list__dropzone-trigger, .folio-react-wrap[data-mode="index"] f-c-r-dropzone-trigger, .folio-react-wrap[data-mode="index"] .f-c-file-list__dropzone-trigger'

      h
    elsif new_dropdown_links.present?
      h
    else
      url = model[:new_url] ? send(options[:new_url]) : default_url

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
