$(document).on 'click', '[data-change-value]', (e) ->
  $this = $(this)
  target = $this.data('target')

  if target is '*'
    $targets = $this.closest('form').find('input, select')
  else
    $targets = $(target)

  $targets.val($this.data('change-value'))

  if $this.data('change-value-submit')?
    $this.closest('form').submit()
