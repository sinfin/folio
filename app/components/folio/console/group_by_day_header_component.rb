# frozen_string_literal: true

class Folio::Console::GroupByDayHeaderComponent < Folio::Console::ApplicationComponent
  def initialize(scope:, date:, attribute:, before_label: nil, label_lambda: nil, klass: nil, after_label: nil)
    @scope = scope
    @date = date
    @attribute = attribute
    @before_label = before_label
    @label_lambda = label_lambda
    @klass = klass
    @after_label = after_label
  end

  def render?
    @date.present?
  end

  def count
    return @count unless @count.nil?

    date = @date.to_date
    @count = @scope.unscope(:limit, :offset)
                    .where("#{@attribute} > ?", date.beginning_of_day)
                    .where("#{@attribute} < ?", date.end_of_day)
                    .count
  end
end
