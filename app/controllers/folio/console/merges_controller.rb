# frozen_string_literal: true

class Folio::Console::MergesController < Folio::Console::BaseController
  before_action do
    class_name = params.require(:klass)
    klass = class_name.try(:safe_constantize)

    if klass && klass < ActiveRecord::Base
      @klass = klass
      merger_klass = "#{class_name}::Merger".safe_constantize

      if merger_klass
        @merger = merger_klass.new(@klass.find(params.require(:original_id)),
                                   @klass.find(params.require(:duplicate_id)),
                                   klass: @klass)
        next
      end
    end

    raise ActionController::ParameterMissing, :klass
  end

  def new
  end

  def create
  end
end
