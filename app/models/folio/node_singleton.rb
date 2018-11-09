# frozen_string_literal: true

module Folio
  class NodeSingleton < Node
    include ::Folio::Singleton
  end
end

# == Schema Information
#
# Table name: folio_nodes
#
#  id               :bigint(8)        not null, primary key
#  title            :string
#  slug             :string
#  perex            :text
#  content          :text
#  meta_title       :string(512)
#  meta_description :text
#  code             :string
#  ancestry         :string
#  type             :string
#  featured         :boolean
#  position         :integer
#  published        :boolean
#  published_at     :datetime
#  original_id      :integer
#  locale           :string(6)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_folio_nodes_on_ancestry      (ancestry)
#  index_folio_nodes_on_code          (code)
#  index_folio_nodes_on_featured      (featured)
#  index_folio_nodes_on_locale        (locale)
#  index_folio_nodes_on_original_id   (original_id)
#  index_folio_nodes_on_position      (position)
#  index_folio_nodes_on_published     (published)
#  index_folio_nodes_on_published_at  (published_at)
#  index_folio_nodes_on_slug          (slug)
#  index_folio_nodes_on_type          (type)
#
