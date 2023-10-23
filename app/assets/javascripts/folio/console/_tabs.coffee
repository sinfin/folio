isCurrentTab = (href, currentUrl, rememberedUrl) ->
  tabUrl = parseTabUrl(href)
  tabUrl is currentUrl or tabUrl is rememberedUrl

parseTabUrl = (href) ->
  href.replace('/edit', '')

$ ->
  rememberedTab = localStorage.getItem('folioConsoleOpenTab')
  localStorage.removeItem('folioConsoleOpenTab')

  if window.location.hash && window.location.hash.length > 0
    currentUrl = parseTabUrl(window.location.href)

  $currentTab = $('.simple_form .nav-link')
                  .filter -> isCurrentTab(@href, currentUrl, rememberedTab)

  if $currentTab.length
    $currentTab.click()


$(document)
  .on 'shown.bs.tab', '.simple_form .nav-link', ->
    if @href
      localStorage.setItem('folioConsoleOpenTab', parseTabUrl(@href))
      document.location.replace(@href)
