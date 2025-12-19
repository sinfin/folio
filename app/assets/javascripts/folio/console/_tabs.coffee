getResourceType = ->
  pathParts = window.location.pathname.split('/')
  consoleIndex = pathParts.indexOf('console')
  if consoleIndex >= 0 && pathParts[consoleIndex + 1]
    return pathParts[consoleIndex + 1]
  return 'default'

getStorageKey = ->
  "folioConsoleOpenTab_#{getResourceType()}"

waitForTabs = ->
  new Promise (resolve) ->
    $tabs = $('.simple_form .nav-link[data-bs-toggle="tab"]')
    if $tabs.length
      resolve()
    else
      observer = new MutationObserver ->
        if $('.simple_form .nav-link[data-bs-toggle="tab"]').length
          observer.disconnect()
          resolve()
      
      observer.observe document.body,
        childList: true
        subtree: true
      
      setTimeout ->
        observer.disconnect()
        resolve()
      , 1000

activateRememberedTab = ->
  storageKey = getStorageKey()
  rememberedTab = localStorage.getItem(storageKey)

  return unless rememberedTab

  waitForTabs().then ->
    $link = $('.simple_form .nav-link[data-bs-toggle="tab"]').filter ->
      hash = @href.split('#')[1]
      hash is rememberedTab

    if $link.length && window.bootstrap
      tabInstance = new bootstrap.Tab($link[0])
      tabInstance.show()

$ ->
  activateRememberedTab()

$(document).on 'shown.bs.tab', '.simple_form .nav-link', ->
  hash = @href.split('#')[1]
  if hash
    storageKey = getStorageKey()
    localStorage.setItem(storageKey, hash)
