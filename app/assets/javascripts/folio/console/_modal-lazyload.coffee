#
# can be removed once https://github.com/jasonslyvia/react-lazyload/pull/174 is merged
#
$modals = $('.folio-console-react-images-modal, .folio-console-react-documents-modal')

if $modals.length
  $modals.on 'scroll', ->
    window.dispatchEvent new Event('checkLazyload')
