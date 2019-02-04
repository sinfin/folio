# frozen_string_literal: true

class Folio::Console::ActionsCell < Folio::ConsoleCell
  def actions
    @actions ||= (options[:actions].presence || %i[show edit destroy])
  end

  def button(label, url, opts = {})
    link_to(label, url, opts.reverse_merge(class: 'btn btn-secondary mr-3'))
  end

  def destroy_button
    name = model.try(:to_label) ||
           model.try(:title) ||
           model.class.model_name.human
    question = t('folio.console.really_delete', title: name)

    opts = {
      'data-confirm': question,
      method: :delete,
      class: 'btn btn-danger mr-3',
    }

    link_to(t('.destroy'), url_for([:console, model]), opts)
  end

  def back_link
    class_name = 'btn btn-outline-secondary'
    if request.url != request.referrer
      ActionController::Base.helpers.link_to(t('.back'),
                                             :back,
                                             class: class_name)
    else
      button(t('.back'), url_for(action: :index), class: class_name)
    end
  end
end
