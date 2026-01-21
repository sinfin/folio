# frozen_string_literal: true

Folio::Ability.class_eval do
  def folio_cache_pack_rules
    if user.superadmin?
      can :do_anything, Folio::Cache::Version
    end
  end
end
