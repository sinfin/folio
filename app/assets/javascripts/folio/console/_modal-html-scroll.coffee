$(document).on 'show.bs.modal', '.modal', ->
  document.documentElement.classList.add('modal-open')

$(document).on 'hide.bs.modal', '.modal', ->
  document.documentElement.classList.remove('modal-open')
