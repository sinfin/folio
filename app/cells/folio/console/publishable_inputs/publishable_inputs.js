$(document).on('change', '.f-c-publishable-inputs__checkbox', function () {
  const $this = $(this)
  const $parent = $this.closest('.f-c-publishable-inputs__box')

  $parent.toggleClass('f-c-publishable-inputs__box--active', this.checked)

  if (this.checked) {
    const $input = $parent.find('.f-c-publishable-inputs__input').first()

    if ($input.length && !$input.val()) {
      const format = $input.data('DateTimePicker').options().format
      const now = window.moment()
      $input.val(now.format(format))
    }
  }
})
