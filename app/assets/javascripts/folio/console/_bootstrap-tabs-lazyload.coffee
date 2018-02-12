$(document).on 'shown.bs.tab', '[data-toggle="tab"]', ->
  window.dispatchEvent new Event('checkLazyload')
