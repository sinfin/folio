// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.jQuery(document).on('click', '[data-destroy-association]', function (e) {
  let $fields, $this
  $this = window.jQuery(this)
  if (!window.confirm(window.FolioConsole.translations.removePrompt)) {
    return $this.blur()
  }
  $fields = $this.closest('.nested-fields')
  $fields.find('input').filter(function () {
    return this.name.indexOf('[_destroy]') !== -1
  }).val(1)
  $fields.attr('hidden', true)
  return $this.closest('[data-cocoon-single-nested]').trigger('single-nested-change')
})
