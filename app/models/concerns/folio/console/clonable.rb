# frozen_string_literal: true

module Folio::Console::Clonable
  extend ActiveSupport::Concern

  DEFAULT_RESET_ATTRIBUTES = [:published_at, :published]

  included do
    def after_clone
    end
  end

  class_methods do
    def is_clonable?
      true
    end

    def ignored_associations
      []
    end

    def referenced_associations
      []
    end

    def reset_attributes
      []
    end

    def generate_cloned_title(original_title)
      I18n.t("folio.console.clone.cloned_title",
                             original_title:,
                             date: Date.today.strftime("%d. %m. %Y"))
    end

      private
        def validate_associations!(associations)
          associations.each do |assoc|
              unless reflect_on_association(assoc)
                raise ArgumentError, I18n.t("activerecord.errors.clonable.association_not_found",
                                          association: assoc,
                                          model: self.name)
              end
            end
        end

        def validate_attributes!(attributes)
          attributes.each do |attr|
            unless column_names.include?(attr.to_s)
              raise ArgumentError, I18n.t("activerecord.errors.clonable.attribute_not_found",
                                        attribute: attr,
                                        model: self.name)
            end
          end
        end
  end
end
