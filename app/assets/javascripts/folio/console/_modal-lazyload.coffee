#
# can be removed once https://github.com/jasonslyvia/react-lazyload/pull/174 is merged
#
$modals = $('.folio-console-react-images-modal, .folio-console-react-documents-modal')

if $modals.length
  $modals.on 'shown.bs.modal scroll', ->
    window.dispatchEvent new Event('checkLazyload')
