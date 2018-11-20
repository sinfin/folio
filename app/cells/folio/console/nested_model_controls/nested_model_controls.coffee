$(document).on 'click', '.folio-console-nested-model-position-button', ->
  $button = $(this)
  $this = $button.closest('.nested-fields')
  moveUp = $button.data('direction') is 'up'

  if moveUp
    $target = $this.prevAll('.nested-fields:first')
  else
    $target = $this.nextAll('.nested-fields:first')

  return unless $target.length

  if moveUp
    $this.after($target)
  else
    $target.after($this)

  $this.parent().find('.folio-console-nested-model-position-input').each (i) ->
    $(this).val(i + 1)

$(document).on 'click', '.folio-console-nested-model-destroy-button', ->
  $button = $(this)
  unless window.confirm(window.FolioConsole.translations.removePrompt)
    return $button.blur()
  $button.siblings('input[type="hidden"]').val(1)
  $button.closest('.nested-fields').hide(0)
