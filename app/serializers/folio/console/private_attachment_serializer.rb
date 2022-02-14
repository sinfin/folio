# frozen_string_literal: true

class Folio::Console::PrivateAttachmentSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :file_size,
             :file_name,
             :type
end
