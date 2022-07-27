$modals = $('.f-c-r-modal')

if $modals.length
  $modals.on 'shown.bs.modal', ->
    window.dispatchEvent new Event('checkLazyload')
