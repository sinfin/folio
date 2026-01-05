# frozen_string_literal: true

class Folio::Console::Api::TiptapRevisionsController < Folio::Console::Api::BaseController
  def save_revision
    placement = find_placement
    authorize!(:update, placement)
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

  def delete_revision
    placement = find_placement
    authorize!(:update, placement)
    user = Folio::Current.user

    revision = placement.tiptap_revisions.find_by(user: user)
    if revision
      revision.destroy!
      render json: { success: true }
    else
      render json: { success: false }, status: :not_found
    end
  end

  def takeover_revision
    from_user = Folio::User.find(params[:from_user_id])
    record_class = params[:record_type].constantize
    record = record_class.find(params[:record_id])
    authorize!(:update, record)

    from_revision = record.tiptap_revisions.find_by(user: from_user)
    return render json: {
      error: t(".no_revision_found", user_id: from_user.id, record_id: record.id, record_type: record.class.name)
    }, status: :not_found unless from_revision

    to_revision = record.tiptap_revisions.find_or_initialize_by(user: Folio::Current.user)
    to_revision.content = from_revision.content
    to_revision.save!

    from_user.update_console_url!(nil)

    render json: { success: true }
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
