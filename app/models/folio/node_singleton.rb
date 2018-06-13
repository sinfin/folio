# frozen_string_literal: true

module Folio
  class NodeSingleton < Node
    validate :validate_singularity

    class MissingError < StandardError; end

    def self.instance
      first.presence || fail(MissingError, self.class.to_s)
    end

    def self.console_selectable?
      to_s != 'Folio::NodeSingleton' && !exists?
    end

    private

      def validate_singularity
        if new_record?
          errors.add(:type, :invalid) if self.class.exists?
        else
          errors.add(:type, :invalid) if self.class.where.not(id: id).exists?
        end
      end
  end
end

# == Schema Information
#
# Table name: folio_nodes
#
#  id               :integer          not null, primary key
#  site_id          :integer
#  title            :string
#  slug             :string
#  perex            :text
#  content          :text
#  meta_title       :string(512)
#  meta_description :string(1024)
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
#  index_folio_nodes_on_site_id       (site_id)
#  index_folio_nodes_on_slug          (slug)
#  index_folio_nodes_on_type          (type)
#
