read = (url) ->
  time = localStorage?.getItem?('folioAntiCacheTime')
  if time && Number(time) + 60 * 60 * 1000 > Number(new Date)
    localStorage.getItem(url)
  else
    undefined

write = (url, html) ->
  if localStorage?.setItem?
    localStorage.setItem('folioAntiCacheTime', Number(new Date))
    localStorage.setItem?(url, html)

swapItems = ($old, $new, immediate) ->
  $old.find('[data-anti-cache-item]').each ->
    $item = $(this)
    id = $item.data('anti-cache-item')
    replacement = $new.find("[data-anti-cache-item='#{id}']")
    $item.replaceWith(replacement)

  if immediate
    $old
      .addClass('folio-anti-cache--done')
      .trigger('folioAntiCacheDone')
  else
    setTimeout (->
      $old
        .addClass('folio-anti-cache--done')
        .trigger('folioAntiCacheDone')
    ), 0

  saveAntiCacheHtml($old)

fetchFresh = ($el, url) ->
  $.get url, (res) -> swapItems($el, $(res), false)

performAntiCache = (e) ->
  $body = $(e.originalEvent.data.newBody || 'body')
  window.performFolioAntiCache $body.find('[data-anti-cache]')

saveAntiCacheHtml = ($el) ->
  write $el.data('anti-cache'), $el.prop('outerHTML')

window.performFolioAntiCache = ($items) ->
  $items.each ->
    $el = $(this)
    url = $el.data('anti-cache')
    value = read(url)

    swapItems($el, $(value), true) if value

    fetchFresh($el, url)

$(document)
  .one 'turbolinks:load', performAntiCache
  .on 'turbolinks:before-render', performAntiCache
