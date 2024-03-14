# frozen_string_literal: true

class Dummy::SearchesController < ApplicationController
  include Folio::RenderComponentJson

  before_action :set_search

  DEFAULT_OVERVIEW_LIMIT = 4
  DEFAULT_LIMIT = 40
  DEFAULT_RESULTS_COMPONENT = Dummy::Searches::ResultsListComponent

  SEARCH_MODELS = [
    {
      klass: Folio::Page,
      limit: DEFAULT_LIMIT,
      overview_limit: DEFAULT_OVERVIEW_LIMIT,
      includes: [cover_placement: :file],
      results_component: DEFAULT_RESULTS_COMPONENT,
    },
  ]

  def show
    @public_page_title = t("dummy.searches.show_component.title")

    respond_to do |format|
      format.html { }
      format.json do
        render_component_json(Dummy::Searches::Show::ContentsComponent.new(search: @search))
      end
    end
  end

  def autocomplete
    render_component_json(Dummy::Searches::AutocompleteComponent.new(search: @search))
  end

  private
    def set_search
      @search = {
        klasses: {},
        count: 0,
        tabs: [],
        active_results: nil,
        q: params[:q]
      }

      @search[:tabs] << {
        label: t("dummy.searches.show.contents_component.tabs/overview"),
        href: dummy_search_path(q: params[:q], tab: nil),
      }

      has_active = false

      SEARCH_MODELS.each do |meta|
        scope = meta[:klass].published

        scope = scope.includes(*meta[:includes]) if meta[:includes].present?

        if params[:q].present?
          scope = scope.by_query(params[:q].presence)
        else
          scope = scope.none
        end

        klass_pagy, klass_records = pagy(scope, items: meta[:overview_limit] || DEFAULT_OVERVIEW_LIMIT)
        count = klass_pagy.count
        label = I18n.t("dummy.searches.show.contents_component.tabs/#{meta[:klass]}", default: meta[:klass].model_name.human(count: 2))

        tab_href = dummy_search_path(q: params[:q], tab: label)

        @search[:klasses][meta[:klass]] = {
          pagy: klass_pagy,
          records: klass_records,
          count:,
          label: "#{label} (#{count})",
          href: tab_href,
          results_component: meta[:results_component] || DEFAULT_RESULTS_COMPONENT,
        }

        @search[:count] += count

        if count > 0
          active = params[:tab] == label
          has_active ||= active

          @search[:tabs] << {
            label: "#{label} (#{count})",
            active:,
            href: tab_href,
          }

          if active
            results_pagy, results_records = pagy(scope, items: meta[:limit] || DEFAULT_LIMIT)

            @search[:active_results] = {
              pagy: results_pagy,
              records: results_records,
              results_component: meta[:results_component] || DEFAULT_RESULTS_COMPONENT,
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
