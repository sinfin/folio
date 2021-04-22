$(document)
  .on 'click', '.d-ui-flash__close ', ->
    $alert = $(this).closest('.d-ui-flash__alert')
    $alert.slideUp(150, -> $alert.remove())
