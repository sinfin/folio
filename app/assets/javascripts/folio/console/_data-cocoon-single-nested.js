// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.jQuery(document).on('single-nested-change', '[data-cocoon-single-nested]', function (e) {
  let $fields, $this
  $this = window.jQuery(this)
  $fields = $this.find('.nested-fields').not('[hidden]')
  return $this.toggleClass('folio-console-has-nested', $fields.length > 0)
})
