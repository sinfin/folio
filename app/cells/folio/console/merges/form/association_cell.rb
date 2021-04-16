# frozen_string_literal: true

class Folio::Console::Merges::Form::AssociationCell < Folio::ConsoleCell
  def show
    render if model.present?
  end

  def multi
    return @multi unless @multi.nil?
    if model[:reflection].class == ActiveRecord::Reflection::ThroughReflection
      @multi = model[:reflection].send(:delegate_reflection).is_a?(ActiveRecord::Reflection::HasManyReflection)
    else
      @multi = model[:reflection].is_a?(ActiveRecord::Reflection::HasManyReflection)
    end
  end

  def records
    @records ||= if multi
      model[:record].send(model[:reflection].name)
    else
      relation = model[:record].send(model[:reflection].name)
      if relation
        [relation]
      else
        []
      end
    end
  end
end
