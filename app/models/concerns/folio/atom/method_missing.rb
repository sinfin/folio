# frozen_string_literal: true

module Folio::Atom::MethodMissing
  extend ActiveSupport::Concern

  def method_missing(method_name, *arguments, &block)
    base_method_name = method_name.to_s
                                  .delete("=")

    question_mark = false

    if base_method_name.ends_with?("?")
      question_mark = true
      base_method_name = base_method_name.delete_suffix("?")
    end

    name_without_operator = base_method_name.to_sym

    name_for_association = name_without_operator.to_s
                                                .gsub(/_(id|type)$/, "")
                                                .to_sym

    if respond_to_missing?(name_without_operator)
      result = if klass::ASSOCIATIONS.key?(name_for_association)
        method_missing_association(method_name, arguments)
      else
        method_missing_data(method_name, arguments[0])
      end

      if question_mark
        result.present?
      else
        result
      end
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    name_without_operator = method_name.to_s
                                       .delete("=")
                                       .to_sym
    name_for_association = name_without_operator.to_s
                                                .gsub(/_(id|type)$/, "")
                                                .to_sym

    klass::STRUCTURE.key?(name_without_operator) ||
    klass::ASSOCIATIONS.key?(name_for_association) ||
    super
  end

  private
    def method_missing_association(method_name, arguments)
      name_without_operator = method_name.to_s
                                         .delete("=")
                                         .to_sym
      name_for_association = name_without_operator.to_s
                                                  .gsub(/_(id|type)$/, "")
                                                  .to_sym

      if method_name.to_s.include?("=")
        self.associations ||= {}
        if method_name.to_s.match?(/_(id|type)=$/)
          key = method_name.to_s.match?(/_id=$/) ? "id" : "type"
          self.associations[name_for_association.to_s] ||= {}
          self.associations[name_for_association.to_s][key] = arguments[0]
        else
          if arguments[0].is_a?(Hash)
            self.associations[name_for_association.to_s] = {
              "id" => arguments[0][:id].present? ? arguments[0][:id] : nil,
              "type" => arguments[0][:type].present? ? arguments[0][:type].constantize.base_class.name : nil,
            }
          else
            self.associations[name_for_association.to_s] = {
              "id" => arguments[0].id,
              "type" => arguments[0].class.base_class.name,
            }
          end
        end
      else
        assoc = (self.associations || {})[name_for_association.to_s] || {}
        if method_name.to_s.match?(/_(id|type)$/)
          key = method_name.to_s.match?(/_id$/) ? "id" : "type"
          assoc[key]
        else
          if assoc["type"].present? && assoc["id"].present?
            scope = assoc["type"].constantize
            if arguments.present? &&
               arguments.first.present? &&
               includes = arguments.first.try(:[], :includes)
              scope = scope.includes(*includes)
            end
            scope.find_by_id(assoc["id"])
          else
            nil
          end
        end
      end
    end

    def method_missing_data(method_name, argument)
      name_without_operator = method_name.to_s
                                         .delete("=")
                                         .to_sym

      is_bool = klass::STRUCTURE[name_without_operator] == :boolean
      is_date = klass::STRUCTURE[name_without_operator] == :date
      is_datetime = klass::STRUCTURE[name_without_operator] == :datetime

      if method_name.to_s.include?("=")
        self.data ||= {}
        value = argument

        if is_bool
          if value == "false" || value == "0"
            value = false
          else
            value = value.present?
          end
        elsif is_date || is_datetime
          begin
            value = Time.zone.parse(value)
          rescue StandardError
            value = nil
          end

          if value && is_date
            value = value.to_date
          end
        end

        self.data[name_without_operator.to_s] = value
      else
        result = nil
        val = (self.data || {})[name_without_operator.to_s]

        if is_bool
          result = val.present?
        elsif is_date || is_datetime
          if val.present?
            if is_date && val.is_a?(Date)
              result = val
            elsif is_datetime && val.is_a?(Time)
              result = val.to_datetime
            elsif is_datetime && val.is_a?(DateTime)
              result = val
            else
              begin
                result = Time.zone.parse(val)
              rescue StandardError
                result = nil
              end
            end
          else
            result = val
          end
        else
          result = val
        end

        if method_name.to_s.ends_with?("?")
          !!result
        else
          result
        end
      end
    end
end
