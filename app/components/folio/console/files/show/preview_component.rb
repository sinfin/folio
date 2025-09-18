# frozen_string_literal: true

class Folio::Console::Files::Show::PreviewComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
    @human_type = file.class.human_type
  end

  def self.should_render?(human_type)
    human_type.in?(%w[image video audio])
  end

  private
    def render?
      self.class.should_render?(@human_type)
    end

    def file_url
      @file_url ||= Folio::S3.url_rewrite(@file.file.remote_url)
    end
end
