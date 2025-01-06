# frozen_string_literal: true

class Folio::Clonable::Cloner
  def initialize(record)
    @record = record
    validate_associations!(@record.class.clonable_ignored_associations)
    validate_associations!(@record.class.clonable_referenced_associations)
    validate_attributes!(@record.class.clonable_reset_attributes)
  end

  def create_clone
    log("CLONING", :info)
    log(I18n.t("cloning.start", model: self.class.name, id: @record.id))
    clone, duplicated = clone_nested_records_recursively(@record)
    log(I18n.t("cloning.associations_duplicated", associations: duplicated))
    reset_clone_attributes(clone)
    log(I18n.t("cloning.finished"))

    if clone.respond_to?(:title=)
      clone.title = generate_cloned_title(@record.title)
    end
    clone
  rescue => e
    log(I18n.t("cloning.error", message: e.message), :error)
    log(e.backtrace.first(5).join("\n"), :error)
    raise
  end

  private
    def clone_nested_records_recursively(original)
      duplicated = []
      cloned = original.deep_dup
      copy_references(original, cloned)
      original.class.reflect_on_all_associations.each do |association|
        next if @record.class.clonable_ignored_associations.include?(association.name)
        next if @record.class.clonable_referenced_associations.include?(association.name)
        if original.public_send(association.name).present?
          duplicated << association.name
          if association.macro == :has_many
            associated_record = original.public_send(association.name).map { |a| clone_nested_records_recursively(a).first }
          else
            associated_record = @record.class.clonable_referenced_associations.include?(association.name) ? original.public_send(association.name) : original.public_send(association.name).deep_dup
          end
          cloned.public_send("#{association.name}=", associated_record)
        end
      end
      [cloned, duplicated]
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
