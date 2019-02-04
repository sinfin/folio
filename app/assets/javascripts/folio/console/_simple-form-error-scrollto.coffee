$ ->
  $formAlert = $('.simple_form .alert-danger')
  return unless $formAlert.length
  $formAlert.on 'click', ->
    $field = $formAlert.closest('form').find('.form-group-invalid, .form-group.has-danger, .folio-console-react-picker--error').first()
    return unless $field.length
    $tab = $field.closest('.tab-pane')

    if $tab.length and !$tab.hasClass('active')
      id = $tab.attr('id')
      $('.nav-tabs .nav-link').filter(-> @href.split('#').pop() is id).click()

    $card = $field.closest('.card')
    if $card.length
      offset = $card.offset().top
    else
      offset = $field.offset().top

    $('html, body').animate scrollTop: offset - 16, ->
      $field.addClass('has-danger-blink')
      setTimeout (->
        $field.removeClass('has-danger-blink')
      ), 500
