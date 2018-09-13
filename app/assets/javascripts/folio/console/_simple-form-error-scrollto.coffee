$ ->
  $formAlert = $('.simple_form .alert-danger')
  return unless $formAlert.length
  $formAlert.on 'click', ->
    $field = $formAlert.closest('form').find('.form-group.has-danger').first()
    return unless $field.length
    $tab = $field.closest('.tab-pane')

    if $tab.length and !$tab.hasClass('active')
      id = $tab.attr('id')
      $('.nav-tabs .nav-link').filter(-> @href.split('#').pop() is id).click()

    offset = $field.offset().top
    offset = $field.closest('.card').offset().top if offset is 0

    $('html, body').animate scrollTop: offset - 16, ->
      $field.addClass('has-danger-blink')
      setTimeout (->
        $field.removeClass('has-danger-blink')
      ), 500
