# frozen_string_literal: true

module Folio::PagesControllerBase
  extend ActiveSupport::Concern

  included do
    before_action :find_page
  end

  def show
    unless force_correct_path_for_page
      if @page.class.view_name
        render @page.class.view_name
      else
        render
      end
    end
  end

  private
    def pages_show_cache_key
      if respond_to?(:cache_key_base)
        ["pages#show", params[:path]] + cache_key_base
      else
        ["pages#show", params[:path]]
      end
    end

    def find_page
      folio_run_unless_cached(pages_show_cache_key) do
        if Rails.application.config.folio_pages_ancestry
          path_parts = params[:path].split("/")
          pages = []

          first_slug = path_parts.shift
          pages << set_nested_page(pages_scope, first_slug, last: path_parts.size == 0)

          path_parts.each_with_index do |slug, i|
            pages << set_nested_page(filter_pages_by_locale(@page.children),
                                     slug,
                                     last: path_parts.size - 1 == i)
          end

          if !@preview_token_valid_for_last && pages.any? { |page| !page.published? }
            fail ActiveRecord::RecordNotFound
          end
        else
          @page = pages_scope.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                             .friendly.find(params[:id])

          add_breadcrumb @page.title, url_for(@page)
        end

        unless @page.class.public?
          if @page.class.public_rails_path
            redirect_to send(@page.class.public_rails_path)
          else
            fail ActiveRecord::RecordNotFound
          end
        end

        set_meta_variables(@page) if @page
      end
    end

    def filter_pages_by_locale(pages)
      if Rails.application.config.folio_pages_locales
        pages.by_locale(I18n.locale)
      else
        pages
      end
    end

    def pages_scope
      base = Folio::Page.by_site(current_site)

      base = base.roots if Rails.application.config.folio_pages_ancestry
      filter_pages_by_locale(base)
    end

    def set_nested_page(scoped, slug, last: false)
      base = scoped

      if last
        base = base.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
      end

      @page = base.friendly.find(slug)

      if last
        @preview_token_valid_for_last = params[Folio::Publishable::PREVIEW_PARAM_NAME] == @page.preview_token
      end

      @ancestry_any_unpublished ||= !@page.published?

      add_breadcrumb @page.title, nested_page_path(@page)

      @page
    end

    def force_correct_path_for_page
      force_correct_path(url_for(@page))
    end
end
