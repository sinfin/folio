# frozen_string_literal: true

class Folio::File < Folio::ApplicationRecord
  include Folio::Filterable
  include Folio::HasHashId
  include Folio::MimeTypeDetection
  include Folio::SanitizeFilename
  include Folio::Taggable

  dragonfly_accessor :file do
    after_assign :sanitize_filename
  end

  # Relations
  has_many :file_placements, class_name: 'Folio::FilePlacement::Base'
  has_many :placements, through: :file_placements

  # Validations
  validates :file, :type,
            presence: true

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_placement, -> (placement_title) { order(created_at: :desc) }
  scope :by_used, -> (used) do
    if used == 'used'
      joins(:file_placements)
    elsif used == 'unused'
      left_joins(:file_placements).where(folio_file_placements: { id: nil })
    else
      all
    end
  end
  scope :by_tags, -> (tags) do
    if tags.is_a?(String)
      tagged_with(tags.split(','))
    else
      tagged_with(tags)
    end
  end

  pg_search_scope :by_file_name,
                  against: [:file_name],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  pg_search_scope :by_placement,
                  associated_against: {
                    file_placements: [:placement_title],
                  },
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  pg_search_scope :by_author,
                  against: [:author],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  before_save :set_mime_type
  before_destroy :check_usage_before_destroy
  after_save :touch_placements

  def title
    file_name
  end

  def file_extension
    if /msword/.match?(mime_type)
      /docx/.match?(file_name) ? :docx : :doc
    else
      Mime::Type.lookup(mime_type).symbol
    end
  end

  def to_h
    {
      thumb: is_a?(Folio::Image) ? thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE).url : nil,
      file_size: file_size,
      file_name: file_name,
      type: type,
      id: id,
    }
  end

  def update_file_placements_size!
    update_columns(file_placements_size: file_placements.count,
                   updated_at: current_time_from_proper_timezone)
  end

  def self.hash_id_additional_classes
    [Folio::PrivateAttachment]
  end

  def self.react_type
    'document'
  end

  private
    def touch_placements
      file_placements.each(&:touch)
    end

    def set_mime_type
      return unless file.present?
      return unless respond_to?(:mime_type)
      self.mime_type = get_mime_type(file)
    end

    def check_usage_before_destroy
      throw(:abort) if file_placements.exists?
    end
end

# == Schema Information
#
# Table name: folio_files
#
#  id                   :bigint(8)        not null, primary key
#  file_uid             :string
#  file_name            :string
#  type                 :string
#  thumbnail_sizes      :text             default("--- {}\n")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  file_width           :integer
#  file_height          :integer
#  file_size            :bigint(8)
#  mime_type            :string(255)
#  additional_data      :json
#  file_metadata        :json
#  hash_id              :string
#  author               :string
#  description          :text
#  file_placements_size :integer
#
# Indexes
#
#  index_folio_files_on_by_file_name  (to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name)::text, ''::text)))) USING gin
#  index_folio_files_on_created_at    (created_at)
#  index_folio_files_on_file_name     (file_name)
#  index_folio_files_on_hash_id       (hash_id)
#  index_folio_files_on_type          (type)
#  index_folio_files_on_updated_at    (updated_at)
#
