$(document).on 'click', '.f-c-nested-model-controls__position-button', ->
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

  $this.parent().find('.f-c-nested-model-controls__position-input').each (i) ->
    $(this)
      .val(i + 1)
      .trigger('change')

$(document).on 'click', '.f-c-nested-model-controls__destroy-button', (e) ->
  $button = $(this)

  if window.confirm(window.FolioConsole.translations.removePrompt)
    $nestedFields = $button.closest('.nested-fields')
    $nestedFieldsParent = $nestedFields.parent()

    if $button.data('remove')
      $nestedFieldsParent.trigger('cocoon:before-remove', [$nestedFields, e])
      $nestedFields.remove()
      $nestedFieldsParent.trigger('cocoon:after-remove', [$nestedFields, e])
    else
      $nestedFields.prop('hidden', true)
      $button.siblings('.f-c-nested-model-controls__destroy-input').val(1).trigger('change')
  else
    e.preventDefault()
    e.stopPropagation()
    $button.blur()
