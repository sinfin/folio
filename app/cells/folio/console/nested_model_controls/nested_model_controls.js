window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.NestedModelControls = {}

window.FolioConsole.NestedModelControls.setPositionsIn = ($wrap) => {
  $wrap.find('.f-c-nested-model-controls__position-input').each((i, el) => {
    $(el).val(i + 1)
  })
}

window.FolioConsole.NestedModelControls.onPositionClick = (e) => {
  const $button = $(e.target)
  const $fields = $button.closest('.nested-fields')
  const moveUp = $button.data('direction') === 'up'
  let $target

  if (moveUp) {
    $target = $fields.prevAll('.nested-fields:first')
  } else {
    $target = $fields.nextAll('.nested-fields:first')
  }
  if (!$target.length) {
    return
  }
  if (moveUp) {
    $fields.after($target)
  } else {
    $target.after($fields)
  }
  return $fields.parent().find('.f-c-nested-model-controls__position-input').each(function (i) {
    return $(this).val(i + 1).trigger('change')[0].dispatchEvent(new window.Event('change', { bubbles: true }))
  })
}

window.FolioConsole.NestedModelControls.onDestroyClick = (e) => {
  const $button = $(e.target)

  if (window.confirm(window.FolioConsole.translations.removePrompt)) {
    const $nestedFields = $button.closest('.nested-fields')
    const $nestedFieldsParent = $nestedFields.parent()
    if ($button.data('remove')) {
      $nestedFieldsParent.trigger('cocoon:before-remove', [$nestedFields, e])
      $nestedFields.remove()
      $nestedFieldsParent.trigger('cocoon:after-remove', [$nestedFields, e])
    } else {
      $nestedFields.prop('hidden', true)
      const $input = $button.closest('.f-c-nested-model-controls').find('.f-c-nested-model-controls__destroy-input').val(1).trigger('change')

      if ($input[0]) {
        $input[0].dispatchEvent(new window.Event('change', { bubbles: true }))
      }

      $nestedFields.find('.f-c-nested-model-controls__position-input').remove()
      window.FolioConsole.NestedModelControls.setPositionsIn($nestedFields.parent())
    }
  } else {
    e.preventDefault()
    e.stopPropagation()
    $button.blur()
  }
}

window.FolioConsole.NestedModelControls.afterInsert = (e, insertedItem) => {
  window.FolioConsole.NestedModelControls.setPositionsIn($(insertedItem).closest('.nested-fields').parent())
}

window.FolioConsole.NestedModelControls.beforeRemove = (e, item) => {
  const $item = $(item)
  $item.find('.f-c-nested-model-controls__position-input').remove()
  window.FolioConsole.NestedModelControls.setPositionsIn($item.closest('.nested-fields').parent())
}

$(document)
  .on('click', '.f-c-nested-model-controls__position-button', window.FolioConsole.NestedModelControls.onPositionClick)
  .on('click', '.f-c-nested-model-controls__destroy-button', window.FolioConsole.NestedModelControls.onDestroyClick)
  .on('cocoon:after-insert', window.FolioConsole.NestedModelControls.afterInsert)
  .on('cocoon:before-remove', window.FolioConsole.NestedModelControls.beforeRemove)
