# frozen_string_literal: true

class Dummy::Blog::LocalizedPage < ApplicationRecord
  include Folio::BelongsToSite
  const_set(:FRIENDLY_ID_SCOPE, :site_id)
  include Folio::FriendlyIdForTraco
end

# == Schema Information
#
# Table name: dummy_blog_localized_pages
#
#  id         :integer          not null, primary key
#  title      :string
#  title_cs   :string
#  title_en   :string
#  slug       :string
#  slug_cs    :string
#  slug_en    :string
#  locale     :string
#  site_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
