$(document)
  .on 'click', '.d-ui-header__menu-a--expandable', (e) ->
    e.preventDefault()
    e.stopPropagation()
    $(this)
      .closest('.d-ui-header__menu-li')
      .toggleClass('d-ui-header__menu-li--expanded')
