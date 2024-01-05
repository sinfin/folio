# frozen_string_literal: true

class AddOwnerToAddresses < ActiveRecord::Migration[7.0]
  def up
    add_reference :folio_addresses, :owner, polymorphic: true

    say_with_time "updating records" do
      if Folio::Address::Base.exists?
        classes_with_addresses.each do |klass|
          owner_type = klass.to_s
          foreign_keys = klass.column_names.intersection(%w[primary_address_id secondary_address_id]).map(&:to_sym)

          scope = klass.where.not(foreign_keys.first => nil)
          scope = scope.or(klass.where.not(foreign_keys.second => nil)) if foreign_keys.second

          scope.select(:id, *foreign_keys)
               .find_in_batches do |records|
            attributes = []

            records.each do |record|
              attributes << { id: record.primary_address_id, owner_id: record.id, owner_type: } if record.try(:primary_address_id)
              attributes << { id: record.secondary_address_id, owner_id: record.id, owner_type: } if record.try(:secondary_address_id)
            end

            Folio::Address::Base.upsert_all(attributes) if attributes.present?
          end

          puts "   #{klass.table_name} updated"
        end
      end

      Folio::Address::Base.where(owner_type: nil).delete_all
    end

    classes_with_addresses.each do |klass|
      remove_reference klass.table_name, :primary_address if klass.column_names.include?("primary_address_id")
      remove_reference klass.table_name, :secondary_address if klass.column_names.include?("secondary_address_id")
    end
  end

  def down
    classes_with_addresses.each do |klass|
      add_reference klass.table_name, :primary_address
      add_reference klass.table_name, :secondary_address
    end

    say_with_time "updating records" do
      Folio::Address::Base.distinct
                          .pluck(:owner_type)
                          .compact
                          .each do |owner_type|
        klass = owner_type.constantize

        {
          Folio::Address::Primary => :primary_address_id,
          Folio::Address::Secondary => :secondary_address_id,
        }.each do |address_klass, foreign_key|
          address_klass.where(owner_type:)
                       .select(:id, :type, :owner_id)
                       .find_in_batches do |addresses|
            attributes = addresses.map do |address|
              {
                id: address.owner_id,
                foreign_key => address.id
              }
            end

            klass.upsert_all(attributes) if attributes.present?
          end
        end
      end
    end

    remove_reference :folio_addresses, :owner, polymorphic: true
  end

  private
    def classes_with_addresses
      @classes_with_addresses ||= ActiveRecord::Base.descendants.filter do |klass|
        klass.table_name.present? && klass.base_class? && klass.ancestors.include?(Folio::HasAddresses)
      end
    end
end
