# frozen_string_literal: true

class Folio::Api::File::VideosController < Folio::Api::BaseController
  before_action :find_video

  def subtitles
    vtt_content = vtt_subtitles_for(@video, params[:lang])

    render plain: vtt_content, content_type: "text/vtt"
  end

  private
    def find_video
      @video = Folio::File::Video.find(params[:id])
    end

    def vtt_subtitles_for(video, lang)
      subs = video.subtitles[lang]
      raise ActiveRecord::RecordNotFound unless subs
      "WEBVTT\n\n" + subs
    end
end
