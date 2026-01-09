# frozen_string_literal: true

class Folio::Console::Api::TiptapRevisionsController < Folio::Console::Api::BaseController
  def save_revision
    placement = find_placement
    authorize!(:update, placement)
    user = Folio::Current.user
    attribute_name = revision_params[:attribute_name] || "tiptap_content"

    revision = placement.tiptap_revisions.find_or_initialize_by(user: user, attribute_name: attribute_name)
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
    attribute_name = placement_params[:attribute_name] || "tiptap_content"

    revision = placement.tiptap_revisions.find_by(user: user, attribute_name: attribute_name)
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

    # Takeover all revisions from the other user (for all attribute_names)
    from_revisions = record.tiptap_revisions.where(user: from_user)
    return render json: {
      error: t(".no_revision_found", user_id: from_user.id, record_id: record.id, record_type: record.class.name)
    }, status: :not_found if from_revisions.empty?

    from_revisions.each do |from_revision|
      to_revision = record.tiptap_revisions.find_or_initialize_by(
        user: Folio::Current.user,
        attribute_name: from_revision.attribute_name
      )
      to_revision.content = from_revision.content
      to_revision.save!
    end

    from_user.update_console_url!(nil)

    render json: { success: true }
  end

  private
    def revision_params
      params.require(:tiptap_revision).permit(:attribute_name, content: {})
    end

    def placement_params
      params.require(:placement).permit(:type, :id, :attribute_name)
    end

    def find_placement
      placement_class = placement_params[:type].constantize
      placement_class.find(placement_params[:id])
    end
end
