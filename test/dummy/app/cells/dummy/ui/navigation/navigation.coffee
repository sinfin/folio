$(document).on 'change', '.d-ui-navigation__select-input', ->
  $this = $(this)
  $this.siblings('.d-ui-navigation__select-overlay').remove()
  Turbolinks.visit($this.val())
