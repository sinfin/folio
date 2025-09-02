# frozen_string_literal: true

class Folio::Console::Api::TiptapRevisionsController < Folio::Console::Api::BaseController
  def save_revision
    placement = find_placement
    user = Folio::Current.user

    revision = placement.tiptap_revisions.find_or_initialize_by(user: user)
    revision.content = revision_params[:content]
    revision.save!

    render json: {
      success: true,
      revision_id: revision.id,
      created_at: revision.created_at,
      updated_at: revision.updated_at
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
