handleMenuOverflow = ->
  $('.d-ui-menu').each ->
    $menu = $(this)
    return if $menu.find('.d-ui-menu__mq--mobile').is(':visible')

    $moreLi = $menu.find('.d-ui-menu__li--more')
    $moreUl = $moreLi.children('.d-ui-menu__children-ul')
    $moreLi.prop('hidden', false)

    width = $menu.width()
    moreLiWidth = $moreLi.outerWidth(true)
    limit = width - moreLiWidth

    $moreUl.html('')

    $allLi = $menu.find('.d-ui-menu__li').not('.d-ui-menu__li--more')
    count = $allLi.length
    toCollapse = []

    $allLi
      .removeClass('d-ui-menu__li--collapsed')
      .each (i, li) ->
        $li = $(li)
        endsAt = $li.position().left + $li.outerWidth(true)

        if endsAt > limit
          if i is count - 1 and endsAt <= width and toCollapse.length is 0
            # last one fits, no need to respect moreLiWidth
          else
            $clone = $li.clone()
            if $clone.find('a').length < 4
              $clone.addClass('d-ui-menu__li--expanded')

            $moreUl.append($clone)
            toCollapse.push($li)

    toCollapse.forEach ($li) -> $li.addClass('d-ui-menu__li--collapsed')
    $moreLi.prop('hidden', toCollapse.length is 0)
    $menu.addClass('d-ui-menu--bound')

$(document)
  .on 'click', '.d-ui-menu__a--expandable', (e) ->
    e.preventDefault()
    e.stopPropagation()
    $(this)
      .closest('.d-ui-menu__li')
      .toggleClass('d-ui-menu__li--expanded')

  .on 'turbolinks:load', ->
    if $('.d-ui-menu').length
      $(window).on('resize.uiHeaderMenu orientationchange.uiHeaderMenu', window.Folio.debounce(handleMenuOverflow, 100))
      handleMenuOverflow()

  .on 'turbolinks:before-render', ->
    $(window).off('.uiHeaderMenu')
