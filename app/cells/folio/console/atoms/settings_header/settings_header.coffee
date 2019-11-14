$ ->
  $closeButtons = $('.f-c-atoms-settings-header__js-close')
  return if $closeButtons.length is 0
  $closeButtons.on 'click', (e) ->
    e.preventDefault()
    $(this)
      .closest('.f-c-simple-form-with-atoms__form--active')
      .removeClass('f-c-simple-form-with-atoms__form--active')
