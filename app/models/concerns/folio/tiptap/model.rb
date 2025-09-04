# frozen_string_literal: true

module Folio::Tiptap::Model
  extend ActiveSupport::Concern

  class_methods do
    def has_folio_tiptap_content(field = :tiptap_content)
      define_method("#{field}=") do |value|
        ftc = Folio::Tiptap::Content.new(record: self)
        result = ftc.convert_and_sanitize_value(value)

        if result[:ok]
          super(result[:value])
        end
      end
    end

    def has_folio_tiptap?
      folio_tiptap_fields.present?
    end

    def folio_tiptap_fields
      %w[tiptap_content]
    end
  end

  included do
    has_many :tiptap_revisions, as: :placement, class_name: "Folio::Tiptap::Revision", dependent: :destroy
    before_validation :convert_titap_fields_to_hashes_and_sanitize
    validate :validate_tiptap_fields
    after_save :cleanup_tiptap_revisions, if: :tiptap_autosave_enabled?
  end

  def convert_titap_fields_to_hashes_and_sanitize
    self.class.folio_tiptap_fields.each do |field|
      value = send(field)

      if value.is_a?(String) && value.present?
        begin
          parsed_value = JSON.parse(value)
          send("#{field}=", parsed_value)
        rescue JSON::ParserError
          errors.add(field, :tiptap_invalid_json)
        end
      end

      if value.is_a?(Hash) && value[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]].blank?
        send("#{field}=", nil)
      end
    end
  end

  def validate_tiptap_fields
    self.class.folio_tiptap_fields.each do |field|
      value = send(field)
      next if value.blank?

      unless value.is_a?(Hash)
        errors.add(field, :tiptap_must_be_hash_or_json)
        next
      end

      unless value[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]].is_a?(Hash)
        errors.add(field, :tiptap_must_have_content_key, content_key: Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content])
        next
      end

      if value[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]]["type"] != "doc"
        errors.add(field, :tiptap_root_node_must_be_doc)
        next
      end
    end
  end

  def tiptap_config
    Folio::Tiptap.config
  end

  def tiptap_autosave_enabled?
    tiptap_config&.autosave == true
  end

  def latest_tiptap_revision(user: nil)
    return nil unless tiptap_autosave_enabled?

    target_user = user || Folio::Current.user
    return nil unless target_user

    tiptap_revisions.find_by(user: target_user)
  end

  def has_tiptap_revision?(user: nil)
    return false unless tiptap_autosave_enabled?

    target_user = user || Folio::Current.user
    return false unless target_user

    tiptap_revisions.exists?(user: target_user)
  end

  private
    def cleanup_tiptap_revisions
      # After saving the main model:
      # 1. Mark all other users' revisions as superseded by current user
      # 2. Delete current user's revision (since content is now in main model)
      return unless Folio::Current.user

      superseded_count = tiptap_revisions.where.not(user_id: Folio::Current.user.id)
                                         .update_all(superseded_by_user_id: Folio::Current.user.id)

      current_user_revision = tiptap_revisions.find_by(user: Folio::Current.user)
      if current_user_revision
        current_user_revision.destroy
        Rails.logger.info "Deleted tiptap revision for user #{Folio::Current.user.id} after saving #{self.class.name}##{id}"
      end

      if superseded_count > 0
        Rails.logger.info "Marked #{superseded_count} tiptap revisions as superseded by user #{Folio::Current.user.id} after saving #{self.class.name}##{id}"
      end
    end
end
