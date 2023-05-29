# frozen_string_literal: true

class Folio::Console::Api::JwPlayerController < Folio::Console::Api::BaseController
  def video_url
    file = Folio::File.find(params.require(:file_id))

    if file.try(:processing_service) == "jw_player" && file.remote_key
      response = HTTParty.get(file.remote_signed_full_url)

      if response && response["playlist"].present?
        attributes = { file_name: response["title"] }
        source_size = nil

        response["playlist"][0]["sources"].each do |source|
          if source_size.nil? || source_size < source["filesize"]
            source_size = source["filesize"]
            attributes[:source_url] = source["file"]
            attributes[:file_width] = source["width"]
            attributes[:file_height] = source["height"]
          end
        end

        if attributes[:source_url]
          return render json: { data: { attributes: } }
        end
      end
    end

    render json: {}, status: 404
  end
end
