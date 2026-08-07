# frozen_string_literal: true

class Folio::Clonable::Cloner
  def initialize(record)
    @record = record
    fail "Not a clonable record" unless @record.class.is_clonable?
    validate_associations!(@record.class.clonable_ignored_associations)
    validate_associations!(@record.class.clonable_referenced_associations)
    validate_attributes!(@record.class.clonable_reset_attributes)
  end

  def create_clone
    log("CLONING", :info)
    log(I18n.t("clonable.cloner.start", model: self.class.name, id: @record.id))
    clone, duplicated = clone_nested_records_recursively(@record)
    log(I18n.t("clonable.cloner.associations_duplicated", associations: duplicated))
    reset_clone_attributes(clone)
    log(I18n.t("clonable.cloner.finished"))

    if clone.respond_to?(:title=)
      clone.title = generate_cloned_title(@record.title)
    end
    clone
  rescue => e
    log(I18n.t("clonable.cloner.error", message: e.message), :error)
    log(e.backtrace.first(5).join("\n"), :error)
    raise
  end

  private
    def clone_nested_records_recursively(original)
      duplicated = []
      cloned = original.deep_dup
      copy_references(original, cloned)
      original.class.reflect_on_all_associations.each do |association|
        log("#{original.class}#try to clone association: #{association.name}")

        next if skip_association?(original, association)

        if original.public_send(association.name).present?
          duplicated << association.name

          if association.macro == :has_many
            associated_record = original.public_send(association.name).map { |a| clone_nested_records_recursively(a).first }
          else
            associated_record = original.public_send(association.name).deep_dup
          end
          cloned.public_send("#{association.name}=", associated_record)
        end
      end
      [cloned, duplicated]
    end

    def skip_association?(original, association)
      return true if referenced_names(original).include?(association.name)
      return true if ignored_names(original).include?(association.name)

      base_class = association_base_class(association)
      return false if base_class.nil?
      return false unless ignored_base_classes(original).include?(base_class)

      log("#{original.class}#skipping association: #{association.name} - " \
          "#{base_class} is opted out via another association")

      true
    end

    def ignored_names(original)
      @record.class.clonable_ignored_associations +
        (original.class.try(:clonable_ignored_associations) || [])
    end

    def referenced_names(original)
      @record.class.clonable_referenced_associations +
        (original.class.try(:clonable_referenced_associations) || [])
    end

    # An explicit opt-out covers every other association writing the same table -
    # STI subclasses, scoped variants and the join models behind has_many :through.
    def ignored_base_classes(original)
      ignored_names(original).filter_map do |name|
        reflection = original.class.reflect_on_association(name)
        association_base_class(reflection) if reflection
      end
    end

    def association_base_class(reflection)
      return nil if reflection.polymorphic?

      reflection.klass.base_class
    rescue NameError
      nil
    end

    def validate_associations!(associations)
      associations.each do |assoc|
          unless @record.class.reflect_on_association(assoc)
            raise ArgumentError, I18n.t("activerecord.errors.clonable.association_not_found",
                                      association: assoc,
                                      model: @record.class.name)
          end
        end
    end

    def validate_attributes!(attributes)
      attributes.each do |attr|
        unless @record.class.column_names.include?(attr.to_s)
          raise ArgumentError, I18n.t("activerecord.errors.clonable.attribute_not_found",
                                    attribute: attr,
                                    model: self.name)
        end
      end
    end

    def reset_clone_attributes(clone)
      @record.class.clonable_reset_attributes.each do |attr|
        clone[attr] = nil if clone.has_attribute?(attr)
      end
    end

    def copy_references(original, cloned)
      return unless @record.class.clonable_referenced_associations.present?
      @record.class.clonable_referenced_associations.each do |assoc|
        next unless original.class.reflect_on_association(assoc)
        cloned.public_send("#{assoc}=", original.public_send(assoc))
      end
    end


    def log(message, level = :info)
      if Rails.env.development? && ENV["FOLIO_CLONABLE_LOG"] && Rails.logger
        Rails.logger.tagged("CLONING") do
          Rails.logger.public_send(level, message)
        end
      end
    end

    def generate_cloned_title(original_title)
      I18n.t("folio.console.clone.cloned_title",
             original_title:,
             date: Date.today.strftime("%d. %m. %Y"))
    end
end
