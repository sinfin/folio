# frozen_string_literal: true

class Folio::SessionAttachment < Folio::ApplicationRecord
  include Folio::HasHashId
  include Folio::RecursiveSubclasses
  include Folio::SanitizeFilename
  include Folio::StiPreload
  include Folio::Aws::FileProcessable

  STALE_PERIOD = 1.day

  # Replace "file" with AWS logic
  # dragonfly_accessor :file do
  #   after_assign :sanitize_filename
  #
  #   storage_options do |attachment|
  #     {
  #       headers: { "x-amz-acl" => "private" },
  #       path: "session_attachments/#{hash_id}/#{sanitize_filename}",
  #     }
  #   end
  # end

  scope :ordered, -> { order(id: :desc) }
  scope :unpaired, -> { where(placement: nil) }

  validate :validate_type

  validates :web_session_id, :file,
            presence: true

  belongs_to :placement, polymorphic: true,
                         optional: true,
                         touch: true

  after_save :pregenerate_thumbnails

  def to_h
    {
      id: hash_id,
      file_name:,
      file_size:,
      file_mime_type:,
      thumb: to_h_thumb,
    }
  end

  def file_extension
    if file_mime_type.include?("msword")
      file_name.include?("docx") ? :docx : :doc
    else
      Mime::Type.lookup(file_mime_type).symbol
    end
  end

  def to_h_thumb
  end

  def thumbnail_store_options
    {
      path_base: "session_attachments/#{hash_id}",
      headers: { "x-amz-acl" => "private" },
      private: true,
    }
  end

  def self.hash_id_length
    16
  end

  def self.human_type
    "document"
  end

  def self.model_name
    @_model_name ||= begin
      base = ActiveModel::Name.new(Folio::SessionAttachment)
      ActiveModel::Name.new(self).tap do |name|
        %w(param_key singular_route_key route_key).each do |key|
          name.instance_variable_set("@#{key}", base.public_send(key))
        end
      end
    end
  end

  def self.sti_paths
    [
      Folio::Engine.root.join("app/models/folio/session_attachment"),
      Rails.root.join("app/models/**/session_attachment"),
    ]
  end

  def self.valid_types
    recursive_subclasses.reject { |k| k.to_s.start_with?("Folio::") }
  end

  def self.clear_unpaired!
    unpaired.where("created_at < ?", STALE_PERIOD.ago).destroy_all
  end

  private
    def validate_type
      return errors.add(:type, :blank) if type.blank?
      errors.add(:type, :invalid) if type.start_with?("Folio::")
    end

    def pregenerate_thumbnails
      return if Rails.env.test?
      return unless respond_to?(:admin_thumb)
      return unless respond_to?(:lightbox_thumb)

      admin_thumb
      lightbox_thumb
    end
end

# == Schema Information
#
# Table name: folio_session_attachments
#
#  id              :bigint(8)        not null, primary key
#  hash_id         :string
#  file_uid        :string
#  file_name       :string
#  file_size       :bigint(8)
#  file_mime_type  :string
#  type            :string
#  web_session_id  :string
#  placement_type  :string
#  placement_id    :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  thumbnail_sizes :json
#
# Indexes
#
#  index_folio_session_attachments_on_hash_id         (hash_id)
#  index_folio_session_attachments_on_placement       (placement_type,placement_id)
#  index_folio_session_attachments_on_type            (type)
#  index_folio_session_attachments_on_web_session_id  (web_session_id)
#
