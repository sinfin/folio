# frozen_string_literal: true

class Folio::FilePlacement::AudioCover < Folio::FilePlacement::Base
  folio_file_placement("Folio::File::Audio",
                       :audio_cover_placement,
                       has_many: false)
end
