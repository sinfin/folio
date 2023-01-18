# frozen_string_literal: true

module Folio::PagesControllerBase
  extend ActiveSupport::Concern

  included do
    include Folio::UrlHelper

    before_action :find_page, :add_meta
  end

  def show
    if @page.published?
      render_page unless force_correct_path_for_page
    else
      redirect_to(action: :preview)
    end
  end

  def preview
    if @page.published?
      redirect_to(action: :show)
    else
      render_page
    end
  end

  private
    def render_page
      if @page.class.view_name
        render @page.class.view_name
      else
        render "folio/pages/show"
      end
    end

    def find_page
      if Rails.application.config.folio_pages_ancestry
        path = params[:path].split("/")

        set_nested_page(pages_scope, path.shift, last: path.size == 1)

        path.each_with_index do |slug, i|
          set_nested_page(filter_pages_by_locale(@page.children),
                          slug,
                          last: path.size - 1 == i)
        end
      else
        if page_includes.present?
          base = pages_scope.includes(*page_includes)
        else
          base = pages_scope
        end

        @page = base.published_or_admin(current_account.present?)
                    .friendly
                    .find(params[:id])
        add_breadcrumb @page.title, url_for(@page)
      end

      unless @page.class.public?
        if @page.class.public_rails_path
          redirect_to send(@page.class.public_rails_path)
        else
          fail ActiveRecord::RecordNotFound
        end
      end
    end

    def add_meta
      set_meta_variables(@page)
    end

    def filter_pages_by_locale(pages)
      if Rails.application.config.folio_pages_locales
        pages.by_locale(I18n.locale)
      else
        pages
      end
    end

    def pages_scope
      base = Folio::Page

      unless Rails.application.config.folio_site_is_a_singleton
        base = base.where(site: current_site)
      end

      base = base.roots if Rails.application.config.folio_pages_ancestry
      filter_pages_by_locale(base)
    end

    def set_nested_page(scoped, slug, last: false)
      if last && page_includes.present?
        base = scoped.includes(*page_includes)
      else
        base = scoped
      end

      @page = base.published_or_admin(current_account.present?)
                  .friendly
                  .find(slug)
      add_breadcrumb @page.title, nested_page_path(@page)
    end

    def page_includes
      []
    end

    def force_correct_path_for_page
      force_correct_path(url_for(@page))
    end
end
