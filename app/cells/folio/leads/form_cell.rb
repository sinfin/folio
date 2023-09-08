# frozen_string_literal: true

class Folio::Leads::FormCell < Folio::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ::Recaptcha::ClientHelper

  class_name "f-leads-form", :flex?, :submitted?

  def show
    render if layout_template
  end

  def default_input_opts
    {
      note: {
        label: model ? t(".note") : nil,
        inner_html: {
          rows: 3,
          value: model.try(:note)
        }
      },
    }
  end

  def default_layout_template
    {
      rows: [
        %w[email phone],
        %w[note],
      ]
    }
  end

  def submitted?
    !lead.new_record?
  end

  def flex?
    layout_template[:flex]
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

  def message
    options[:message].presence || t(".message")
  end

  end

  def input_opts
    @input_opts ||= begin
      opts = options[:input_opts] || {}

      if opts.is_a?(String)
        opts = JSON.parse(opts).deep_symbolize_keys!
      end

      default_input_opts.deep_merge(opts)
    end
  end

  def layout_template
    @layout_template ||= begin
      layout_template = options[:layout] || default_layout_template

      if layout_template.is_a?(String)
        JSON.parse(layout_template).symbolize_keys
      else
        layout_template
      end
    end
  end

  def layout(structure_key)
    return unless layout_template[structure_key]

    layout_template[structure_key].map do |col|
      col.map do |field|
        opts = input_opts[field.to_sym] || {}

        if opts[:label].present?
          opts[:label] = opts[:label].html_safe
        end

        {
          name: field,
          opts:
        }
      end
    end
  end

  def rows_layout
    @rows_layout ||= layout(:rows)
  end

  def cols_layout
    @cols_layout ||= layout(:cols)
  end

  def additional_data_input(f)
    f.hidden_field :additional_data, value: lead.additional_data.try(:to_json)
  end

  def remember_option_keys
    [
      *Folio::LeadsController::REMEMBER_OPTION_KEYS,
      :input_opts
    ]
  end

  def remember_options
    @remember_options ||= remember_option_keys.filter_map do |opt_name|
      next unless options[opt_name]

      if opt_name == :layout
        val = layout_template.to_json
      elsif opt_name == :input_opts
        val = input_opts.to_json
      elsif %i[above_form under_form].include?(opt_name)
        val = options[opt_name].gsub(/="([^"]+)"/, "='\\1'")
      else
        val = options[opt_name]
      end

      [opt_name, ERB::Util.html_escape(val)]
    end || []
  end
end
