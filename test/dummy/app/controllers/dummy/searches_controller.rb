# frozen_string_literal: true

class Dummy::SearchesController < ApplicationController
  before_action :set_search

  DEFAULT_OVERVIEW_LIMIT = 4
  DEFAULT_LIMIT = 40
  DEFAULT_RESULTS_CELL = "dummy/searches/results_list"
  DEFAULT_AUTOCOMPLETE_RESULTS_CELL = "dummy/searches/results_list"

  def show
  end

  def autocomplete
  end

  private
    def set_search
      @search = {
        klasses: {},
        count: 0,
        tabs: [],
        active_results: nil,
      }

      @search[:tabs] << {
        label: t("dummy.searches.show.tabs.overview"),
        href: dummy_search_path(q: params[:q], tab: nil),
      }

      has_active = false

      # cell defaults to "dummy/searches/results_list"
      [
        {
          klass: Folio::Page,
          limit: DEFAULT_LIMIT,
          overview_limit: DEFAULT_OVERVIEW_LIMIT,
          includes: [cover_placement: :file],
          results_cell: "dummy/searches/results_list",
          autocomplete_results_cell: "dummy/searches/results_list",
        },
      ].each do |meta|
        scope = meta[:klass].published

        scope = scope.includes(*meta[:includes]) if meta[:includes].present?

        scope = scope.by_query(params[:q].presence)

        klass_pagy, klass_records = pagy(scope, items: meta[:overview_limit] || DEFAULT_OVERVIEW_LIMIT)
        count = klass_pagy.count
        label = I18n.t('dummy.searches.show.tabs.#{meta[:klass].to_s}', default: meta[:klass].model_name.human(count: 2))

        tab_href = dummy_search_path(q: params[:q], tab: label)

        @search[:klasses][meta[:klass]] = {
          pagy: klass_pagy,
          records: klass_records,
          count: count,
          label: "#{label} (#{count})",
          href: tab_href,
          results_cell: meta[:results_cell] || DEFAULT_RESULTS_CELL,
          autocomplete_results_cell: meta[:autocomplete_results_cell] || DEFAULT_AUTOCOMPLETE_RESULTS_CELL,
        }

        @search[:count] += count

        if count > 0
          active = params[:tab] == label
          has_active ||= active

          @search[:tabs] << {
            label: "#{label} (#{count})",
            active: active,
            href: tab_href,
          }

          if active
            results_pagy, results_records = pagy(scope, items: meta[:limit] || DEFAULT_LIMIT)

            @search[:active_results] = {
              pagy: results_pagy,
              records: results_records,
              results_cell: meta[:results_cell] || DEFAULT_RESULTS_CELL,
            }
          end
        end
      end

      unless has_active
        @search[:tabs][0][:active] = true
        @search[:overview] = true
      end
    end
end
