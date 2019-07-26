$ ->
  $localeButtons = $('.f-c-atoms-form-header__button--locale')
  return if $localeButtons.length is 0
  $localeButtons.on 'click', (e) ->
    e.preventDefault()
    $localeButtons.removeClass('f-c-atoms-form-header__button--active')
    $button = $(this)
    $button.addClass('f-c-atoms-form-header__button--active')
    $button
      .closest('.f-c-atoms-form-header')
      .attr('data-active-offset', $button.nextAll('.f-c-atoms-form-header__button').length)
    msg =
      type: 'selectLocale'
      locale: $button.data('locale')
    document
      .getElementById('f-c-simple-form-with-atoms__iframe')
      .contentWindow
      .postMessage(msg, window.origin)

  $settingsButtons = $('.f-c-atoms-form-header__button--settings')
  $settingsButtons.on 'click', (e) ->
    e.preventDefault()
    $('.f-c-simple-form-with-atoms__form--settings')
      .toggleClass('f-c-simple-form-with-atoms__form--active')
