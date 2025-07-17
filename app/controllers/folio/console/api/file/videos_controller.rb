# frozen_string_literal: true

class Folio::Console::Api::File::VideosController < Folio::Console::Api::BaseController
  include Folio::Console::Api::FileControllerBase

  folio_console_controller_for "Folio::File::Video"

  def subtitles_html
    respond_to do |format|
      format.json { render_component_json(Folio::Console::Files::SubtitlesFormComponent.new(file: @video)) }
    end
  end

  def retranscribe_subtitles
    @video.transcribe_subtitles!(force: true)

    respond_to do |format|
      format.json { render_component_json(Folio::Console::Files::SubtitlesFormComponent.new(file: @video)) }
    end
  end

  def create_subtitle
    update_or_create_subtitle
  end

  def update_subtitle
    update_or_create_subtitle
  end

  def subtitle_html
    language = params[:language]

    unless language.present? && @video.site.subtitle_languages.include?(language)
      render json: { error: "Invalid language parameter" }, status: :bad_request
      return
    end

    subtitle = @video.subtitle_for(language)

    if subtitle
      respond_to do |format|
        format.json { render_component_json(Folio::Console::Files::SubtitleFormComponent.new(file: @video, subtitle: subtitle)) }
      end
    else
      render json: { error: "Subtitle not found" }, status: :not_found
    end
  end

  def new_subtitle_html
    language = params[:language]

    unless language.present? && @video.site.subtitle_languages.include?(language)
      render json: { error: "Invalid language parameter" }, status: :bad_request
      return
    end

    # Don't create in the database, just render the component
    respond_to do |format|
      format.json { render_component_json(Folio::Console::Files::SubtitleFormComponent.new(file: @video, language: language, expanded: true)) }
    end
  end

  def delete_subtitle
    language = params[:language]

    # Validate language parameter
    unless language.present?
      render json: { error: "Invalid language parameter" }, status: :bad_request
      return
    end

    subtitle = @video.subtitle_for(language)

    if subtitle
      subtitle.destroy
      Rails.logger.info "[VideosController] Deleted subtitle for language: #{language}, video_file ID: #{@video.id}"
    end

    # Broadcast subtitle update to reload video iframe
    broadcast_subtitle_update

    respond_to do |format|
      format.json { render json: { success: true, message: "Subtitle deleted successfully" } }
    end
  end

  def update_subtitles
    # Legacy support for bulk subtitle updates using the old parameter format
    file_params = params.require(:file)

    # Process each language-specific parameter
    @video.site.subtitle_languages.each do |lang|
      text_key = "subtitles_#{lang}_text"
      enabled_key = "subtitles_#{lang}_enabled"

      next unless file_params.key?(text_key) || file_params.key?(enabled_key)

      subtitle = @video.subtitle_for!(lang)

      # Update text if provided
      if file_params[text_key].present?
        subtitle.text = file_params[text_key]
        subtitle.mark_manual_edit!
      end

      # Update enabled status if provided
      if file_params.key?(enabled_key)
        enabled = ["1", "true", true].include?(file_params[enabled_key])
        subtitle.enabled = enabled
        subtitle.user_action = :enable if enabled
      end

      # Use shared validation service for consistent validation handling
      enable_if_valid = subtitle.user_action == :enable
      Folio::SubtitleValidationService.validate_and_update_metadata(subtitle, enable_if_valid: enable_if_valid)

      # Clear user_action since validation service handled the enabling logic
      subtitle.user_action = nil if subtitle.user_action == :enable
      subtitle.save!(validate: false) # Skip Rails validations since we handled them manually
    end

    # Broadcast subtitle update to reload video iframe
    broadcast_subtitle_update

    respond_to do |format|
      format.json { render_component_json(Folio::Console::Files::SubtitlesFormComponent.new(file: @video)) }
    end
  end

  private
    def update_or_create_subtitle
      language = params[:language]

      # Validate language parameter
      unless language.present? && @video.site.subtitle_languages.include?(language)
        render json: { error: "Invalid language parameter" }, status: :bad_request
        return
      end

      subtitle = @video.subtitle_for!(language)

      # Track manual edits only if text content changes
      if subtitle_params[:text].present? && subtitle_params[:text] != subtitle.text
        subtitle.mark_manual_edit!
      end

      # Set user_action for validation if enabling
      subtitle.user_action = :enable if subtitle_params[:enabled] == true || subtitle_params[:enabled] == "1"

      # Update subtitle attributes
      subtitle.assign_attributes(subtitle_params)

      # Use shared validation service for consistent validation handling
      enable_if_valid = subtitle.user_action == :enable
      Folio::SubtitleValidationService.validate_and_update_metadata(subtitle, enable_if_valid: enable_if_valid)

      # Clear user_action since validation service handled the enabling logic
      subtitle.user_action = nil if subtitle.user_action == :enable

      # Save without validation since we've already handled it manually
      subtitle.save(validate: false)

      # Broadcast subtitle update to reload video iframe
      broadcast_subtitle_update

      respond_to do |format|
        format.json { render_component_json(Folio::Console::Files::SubtitleFormComponent.new(file: @video, subtitle: subtitle)) }
      end
    end

    def subtitle_params
      params.require(:subtitle).permit(:text, :enabled, :format)
    end

    def broadcast_subtitle_update
      # In test environment, always broadcast for testing purposes
      # In production, ensure we have a current user to broadcast to
      user_ids = if Rails.env.test?
        [current_user&.id].compact
      else
        message_bus_user_ids
      end

      return unless user_ids.any?

      # Send broadcast message for subtitle updates
      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::Console::Api::File::VideosController/subtitle_updated",
                           data: { id: @video.id },
                         }.to_json,
                         user_ids: user_ids
    end

    def message_bus_user_ids
      @message_bus_user_ids ||= Folio::User.where.not(console_url: nil)
                                           .where(console_url_updated_at: 1.hour.ago..)
                                           .pluck(:id)
    end
end
