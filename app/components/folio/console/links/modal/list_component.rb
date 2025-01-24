# frozen_string_literal: true

class Folio::Console::Links::Modal::ListComponent < Folio::Console::ApplicationComponent
  include Pagy::Backend

  PAGY_ITEMS_MULTI = 5
  PAGY_ITEMS_SINGLE = 25

  def initialize(filtering: false)
    @filtering = filtering
  end

  def records_data
    @records_data ||= begin
      ary = all_links.filter_map do |class_name, url_proc|
        next if Folio::Current.site.blank?

        class_from_params = if params[:class_name].present?
          runner = params[:class_name].safe_constantize
          runner if runner < ActiveRecord::Base
        end

        klass = class_name.safe_constantize
        items = class_from_params ? PAGY_ITEMS_SINGLE : PAGY_ITEMS_MULTI

        if klass && klass < ActiveRecord::Base
          if class_from_params
            next unless klass <= class_from_params
          end

          scope = klass
          scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
          scope = scope.accessible_by(Folio::Current.ability)

          if klass.try(:has_folio_attachments?)
            scope = scope.includes(cover_placement: :file)
          end

          if @filtering
            if params[:published_within].present?
              from, to = params[:published_within].split(/ ?- ?/)

              next unless scope.column_names.include?("published_at")

              if from.present?
                from_date_time = DateTime.parse(from)
                scope = scope.where("published_at >= ?", from_date_time)
              end

              if to.present?
                to = "#{to} 23:59" if to.exclude?(":")
                to_date_time = DateTime.parse(to)
                scope = scope.where("published_at <= ?", to_date_time)
              end
            end

            understands_all_filters = true

            Rails.application.config.folio_console_links_additional_filters.each do |key, data|
              value = params[key].presence

              if value.present?
                if understands_all_filters && scope.respond_to?(key)
                  scope = scope.public_send(key, value)
                else
                  understands_all_filters = false
                end
              end
            end

            next unless understands_all_filters
          end

          if @filtering && scope.respond_to?(:by_label_query) && params[:q].present?
            scope = scope.by_label_query(params[:q])
          elsif @filtering && scope.respond_to?(:by_label_query) && params[:q].present?
            scope = scope.by_label_query(params[:q])
          elsif scope.respond_to?(:ordered)
            scope = scope.ordered
          else
            scope = scope.order(id: :desc)
          end

          pagy_ref, records = pagy(scope, items:)

          if records.present?
            {
              klass:,
              url_proc:,
              records:,
              pagy: pagy_ref,
              scope:,
            }
          end
        end
      end

      if ary.size == 1 && ary[0][:pagy].items === PAGY_ITEMS_MULTI
        pagy_ref, records = pagy(ary[0][:scope], items: PAGY_ITEMS_SINGLE)
        ary[0][:pagy] = pagy_ref
        ary[0][:records] = records
      end

      ary
    end
  end

  def page_links
    if Rails.application.config.folio_pages_ancestry
      {
        "Folio::Page" => Proc.new { |controller, instance| controller.main_app.page_path(instance.to_preview_param) }
      }
    else
      {
        "Folio::Page" => Proc.new { |controller, instance| controller.main_app.url_for(instance) }
      }
    end
  end

  def additional_links
    @additional_links ||= Rails.application.config.folio_console_links_mapping
  end

  def data
    stimulus_controller("f-c-links-modal-list")
  end

  def all_links
    if additional_links["Folio::Page"]
      additional_links
    else
      additional_links.merge(page_links)
    end
  end

  def record_to_data(data:, record:)
    stimulus_action(click: "onRecordClick").merge(
      url_json: {
        record_id: record.id,
        record_type: record.class.base_class.name,
        href: data[:url_proc].call(controller, record),
        label: record.to_label,
      }.to_json
    )
  end
end
