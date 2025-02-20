// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  const INPUT_SELECTOR = '.position, .folio-console-nested-model-position-input'

  window.jQuery(document).on('cocoon:after-insert', function (e, insertedItem) {
    const $item = window.jQuery(insertedItem)
    const $input = window.jQuery(insertedItem).find(INPUT_SELECTOR)

    if (!$input.length) {
      return
    }

    const pos = $item.prevAll('.nested-fields:first').find(INPUT_SELECTOR).val()

    return $input.val((parseInt(pos) || 0) + 1)
  })
})()
