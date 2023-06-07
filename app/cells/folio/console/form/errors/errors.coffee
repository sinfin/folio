$ ->
  $formGroups = $('.form-group-invalid, \
                  .form-group.has-danger, \
                  .folio-console-react-picker--error')

  if $formGroups.length
    $errorButtons = $('.f-c-form-errors__button--hidden')

    $formGroups.each ->
      $formGroup = $(this)

      if $formGroup.hasClass('folio-console-react-picker--error')
        $errorButtons
          .filter('.f-c-form-errors__button--hidden')
          .filter ->
            $(this).data('error-field').indexOf('cover_placement') isnt -1
          .removeClass('f-c-form-errors__button--hidden')
          .data('errorFormGroup', $formGroup)
      else
        key = $formGroup
          .find('.form-control:visible, .form-control.redactor-source')
          .prop('name')

        key = key.match(/\[(.+)\]$/) if key
        key = key[1] if key

        if key
          key = key.replace('_attributes', '').replace(/\]\[\d*\]\[/, '.')
          $errorButtons
            .filter('.f-c-form-errors__button--hidden')
            .filter("[data-error-field='#{key}']")
            .removeClass('f-c-form-errors__button--hidden')
            .data('errorFormGroup', $formGroup)

    $(document).on 'click', '.f-c-form-errors__button', (e) ->
      e.preventDefault()
      $button = $(this)
      $formGroup = $button.data('errorFormGroup')
      return if not $formGroup or $formGroup.length is 0

      $tab = $formGroup.closest('.tab-pane')

      if $tab.length and !$tab.hasClass('active')
        id = $tab.attr('id')
        $('.nav-tabs .nav-link').filter(-> @href.split('#').pop() is id).click()

      $card = $formGroup.closest('.card')
      if $card.length
        offset = $card.offset().top
      else
        offset = $formGroup.offset().top

      callback = ->
        $formGroup.addClass('has-danger-blink')

        if $formGroup.hasClass('string') or $formGroup.hasClass('text')
          $formGroup.find('.form-control').focus()

        setTimeout (->
          $formGroup.removeClass('has-danger-blink')
        ), 500

      if offset > $(window).height() / 2
        $(document.documentElement).animate scrollTop: offset - $scroll.offset().top - 10, callback
      else
        callback()
