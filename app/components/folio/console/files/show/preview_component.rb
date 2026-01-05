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
      return tmp_aws_file_handler_url

      @file_url ||= Folio::S3.url_rewrite(@file.file.remote_url)
    end

    def tmp_aws_file_handler_url
      if @file && @file.id
        "https://doader.s3.amazonaws.com/1000x1000.gif?aws-file-handler=1&id=#{@file.id}"
      else
        "https://doader.s3.amazonaws.com/1000x1000.gif?aws-file-handler=1"
      end
    end
end
