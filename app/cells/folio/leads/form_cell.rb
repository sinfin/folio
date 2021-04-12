# frozen_string_literal: true

class Folio::Leads::FormCell < Folio::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ::Recaptcha::ClientHelper

  class_name "f-leads-form", :flex?, :submitted?

  def show
    render if layout
  end

  def form(&block)
    opts = {
      url: controller.folio.leads_path,
      html: { class: "f-leads-form__form" },
    }

    simple_form_for(lead, opts, &block)
  end

  def lead
    @lead ||= (model || new_lead)
  end

  def new_lead
    if options[:additional_data]
      Folio::Lead.new(additional_data: options[:additional_data])
    else
      Folio::Lead.new
    end
  end

  def submitted?
    !lead.new_record?
  end

  def flex?
    layout[:flex]
  end

  def note_value
    return options[:note] if options[:note]
    model.note if model
  end

  def note_label
    return options[:note_label] if options[:note_label]
    t(".note") if model
  end

  def message
    return options[:message] if options[:message]
    t(".message")
  end

  def note_rows
    return options[:note_rows] if options[:note_rows]
    3
  end

  def remember_option_keys
    Folio::LeadsController::REMEMBER_OPTION_KEYS
  end

  def additional_data_input(f)
    f.hidden_field :additional_data, value: lead.additional_data.try(:to_json)
  end

  def layout
    @layout ||= begin
      if options[:layout]
        if options[:layout].is_a?(String)
          JSON.parse(options[:layout]).symbolize_keys
        else
          options[:layout]
        end
      else
        default_layout
      end
    end
  end

  def default_layout
    {
      rows: [
        %w[email phone],
        %w[note],
      ]
    }
  end

  def input_for(f, col)
    if col == :note || col == "note"
      f.input(col, label: note_label,
                   input_html: { rows: note_rows, value: note_value })
    else
      f.input(col, label: t(".#{col}"))
    end
  end

  def remember_option(opt)
    if opt == :layout
      val = layout.to_json
    elsif %i[above_form under_form].include?(opt)
      val = options[opt].gsub(/="([^"]+)"/, "='\\1'")
    else
      val = options[opt]
    end

    ERB::Util.html_escape(val)
  end
end
