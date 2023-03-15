# frozen_string_literal: true

module Folio::HasRoles
  extend ActiveSupport::Concern

  included do
    validate :validate_roles
    before_validation :normalize_roles

    scope :without_role, -> (role) {
      where.not("roles ? :role", role:)
    }

    scope :without_roles, -> (role) {
      where.not("roles ?| array[:roles]", roles:)
    }

    scope :by_role, -> (role) {
      where("roles ? :role", role:)
    }

    scope :by_roles, -> (roles) {
      where("roles ?| array[:roles]", roles:)
    }
  end

  class_methods do
    def roles
      # keep the order by strength (strongest first)!
      %w[]
    end

    def human_role_name(role)
      human_attribute_name("roles/#{role}")
    end

    def roles_for_select(selectable_roles = nil)
      (selectable_roles || roles).map do |role|
        [human_attribute_name("roles/#{role}"), role]
      end
    end

    def roles_mandatory?
      true
    end
  end

  def has_role?(role)
    roles.include?(role.to_s)
  end

  def has_any_roles?(roles_to_check)
    roles_to_check.any? { |role| roles.include?(role) }
  end

  def has_all_roles?(roles_to_check)
    roles_to_check.all? { |role| roles.include?(role) }
  end

  def human_role_names
    roles.map do |role|
      self.class.human_role_name(role)
    end
  end

  private
    def validate_roles
      if roles.blank?
        errors.add :roles, :missing if self.class.roles_mandatory?
      elsif roles.any? { |role| self.class.roles.exclude?(role) }
        errors.add :roles, :invalid
      end
    end

    # keep defined order and allow only known roles
    def normalize_roles
      self.roles = if self.roles.blank?
        []
      else
        self.class.roles.select { |role| roles.include?(role) }
      end
    end
end
