handleMenuOverflow = ->
  $('.d-ui-header__menu').each ->
    $menu = $(this)
    return if $menu.siblings('.d-ui-header__menu-toggle').is(':visible')

    $moreLi = $menu.find('.d-ui-header__menu-li--more')
    $moreUl = $moreLi.children('.d-ui-header__menu-children-ul')
    $moreLi.prop('hidden', false)

    width = $menu.width()
    moreLiWidth = $moreLi.outerWidth(true)
    limit = width - moreLiWidth

    $moreUl.html('')
    html = ""

    $allLi = $menu.find('.d-ui-header__menu-li').not('.d-ui-header__menu-li--more')
    count = $allLi.length
    toCollapse = []

    $allLi
      .removeClass('d-ui-header__menu-li--collapsed')
      .each (i, li) ->
        $li = $(li)
        endsAt = $li.position().left + $li.outerWidth(true)

        if endsAt > limit
          if i is count - 1 and endsAt <= width and toCollapse.length is 0
            # last one fits, no need to respect moreLiWidth
          else
            $li.find('a').each ->
              html += """
                <li class="d-ui-header__menu-children-li">
                  <a href="#{@href}" class="d-ui-header__menu-children-a">
                    <span class="d-ui-header__menu-span">
                      #{$(this).find('.d-ui-header__menu-span').text()}
                    </span>
                  </a>
                </li>
              """
            toCollapse.push($li)

    toCollapse.forEach ($li) -> $li.addClass('d-ui-header__menu-li--collapsed')
    $moreLi.prop('hidden', toCollapse.length is 0)
    $moreUl.html(html)
    $menu.addClass('d-ui-header__menu--bound')

$(document)
  .on 'click', '.d-ui-header__menu-a--expandable', (e) ->
    e.preventDefault()
    e.stopPropagation()
    $(this)
      .closest('.d-ui-header__menu-li')
      .toggleClass('d-ui-header__menu-li--expanded')

  .on 'turbolinks:load', ->
    if $('.d-ui-header__menu').length
      $(window).on('resize.uiHeaderMenu orientationchange.uiHeaderMenu', window.folioDebounce(handleMenuOverflow, 100))
      handleMenuOverflow()

  .on 'turbolinks:before-render', ->
    $(window).off('.uiHeaderMenu')
