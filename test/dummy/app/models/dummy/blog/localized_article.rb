# frozen_string_literal: true

class Dummy::Blog::LocalizedArticle < ApplicationRecord
  include Folio::BelongsToSite
  const_set(:FRIENDLY_ID_SCOPE, :site_id)
  include Folio::FriendlyIdForTraco
end
