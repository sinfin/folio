//= require message-bus

window.Folio = window.Folio || {}
window.Folio.MessageBus = {}

// respect lib/folio.rb
window.Folio.MessageBus.channel = "folio_messagebus_channel"
window.Folio.MessageBus.callbacks = window.Folio.MessageBus.callbacks || {}
window.Folio.MessageBus.debug = false

window.MessageBus.start()

//
// how often do you want the callback to fire in ms in case of failure
// note the code from message-bus.js:
//
// interval = me.callbackInterval;
// if (failCount > 2) {
//   interval = interval * failCount;
// }
//
window.MessageBus.callbackInterval = 500

// -2 will recieve last message + all new messages
//   -> we want the last message to receive last id in case we go offline before first messages arrives
window.Folio.MessageBus.onlyGetMessageIdForFirstMessage = true
// disable after 5 seconds in the rare case of no messages in redis
setTimeout(() => { window.Folio.MessageBus.onlyGetMessageIdForFirstMessage = false }, 5000)

window.Folio.MessageBus.lastId = -2

window.Folio.MessageBus.handleMessage = (msg, globalMsgId, msgId) => {
  window.Folio.MessageBus.lastId = msgId

  if (window.Folio.MessageBus.onlyGetMessageIdForFirstMessage) {
    window.Folio.MessageBus.onlyGetMessageIdForFirstMessage = false
    return
  }

  const data = JSON.parse(msg)

  if (!data) return

  if (window.Folio.MessageBus.debug) {
    console.group("[Folio] [MessageBus] handleMessage")
    console.log(msgId)
    console.log(data)
    console.groupEnd()
  }

  Object.values(window.Folio.MessageBus.callbacks).forEach((callback) => { callback(data) })
}

window.MessageBus.subscribe(window.Folio.MessageBus.channel,
                            window.Folio.MessageBus.handleMessage,
                            window.Folio.MessageBus.lastId)

window.Folio.MessageBus.callbacks['Folio::GenerateThumbnailJob'] = (data) => {
  if (!data || data.type !== 'Folio::GenerateThumbnailJob') return
  const { temporary_url, temporary_s3_url, url } = data.data
  if (!temporary_url || !temporary_s3_url || !url) return

  [temporary_url, temporary_s3_url].forEach((tempUrl) => {
    $(`img[src='${tempUrl}']`).attr('src', url)

    $(`img[srcset*='${tempUrl}']`).each((i, el) => {
      const $img = $(el)
      $img.attr('srcset', $img.attr('srcset').replace(tempUrl, url))
    })

    $('.folio-thumbnail-background').each((i, el) => {
      const $el = $(el)
      const bg = $el.css('background-image')

      if (bg.indexOf(tempUrl) !== -1) {
        $el.css('background-image', `url('${url}')`)
        $el.removeClass('folio-thumbnail-background')
      }
    })

    $(`[data-lightbox-src='${tempUrl}']`)
      .attr('data-lightbox-src', url)
      .attr('data-lightbox-width', data.width)
      .attr('data-lightbox-height', data.height)
  })
}
