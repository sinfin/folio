$ ->
  $layoutButtons = $('.f-c-atoms-layout-switch__button')
  return if $layoutButtons.length is 0

  $layoutButtons.on 'click', (e) ->
    e.preventDefault()
    $button = $(this)
    $button.siblings().removeClass('f-c-atoms-layout-switch__button--active')
    $button.addClass('f-c-atoms-layout-switch__button--active')

    layout = $button.data('layout')
    Cookies.set('f_c_atoms_layout_switch', layout)

    $button
      .closest('.f-c-simple-form-with-atoms')
      .removeClass('f-c-simple-form-with-atoms--layout-vertical f-c-simple-form-with-atoms--layout-horizontal')
      .addClass("f-c-simple-form-with-atoms--layout-#{layout}")
