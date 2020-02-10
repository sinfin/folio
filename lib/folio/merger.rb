# frozen_string_literal: true

class Folio::Merger
  attr_accessor :original,
                :duplicate,
                :klass,
                :targets

  def initialize(original, duplicate, klass: nil)
    @original = original
    @duplicate = duplicate
    @klass = klass || default_klass
    @targets = {}

    structure.each do |row|
      key = row.is_a?(Hash) ? row[:key] : row
      @targets[key] = 'original'
    end
  end

  def merge(params, bang: false)
    @targets.merge!(params)

    attrs = {}

    structure.each do |row|
      is_hash = row.is_a?(Hash)
      key = is_hash ? row[:key] : row
      next if @targets[key] != 'duplicate'
      if is_hash
        attrs = merge_hash_row(attrs, row)
      else
        attrs[key] = @duplicate.send(key)
      end
    end

    ActiveRecord::Base.transaction do
      merge_atoms

      if bang
        @original.update!(attrs)
        @duplicate.destroy!
      else
        @original.update(attrs)
        @duplicate.destroy
      end
    end
  end

  def merge!(params)
    merge(params, bang: true)
  end

  private

    def default_klass
      self.class.parent
    end

    def merge_hash_row(attrs, row)
      case row[:as]
      when :publishable_and_featured
        %i[featured published published_at].each do |attr|
          if @original.respond_to?(attr)
            attrs[attr] = @duplicate.send(attr)
          end
        end
      end
      attrs
    end

    def merge_atoms
      return unless @targets[:atoms] == 'duplicate'

      if @original.class.respond_to?(:atom_locales)
        keys = @original.class.atom_locales.map { |locale| "#{locale}_atoms" }
      else
        keys = %i[atoms]
      end

      keys.each do |key|
        @original.send(key).destroy_all
        @duplicate.send(key).update_all(placement_id: @original.id)
      end
    end
end
