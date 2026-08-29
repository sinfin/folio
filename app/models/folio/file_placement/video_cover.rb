# frozen_string_literal: true

class Folio::FilePlacement::VideoCover < Folio::FilePlacement::Base
  folio_file_placement "Folio::File::Video",
                       :video_cover_placement,
                       has_many: false
end
