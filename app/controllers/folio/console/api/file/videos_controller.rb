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
    
    respond_to do |format|
      format.json { render_component_json(Folio::Console::Files::SubtitlesFormComponent.new(file: @video)) }
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
        enabled = ['1', 'true', true].include?(file_params[enabled_key])
        subtitle.enabled = enabled
        subtitle.user_action = :enable if enabled
      end
      
      subtitle.save!
    end
    
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
    
    # Track manual edits
    subtitle.mark_manual_edit!
    
    # Set user_action for validation if enabling
    subtitle.user_action = :enable if subtitle_params[:enabled] == true || subtitle_params[:enabled] == '1'
    
    # Update subtitle attributes
    subtitle.assign_attributes(subtitle_params)
    
    # If we're trying to enable, validate the content and store errors
    if subtitle.user_action == :enable
      subtitle.validate_content = true
      if subtitle.valid?
        subtitle.update_validation_metadata(true, [])
      else
        subtitle.update_validation_metadata(false, subtitle.errors.full_messages)
        # Keep the subtitle disabled if validation fails
        subtitle.enabled = false
      end
      subtitle.validate_content = false
    end
    
    # Save without validation since we've already handled it
    subtitle.save(validate: false)
    
    respond_to do |format|
      format.json { render_component_json(Folio::Console::Files::SubtitlesFormComponent.new(file: @video)) }
    end
  end

  def subtitle_params
    params.require(:subtitle).permit(:text, :enabled, :format)
  end
end
