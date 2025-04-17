# frozen_string_literal: true

namespace :folio do
  namespace :session_attachments do
    task clear_unpaired: :environment do
      Folio::SessionAttachment.clear_unpaired!
    end
  end
end
