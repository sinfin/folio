# frozen_string_literal: true

class Folio::Merger
  attr_accessor :original,
                :duplicate,
                :klass,
                :targets

  ORIGINAL = "original"
  DUPLICATE = "duplicate"

  def initialize(original, duplicate, klass: nil)
    @original = original
    @duplicate = duplicate

    if @original == @duplicate
      fail "Cannot merge record into itself"
    end

    @klass = klass || default_klass
    @targets = {}

    structure.each do |row|
      key = row.is_a?(Hash) ? row[:key] : row
      @targets[key] = ORIGINAL
    end
  end

  def merge(params, bang: false)
    @targets.merge!(params.to_h.symbolize_keys)

    attrs = {}

    structure.each do |row|
      is_hash = row.is_a?(Hash)
      key = is_hash ? row[:key] : row
      next if @targets[key] != DUPLICATE
      if is_hash
        attrs = merge_hash_row(attrs, row)
      else
        attrs[key] = @duplicate.send(key)
      end
    end

    ActiveRecord::Base.transaction do
      update_atom_associations
      merge_atoms
      merge_placements
      merge_custom_relations

      if bang
        @original.update!(attrs)
        @duplicate.reload.destroy!
        post_merge_update(bang: bang)
        success = true
      else
        success = @original.update(attrs)
        @duplicate.reload.destroy
        success = success && (post_merge_update(bang: bang) != false)
      end

      success
    end
  end

  def merge!(params)
    merge(params, bang: true)
  end

  def permitted_params
    structure.map do |row|
      if row.is_a?(Hash)
        row[:key]
      else
        row
      end
    end
  end

  private
    def default_klass
      self.class.module_parent
    end

    def merge_hash_row(attrs, row)
      case row[:as]
      when :publishable_and_featured
        %i[featured published published_at].each do |attr|
          if @original.respond_to?(attr)
            attrs[attr] = @duplicate.send(attr)
          end
        end
      else
        attrs = merge_custom_hash_row(attrs, row)
      end
      attrs
    end

    def merge_atoms
      return unless @targets[:atoms] == DUPLICATE

      if @original.class.respond_to?(:atom_locales)
        keys = @original.class.atom_locales.map { |locale| "#{locale}_atoms" }
      else
        keys = %i[atoms]
      end

      keys.each do |key|
        @original.send(key).destroy_all
        @duplicate.send(key).update_all(placement_id: @original.id,
                                        placement_type: original_type)
      end
    end

    def merge_placements
      structure.each do |row|
        next unless row.is_a?(Hash)
        next unless @targets[row[:key]] == DUPLICATE

        if row[:as] == :file_placement
          @original.send(row[:key]).try(:destroy)
          duplicate_placement = @duplicate.send(row[:key])
          if duplicate_placement
            duplicate_placement.update!(placement: @original)
          end
        elsif row[:as] == :file_placements
          @original.send(row[:key]).each(&:destroy!)
          @duplicate.send(row[:key]).each { |fp| fp.update!(placement: @original) }
        end
      end
    end

    def merge_custom_relations
    end

    def post_merge_update(bang: false)
    end

    def merge_custom_hash_row(attrs, _row)
      attrs
    end

    def original_type
      @original_type ||= @original.try(:type) || @klass.to_s
    end

    def update_atom_associations
      Folio::Atom.types.each do |atom_klass|
        atom_klass::ASSOCIATIONS.each do |key, class_names|
          if class_names.include?(@klass.to_s)
            atom_klass.where("folio_atoms.associations -> ? ->> 'type' = ?",
                             key,
                             @klass.to_s)
                      .where("folio_atoms.associations -> ? ->> 'id' = ?",
                             key,
                             @duplicate.id.to_s)
                      .each { |atom| atom.update!(key => @original) }
          end
        end
      end
    end
end
