$ ->
  $('.f-c-new-record-modal').each ->
    $modal = $(this)

    loadForm = (e, opts = {}) ->
      $modal.addClass('f-c-new-record-modal--loading')

      $.ajax
        method: opts.method or 'GET'
        url: opts.url or $modal.data('new-url')
        data: opts.data
        success: (res) ->
          if opts.create and res.id
            $toggle = $('.f-c-new-record-modal__toggle--active')
            $group = $toggle.prev('.form-group')
            selector = ".#{$group.prop('className').replace(/ /g, '.')}"
            option = new Option(res.label, res.id)

            $(selector).find('.form-control, .selectized').each ->
              $formControl = $(this)
              $formControl.append(option)
              if $formControl[0].selectize
                $formControl[0].selectize.addOption
                  text: res.label
                  id: res.id
                  value: res.id

            $formControl = $group.find('.form-control, .selectized')
            if $formControl[0].selectize
              $formControl[0].selectize.setValue(res.id, true)
            $formControl.val(res.id)

            $toggle.removeClass('f-c-new-record-modal__toggle--active')
            $modal.modal('hide')
          else
            $res = $($.parseHTML(res))

            $form = $res
              .filter('.f-c-layout-main')
              .find('.simple_form')
              .first()

            $form
              .find('.f-c-form-header__inner, .f-c-form-footer')
              .remove()

            $modal
              .find('.modal-body')
              .trigger('cocoon:before-remove', [$modal.find('.simple_form'), e])
              .html $form
              .trigger('cocoon:after-insert', [$form, e])

        error: (jxHr) ->
          $modal.modal('hide')
          alert("#{jxHr.status}: #{jxHr.statusText}")

        complete: ->
          $modal.removeClass('f-c-new-record-modal--loading')

    submitForm = (e) ->
      e.preventDefault()

      loadForm e,
        url: $modal.data('create-url')
        method: 'POST'
        data: "#{$modal.find('.simple_form').serialize()}&created_from_modal=1"
        originalEvent: e
        create: true

    $modal
      .on 'show.bs.modal', loadForm
      .on 'submit', '.simple_form', submitForm
      .on 'click', '.f-c-new-record-modal__submit', submitForm

  $(document).on 'click', '.f-c-new-record-modal__toggle', (e) ->
    e.preventDefault()
    $toggle = $(this)
    $toggle.addClass('f-c-new-record-modal__toggle--active')
    $($toggle.data('target')).modal show: true
