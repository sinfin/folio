# frozen_string_literal: true

class Folio::Console::Api::TiptapRevisionsController < Folio::Console::Api::BaseController
  def create
    placement = find_placement
    revision = placement.create_tiptap_revision!(
      content: revision_params[:content],
      user: Folio::Current.user
    )

    render json: {
      success: true,
      revision_id: revision.id,
      revision_number: revision.revision_number,
      created_at: revision.created_at
    }
  end

  private
    def revision_params
      params.require(:tiptap_revision).permit(content: {})
    end

    def placement_params
      params.require(:placement).permit(:type, :id)
    end

    def find_placement
      placement_class = placement_params[:type].constantize
      placement_class.find(placement_params[:id])
    end
end
