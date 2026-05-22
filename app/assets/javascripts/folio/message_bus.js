//= require message-bus
//= require message-bus-ajax

window.Folio = window.Folio || {}
window.Folio.MessageBus = {}

// respect lib/folio.rb
window.Folio.MessageBus.channel = 'folio_messagebus_channel'
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

// Cross-page continuity: a page redirecting to another page can append
// ?folio_mb_last_id=<id> to the URL with the current lastId snapshot, so the
// new page's subscription picks up exactly where the old page left off — no
// messages lost during the navigation gap, no bootstrap drop needed.
const folioMbLastIdParam = new URLSearchParams(window.location.search).get('folio_mb_last_id')
const folioMbLastIdParsed = folioMbLastIdParam === null ? NaN : parseInt(folioMbLastIdParam, 10)
const folioMbHasExplicitLastId = Number.isInteger(folioMbLastIdParsed) && folioMbLastIdParsed >= 0

// -2 will recieve last message + all new messages
//   -> we want the last message to receive last id in case we go offline before first messages arrives
window.Folio.MessageBus.onlyGetMessageIdForFirstMessage = !folioMbHasExplicitLastId
// disable after 5 seconds in the rare case of no messages in redis
if (!folioMbHasExplicitLastId) {
  setTimeout(() => { window.Folio.MessageBus.onlyGetMessageIdForFirstMessage = false }, 5000)
}

window.Folio.MessageBus.lastId = folioMbHasExplicitLastId ? folioMbLastIdParsed : -2

window.Folio.MessageBus.handleMessage = (msg, globalMsgId, msgId) => {
  window.Folio.MessageBus.lastId = msgId

  if (window.Folio.MessageBus.onlyGetMessageIdForFirstMessage) {
    window.Folio.MessageBus.onlyGetMessageIdForFirstMessage = false
    return
  }

  const data = JSON.parse(msg)

  if (!data) return

  if (window.Folio.MessageBus.debug) {
    console.group('[Folio] [MessageBus] handleMessage')
    console.log(msgId)
    console.log(data)
    console.groupEnd()
  }

  Object.values(window.Folio.MessageBus.callbacks).forEach((callback) => { callback(data) })
}

window.MessageBus.subscribe(
  window.Folio.MessageBus.channel,
  window.Folio.MessageBus.handleMessage,
  window.Folio.MessageBus.lastId
)
