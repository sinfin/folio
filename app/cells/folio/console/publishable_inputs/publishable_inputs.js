$(document).on('change', '.f-c-publishable-inputs__checkbox', function () {
  const $this = $(this)
  const $parent = $this.closest('.f-c-publishable-inputs__box')

  $parent.toggleClass('f-c-publishable-inputs__box--active', this.checked)

  if (this.checked) {
    const $input = $parent.find(window.Folio.Input.DateTime.SELECTOR).first()

    if ($input.length && !$input.val() && $input.prop('folioInputTempusDominus')) {
      const oneMinuteAgo = new Date() - 60 * 1000
      $input.val($input.prop('folioInputTempusDominus').dates.formatInput(new window.tempusDominus.DateTime(oneMinuteAgo)))
    }
  }
})
