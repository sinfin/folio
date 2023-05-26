# frozen_string_literal: true

module Folio::FriendlyId::History
  extend ActiveSupport::Concern

  included do
    extend FriendlyId

    before_save :remove_conflicting_history_slugs
  end

  private
    def remove_conflicting_history_slugs
      if slug.present?
        scope_names = if self.class.friendly_id_config.uses?(:scoped)
          self.class.friendly_id_config.scope_columns.sort.map { |column| "#{column}:#{send(column)}" }.join(",")
        else
          nil
        end

        existing_scope = FriendlyId::Slug.where(sluggable_type: self.class.base_class.to_s,
                                                slug:,
                                                scope: scope_names)
                                         .where.not(sluggable_id: id)

        existing_scope.each do |slug|
          last_slug_for_record = FriendlyId::Slug.where(sluggable_type: slug.sluggable_type,
                                                        sluggable_id: slug.sluggable_id,
                                                        scope: slug.scope)
                                                 .order(id: :asc)
                                                 .last

          slug.destroy if slug.id != last_slug_for_record.id
        end
      end
    end
end
