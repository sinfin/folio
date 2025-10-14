# frozen_string_literal: true

class Folio::MediaSource < Folio::ApplicationRecord
  include Folio::BelongsToSite

  has_many :media_source_site_links, class_name: "Folio::MediaSourceSiteLink", dependent: :destroy
  has_many :allowed_sites, through: :media_source_site_links, source: :site, class_name: "Folio::Site"
  has_many :files, class_name: "Folio::File", foreign_key: :media_source_id

  accepts_nested_attributes_for :media_source_site_links, allow_destroy: true

  validates :title, presence: true, uniqueness: true
  validates :max_usage_count, numericality: { greater_than: 0, allow_nil: true }

  before_destroy :nullify_attached_files_attributes, prepend: true
  after_commit :broadcast_files_reload, on: :destroy

  scope :ordered, -> { order(id: :desc) }

  scope :by_allowed_site_slug, -> (slug) do
    joins(:allowed_sites).where(folio_sites: { slug: })
  end

  def self.with_assigned_media_counts
    left_joins(:files)
      .group(:id)
      .select("folio_media_sources.*, COUNT(folio_files.id) as assigned_media_count")
  end

  def assigned_media_count
    # If eager loaded from with_assigned_media_counts, use that value
    if has_attribute?(:assigned_media_count) && attributes["assigned_media_count"].present?
      attributes["assigned_media_count"].to_i
    else
      @assigned_media_count ||= Folio::File.where(media_source_id: id).count
    end
  end

  def indestructible_reason
    return nil unless assigned_media_count.positive?
    I18n.t("folio.media_source.cannot_destroy_with_assigned_media", count: assigned_media_count)
  end

  private
    def nullify_attached_files_attributes
      ids = files.ids
      @nullified_file_ids = ids
      return true if ids.blank?

      scope = Folio::File.where(id: ids)

      Folio::FileSiteLink
        .where(file_id: ids)
        .where("site_id = ? OR site_id IN (SELECT site_id FROM folio_media_source_site_links WHERE media_source_id = ?)",
               site_id, id)
        .delete_all
      scope.update_all(media_source_id: nil)
      clear_field_if_equal(scope, :attribution_source, title)
      clear_field_if_equal(scope, :attribution_max_usage_count, max_usage_count)
      clear_field_if_equal(scope, :attribution_licence, licence)
      clear_field_if_equal(scope, :attribution_copyright, copyright_text)

      true
    end

    # Nullifies `column` for all records in scope where the current value equals `value`.
    def clear_field_if_equal(scope, column, value)
      return if value.blank?

      scope.where(column => value).update_all(column => nil)
    end

    def broadcast_files_reload
      return unless @nullified_file_ids.present?
      return unless defined?(MessageBus) && Folio::Current.user

      @nullified_file_ids.each do |fid|
        MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                           { type: "f-c-files-show:reload", data: { id: fid } }.to_json,
                           user_ids: [Folio::Current.user.id]
      end
    ensure
      @nullified_file_ids = nil
    end
end

# == Schema Information
#
# Table name: folio_media_sources
#
#  id              :bigint(8)        not null, primary key
#  title           :string           not null
#  licence         :string
#  copyright_text  :string
#  max_usage_count :integer          default(1)
#  site_id         :bigint(8)        not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_folio_media_sources_on_site_id  (site_id)
#  index_folio_media_sources_on_title    (title) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#
