$(document).on 'click', '.folio-console-thumbnail__alt', (e) ->
  e.preventDefault()
  $this = $(this)
  $input = $this.prev('input')
  alt = window.prompt($(['data-alt-prompt']).data('data-alt-prompt'), $input.val())

  if alt isnt null
    $input.val(alt)
    $this.text("alt: #{alt}")
