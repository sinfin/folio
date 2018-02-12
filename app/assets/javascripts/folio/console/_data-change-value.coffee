$(document).on 'click', '[data-change-value]', (e) ->
  $this = $(this)
  target = $this.data('target')

  if target is '*'
    $targets = $this.closest('form').find('input')
  else
    $targets = $(target)

  $targets.val($this.data('change-value'))
