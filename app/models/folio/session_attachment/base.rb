# frozen_string_literal: true

class Folio::SessionAttachment::Base < Folio::ApplicationRecord
  include Folio::HasHashId
  include Folio::RecursiveSubclasses
  include Folio::SanitizeFilename
  include Folio::StiPreload

  STALE_PERIOD = 1.day

  self.table_name = "folio_session_attachments"

  dragonfly_accessor :file do
    after_assign :sanitize_filename

    storage_options do |attachment|
      {
        headers: { "x-amz-acl" => "private" },
        path: "session_attachments/#{hash_id}/#{sanitize_filename}",
      }
    end
  end

  scope :ordered, -> { order(id: :desc) }
  scope :unpaired, -> { where(placement: nil) }

  validate :validate_type

  validates :web_session_id, :file,
            presence: true

  belongs_to :visit, optional: true
  belongs_to :user, optional: true
  belongs_to :placement, polymorphic: true,
                         optional: true,
                         inverse_of: :session_attachments,
                         touch: true

  before_save :set_file_mime_type

  alias_attribute :mime_type, :file_mime_type

  def to_h
    {
      id: hash_id,
      file_name: file_name,
      file_size: file_size,
      file_mime_type: file_mime_type,
      thumb: thumb,
    }
  end

  def file_extension
    if /msword/.match?(file_mime_type)
      /docx/.match?(file_name) ? :docx : :doc
    else
      Mime::Type.lookup(file_mime_type).symbol
    end
  end

  def thumb
  end

  def self.hash_id_length
    16
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
    def set_file_mime_type
      return unless will_save_change_to_file_uid?
      return unless file.present?
      self.file_mime_type = file.mime_type
    end

    def validate_type
      return errors.add(:type, :blank) if type.blank?
      return errors.add(:type, :invalid) if type.start_with?("Folio::")
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
#  thumbnail_sizes :jsonb
#  visit_id        :bigint(8)
#  placement_type  :string
#  placement_id    :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_folio_session_attachments_on_hash_id         (hash_id)
#  index_folio_session_attachments_on_placement       (placement_type,placement_id)
#  index_folio_session_attachments_on_type            (type)
#  index_folio_session_attachments_on_visit_id        (visit_id)
#  index_folio_session_attachments_on_web_session_id  (web_session_id)
#
