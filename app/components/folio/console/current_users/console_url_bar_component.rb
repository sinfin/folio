# frozen_string_literal: true

class Folio::Console::CurrentUsers::ConsoleUrlBarComponent < Folio::Console::ApplicationComponent
  def initialize(show:, record: nil)
    @show = show
    @record = record
  end

  def render?
    @show && can_now?(:access_console) && (other_user_at_url || outdated_revision.present?)
  end

  private
    def other_user_at_url
      return false unless can_now?(:access_console)
      return @other_user_at_url unless @other_user_at_url.nil?
      @other_user_at_url = Folio::User.currently_editing_url(request.url).where.not(id: Folio::Current.user.id).first || false
    end

    def has_tiptap_with_autosave?
      return false if @record.blank?

      @record.class.try(:has_folio_tiptap?) && @record.tiptap_autosave_enabled?
    end

    def other_user_has_revision?
      return false unless has_tiptap_with_autosave?
      return false unless other_user_at_url

      @record.has_tiptap_revision?(user: other_user_at_url)
    end

    def outdated_revision
      return nil if @record.blank?
      return nil unless has_tiptap_with_autosave?

      revision = @record.latest_tiptap_revision(user: Folio::Current.user)

      if revision.present? && revision.superseded?
        return revision
      end

      nil
    end

    def name
      if other_user_at_url
        other_user_at_url.to_label
      end
    end

    def title
      if outdated_revision.present?
        t(".autosave.outdated_title", edited_by: outdated_revision.superseded_by_user.to_label,
                                      edited_at: l(@record.updated_at, format: :short))
      elsif other_user_has_revision?
        t(".autosave.title", edited_by: name,
                             edited_at: l(other_user_at_url.console_url_updated_at, format: :short))
      else
        "#{t('.title')} #{content_tag(:span, name, class: 'f-c-current-users-console-url-bar__middle--name')}".html_safe
      end
    end

    def middle_text
      if outdated_revision.present?
        t(".autosave.outdated_text")
      elsif other_user_has_revision?
        t(".autosave.text")
      else
        t(".text")
      end
    end

    def buttons
      if outdated_revision.present?
        [
          {
            variant: :primary,
            label: t(".autosave.outdated_continue"),
            data: stimulus_action(click: "onOutdatedContinueButtonClick")
          }
        ]
      elsif other_user_has_revision?
        [
          {
            variant: :primary,
            label: t(".autosave.takeover"),
            data: stimulus_action(click: "onTakeoverButtonClick")
          },
          {
            variant: :tertiary,
            label: t(".autosave.back"),
            href: url_for([:console, @record.class])
          }
        ]
      else
        nil
      end
    end

    def data
      stimulus_controller("f-c-current-users-console-url-bar",
                          values: {
                            api_url: controller.console_url_ping_console_api_current_user_url(format: :json),
                            takeover_api_url: controller.takeover_revision_console_api_tiptap_revisions_path,
                            delete_revision_url: controller.delete_revision_console_api_tiptap_revisions_path,
                            from_user_id: other_user_at_url.present? ? other_user_at_url.id : nil,
                            record_id: @record&.id,
                            record_type: @record&.class&.name
                          })
    end
end
