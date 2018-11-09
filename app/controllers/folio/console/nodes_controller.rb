# frozen_string_literal: true

module Folio
  class Console::NodesController < Console::BaseController
    include Console::NodesHelper
    include Console::SetPositions
    handles_set_positions_for Node

    respond_to :json, only: %i[update]

    before_action :find_node, except: [:index, :create, :new, :set_positions]
    before_action :find_files, only: [:new, :edit, :create, :update]
    add_breadcrumb Node.model_name.human(count: 2), :console_nodes_path

    def index
      if misc_filtering?
        if params[:by_parent].present?
          parent = Node.find(params[:by_parent])
          @nodes = parent.subtree.original
                         .filter(filter_params)
                         .arrange(order: 'position asc, created_at asc')
        else
          @nodes = Node.original
                       .ordered.filter(filter_params)
                       .page(current_page)
        end
      else
        @limit = self.class.index_children_limit
        @nodes = Node.original.arrange(order: 'position asc, created_at asc')
      end
    end

    def new
      if params[:node].blank? || params[:node][:original_id].blank?
        parent = Node.find(params[:parent]) if params[:parent].present?
        @node = Page.new(parent: parent, type: params[:type])
      else
        original = Node.find(params[:node][:original_id])

        @node = original.translate!(params[:node][:locale])

        redirect_to edit_console_node_path(@node.id)
      end

      after_new
    end

    def create
      # set type first beacuse of @node.additional_params
      @node = Node.new(type: params[:node][:type])
      @node.update(node_params)
      if @node.new_record?
        respond_with @node, location: new_console_node_path
      else
        respond_with @node, location: edit_console_node_path(@node.id)
      end
    end

    def update
      @node.update(node_params)
      respond_with @node, location: edit_console_node_path(@node.id)
    end

    def destroy
      @node.destroy
      respond_with @node, location: console_nodes_path
    end

  private

    def self.index_children_limit
      5
    end

    def after_new
    end

    def find_node
      @node = Node.friendly.find(params[:id])
    end

    def find_files
      @images = Image.all.page(1).per(11)
      @documents = Document.all.page(1).per(11)
    end

    def filter_params
      params.permit(:by_query, :by_published, :by_type, :by_tag)
    end

    def node_params
      p = params.require(:node)
                .permit(:title,
                        :slug,
                        :perex,
                        :content,
                        :meta_title,
                        :meta_description,
                        :code,
                        :tag_list,
                        :type,
                        :featured,
                        :published,
                        :published_at,
                        :locale,
                        :parent_id,
                        :original_id,
                        *traco_params,
                        *additional_strong_params(@node),
                        *atoms_strong_params,
                        *file_placements_strong_params,
                        *cover_placement_strong_params)
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
      %i[by_parent by_query by_published by_type by_tag].any? { |by| params[by].present? }
    end

    def index_filters
      {
        by_parent: [
          [t('.filters.all_parents'), nil],
        ] + Node.original.roots.map { |n| [n.title, n.id] },
        by_published: [
          [t('.filters.all_nodes'), nil],
          [t('.filters.published'), 'published'],
          [t('.filters.unpublished'), 'unpublished'],
        ],
        by_type: [
          [t('.filters.all_types'), nil],
          [t('.filters.page'), 'page'],
          [t('.filters.category'), 'category'],
        ],
      }
    end

    helper_method :index_filters
  end
end
