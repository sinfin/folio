# frozen_string_literal: true

module Folio
  class Console::NodesController < Console::BaseController
    include Console::NodesHelper

    respond_to :json, only: %i[update set_position]

    before_action :find_node, except: [:index, :create, :new, :set_positions]
    before_action :find_files, only: [:new, :edit, :create, :update]
    add_breadcrumb Node.model_name.human(count: 2), :console_nodes_path

    def index
      if misc_filtering?
        if params[:by_parent].present?
          parent = Node.find(params[:by_parent])
          @nodes = parent.subtree.original
                         .filter(filter_params)
                         .arrange(order: 'position desc, created_at desc')
        else
          @nodes = Node.original
                       .ordered.filter(filter_params)
                       .page(current_page)
        end
      else
        @limit = 5
        @nodes = Node.original.arrange(order: 'position desc, created_at desc')
      end
    end

    def new
      if params[:node].blank? || params[:node][:original_id].blank?
        parent = Node.find(params[:parent]) if params[:parent].present?
        @node = Node.new(parent: parent, type: params[:type])
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
      success = @node.update(node_params)
      respond_with @node, location: success ? edit_console_node_path : console_nodes_path
    end

    def update
      @node.update(node_params)
      respond_with @node, location: edit_console_node_path
    end

    def destroy
      @node.destroy
      respond_with @node, location: console_nodes_path
    end

    def set_position
      Node.update(set_position_params.keys, set_position_params.values)
      render json: { success: 'success', status_code: '200' }
    end

  private

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
                        *additional_strong_params(@node),
                        *atoms_strong_params,
                        *file_placements_strong_params)
      p[:slug] = nil unless p[:slug].present?
      p
    end

    def set_position_params
      params.require(:node)
    end

    def misc_filtering?
      %i[by_parent by_query by_published by_type by_tag].any? { |by| params[by].present? }
    end

    def index_filters
      {
        by_parent: [
          [t('.filters.all_parents'), nil],
        ] + Folio::Node.original.roots.map { |n| [n.title, n.id] },
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
