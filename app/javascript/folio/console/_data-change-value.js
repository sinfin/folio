// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.jQuery(document).on('click', '[data-change-value]', function (e) {
  let $targets
  const $this = window.jQuery(this)
  const target = $this.data('target')

  if (target === '*') {
    $targets = $this.closest('form').find('input, select')
  } else {
    $targets = window.jQuery(target)
  }

  $targets.val($this.data('change-value'))

  if ($this.data('change-value-submit') !== null) {
    return $this.closest('form').submit()
  }
})
