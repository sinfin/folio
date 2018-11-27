$modals = $('.folio-console-react-modal')

if $modals.length
  $modals.on 'shown.bs.modal', ->
    window.dispatchEvent new Event('checkLazyload')
