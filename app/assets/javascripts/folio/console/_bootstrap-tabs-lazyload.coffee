$(document).on 'shown.bs.tab', '[data-bs-toggle="tab"]', ->
  window.dispatchEvent new Event('checkLazyload')
