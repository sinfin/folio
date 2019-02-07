# frozen_string_literal: true

class Folio::Console::PagesController < Folio::Console::BaseController
  include Folio::Console::PagesHelper
  include Folio::Console::SetPositions
  handles_set_positions_for Folio::Page

  respond_to :json, only: %i[update]

  before_action :find_page, except: [:index, :create, :new, :set_positions]
  add_breadcrumb Folio::Page.model_name.human(count: 2), :console_pages_path

  def index
    if misc_filtering?
      if params[:by_parent].present?
        parent = Folio::Page.find(params[:by_parent])
        @pages = parent.subtree.original
                       .filter_by_params(filter_params)
                       .arrange(order: 'position asc, created_at asc')
      else
        pages = Folio::Page.original
                           .filter_by_params(filter_params)
        @pagy, @pages = pagy(pages)
      end
    else
      @limit = self.class.index_children_limit
      @pages = Folio::Page.original.arrange(order: 'position asc, created_at asc')
    end
  end

  def new
    if params[:page].blank? || params[:page][:original_id].blank?
      parent = Folio::Page.find(params[:parent]) if params[:parent].present?
      @page = Folio::Page.new(parent: parent, type: params[:type])
    else
      original = Folio::Page.find(params[:page][:original_id])

      @page = original.translate!(params[:page][:locale])

      redirect_to edit_console_page_path(@page.id)
    end

    after_new
  end

  def create
    # set type first beacuse of @page.additional_params
    @page = Folio::Page.new(type: params[:page][:type])
    @page.update(page_params)
    if @page.new_record?
      respond_with @page, location: new_console_page_path
    else
      respond_with @page, location: edit_console_page_path(@page.id)
    end
  end

  def update
    @page.update(page_params)
    respond_with @page, location: edit_console_page_path(@page.id)
  end

  def destroy
    @page.destroy
    respond_with @page, location: console_pages_path
  end

  private

    def self.index_children_limit
      5
    end

    def after_new
    end

    def find_page
      @page = Folio::Page.friendly.find(params[:id])
    end

    def filter_params
      params.permit(:by_query, :by_published, :by_tag)
    end

    def page_params
      p = params.require(:page)
                .permit(:title,
                        :slug,
                        :perex,
                        :content,
                        :meta_title,
                        :meta_description,
                        :code,
                        :type,
                        :featured,
                        :published,
                        :published_at,
                        :locale,
                        :parent_id,
                        :original_id,
                        :tag_list,
                        *traco_params,
                        *additional_strong_params(@page),
                        *atoms_strong_params,
                        *file_placements_strong_params)
      p[:slug] = nil unless p[:slug].present?
      sti_atoms(p)
    end

    def traco_params
      if ::Rails.application.config.folio_using_traco
        I18n.available_locales.map do |locale|
          %i[title
             slug
             perex
             content
             meta_title
             meta_description].map { |p| "#{p}_#{locale}".to_sym }
        end.flatten
      else
        []
      end
    end

    def misc_filtering?
      %i[by_parent by_query by_published by_tag].any? { |by| params[by].present? }
    end

    def index_filters
      {
        by_parent: [
          [t('.filters.all_parents'), nil],
        ] + Folio::Page.original.roots.map { |n| [n.title, n.id] },
        by_published: [
          [t('.filters.all_pages'), nil],
          [t('.filters.published'), 'published'],
          [t('.filters.unpublished'), 'unpublished'],
        ],
      }
    end

    helper_method :index_filters

    def additional_strong_params(page)
      page.additional_params
    end
end
