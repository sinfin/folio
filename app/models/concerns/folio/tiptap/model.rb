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
    before_validation :update_tiptap_file_placements
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

  def update_tiptap_file_placements
    new_file_placements = []

    self.class.folio_tiptap_fields.each do |field|
      value = send(field)
      next if value.blank?

      content = value[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]]
      next if content.blank?

      Folio::Tiptap::Node.instances_from_tiptap_content(content).each do |instance|
        instance.class.structure.each do |key, config|
          next if config[:type] != :folio_attachment

          if config[:has_many]
            instance.send("#{key.to_s.singularize}_placements").each do |file_placement|
              new_file_placements << file_placement if file_placement
            end
          else
            file_placement = instance.send("#{key}_placement")
            new_file_placements << file_placement if file_placement
          end
        end
      end
    end

    # check existing tiptap_placements and map by file_id, remove unused, add new
    persisted_tiptap_placements_ary = tiptap_placements.to_a.select(&:persisted?)
    new_attributes = []

    new_file_placements.each do |new_file_placement|
      persisted_placement = persisted_tiptap_placements_ary.find do |pp|
        new_attributes.none? { |attrs| attrs[:id] == pp.id } &&
        pp.file_id == new_file_placement.file_id
      end

      new_attributes << {
        id: persisted_placement.try(:id),
        file_id: new_file_placement.file_id,
        title: new_file_placement.title,
        alt: new_file_placement.alt,
      }
    end

    persisted_tiptap_placements_ary.each do |persisted_placement|
      if new_attributes.none? { |attrs| attrs[:id] == persisted_placement.id }
        new_attributes << { id: persisted_placement.id, _destroy: true }
      end
    end

    self.tiptap_placements_attributes = new_attributes
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

      folio_tiptap_pages_count = count_folio_tiptap_pages_nodes(value[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]])
      if folio_tiptap_pages_count > 1
        errors.add(field, :tiptap_multiple_folio_tiptap_pages, count: folio_tiptap_pages_count)
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

  def folio_html_sanitization_config
    config = if respond_to?(:folio_html_sanitize)
      super
    else
      Folio::HtmlSanitization::Model::DEFAULT_CONFIG.deep_dup
    end

    self.class.folio_tiptap_fields.each do |field|
      config[:attributes][field.to_sym] = :tiptap_content
    end

    config
  end

  def latest_tiptap_revision(user: nil)
    return nil unless tiptap_autosave_enabled?

    revs = tiptap_revisions.order(updated_at: :asc)
    revs = revs.where(user: user) if user.present?
    revs.last
  end

  def has_tiptap_revision?(user: nil)
    return false unless tiptap_autosave_enabled?

    revs = tiptap_revisions
    revs = revs.where(user: user) if user.present?
    revs.exists?
  end

  private
    def count_folio_tiptap_pages_nodes(node)
      return 0 unless node.is_a?(Hash)

      count = 0
      count += 1 if node["type"] == "folioTiptapPages"

      if node["content"].is_a?(Array)
        node["content"].each do |child_node|
          count += count_folio_tiptap_pages_nodes(child_node)
        end
      end

      count
    end

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
