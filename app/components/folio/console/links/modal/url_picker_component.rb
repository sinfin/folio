# frozen_string_literal: true

class Folio::Console::Links::Modal::UrlPickerComponent < Folio::Console::ApplicationComponent
  include Folio::Console::Cell::IndexFilters

  def initialize(url_json:)
    @url_json = url_json
  end

  def before_render
    if @record.nil? && @url_json[:record_id].present? && @url_json[:record_type].present?
      klass = @url_json[:record_type].safe_constantize

      if klass < ActiveRecord::Base
        record = klass.find_by(id: @url_json[:record_id])

        if can_now?(:show, record)
          @record = record
        end
      end
    end
  end

  def tabs
    @tabs ||= begin
      first_active = @record.present? || @url_json[:href].blank?

      [
        { label: t(".tab/pick"), key: :pick, active: first_active },
        { label: t(".tab/custom_url"), key: :custom_url, active: !first_active }
      ]
    end
  end

  def data
    stimulus_controller("f-c-links-modal-url-picker",
                        action: {
                          "f-c-links-modal-list:selectedRecord" => "selectedRecord",
                          "f-c-input-form-group-url:edit" => "edit",
                          "f-c-input-form-group-url:remove" => "remove",
                        },
                        values: {
                          value_loading: false,
                          list_loading: false,
                          value_present: !!@record,
                          api_value_url: controller.value_console_api_links_path,
                          api_list_url: controller.list_console_api_links_path,
                          filtering: false,
                          autofocus_input: tabs[1][:active],
                        })
  end

  def cancel_button_model
    {
      data: stimulus_data(action: { click: "cancelFilters" }, target: "cancelButton"),
      variant: :danger,
      icon: :close,
      class: "f-c-links-modal-url-picker__list-filters-cancel-button"
    }
  end

  def filter_form(&block)
    opts = {
      url: "#filter",
      method: :get,
      html: {
        class: "f-c-links-modal-url-picker__list-filters-form",
        data: stimulus_data(action: {
          change: "onFormChange",
          folio_select2_change: "onFormChange",
          submit: "onFormSubmit"
        }, target: "form"),
      },
    }

    simple_form_for("", opts, &block)
  end

  def class_names_collection
    (%w[Folio::Page] + Rails.application.config.folio_console_links_mapping.keys).uniq.filter_map do |class_name|
      klass = class_name.safe_constantize

      if klass && klass < ActiveRecord::Base && can_now?(:show, klass)
        [klass.model_name.human, klass.to_s]
      end
    end
  end

  def additional_filters_hash
    Rails.application.config.folio_console_links_additional_filters
  end

  def additional_select(f, key, data)
    url = controller.folio.select2_console_api_autocomplete_path(klass: data[:klass],
                                                                 scope: data[:scope],
                                                                 order_scope: data[:order_scope],
                                                                 slug: data[:slug],
                                                                 label_method: data[:label_method])

    select2_select(f, key, data, url:)
  end

  def label_for_key(key)
    t(".placeholder/#{key}", default: key.to_s)
  end
end
