# frozen_string_literal: true

class Folio::Console::Links::Modal::ListComponent < Folio::Console::ApplicationComponent
  include Pagy::Backend

  def records_data
    @records_data ||= page_links.merge(additional_links).filter_map do |klass, url_proc|
      next if Folio::Current.site.blank?

      scope = klass
      scope = scope.by_site(Folio::Current.site) if scope.respond_to?(:by_site)
      scope = scope.accessible_by(Folio::Current.ability)

      if scope.respond_to?(:by_query) && params[:q].present?
        scope = scope.by_query(params[:q])
      elsif scope.respond_to?(:ordered)
        scope = scope.ordered
      else
        scope = scope.order(id: :desc)
      end

      pagy_ref, records = pagy(scope, items: 5)

      if records.present?
        {
          klass:,
          url_proc:,
          records:,
          pagy: pagy_ref,
        }
      end
    end
  end

  def page_links
    if Rails.application.config.folio_pages_ancestry
      {
        Folio::Page => Proc.new { |page| controller.main_app.page_path(page.to_preview_param) }
      }
    else
      {
        Folio::Page => Proc.new { |page| controller.main_app.url_for(page) }
      }
    end
  end

  def additional_links
    @additional_links ||= Rails.application.config.folio_console_links_mapping
  end

  def rails_paths
    @rails_paths ||= Rails.application.class.module_parent.try(:rails_paths)
  end

  def data
    stimulus_controller("f-c-links-modal-list")
  end

  def record_to_data(data:, record:)
    stimulus_action(click: "onRecordClick").merge(
      url_json: {
        record_id: record.id,
        record_type: record.class.base_class.name,
        href: data[:url_proc].call(record),
        label: record.to_label,
      }.to_json
    )
  end
end
