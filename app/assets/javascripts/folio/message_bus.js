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

// -1 receives new messages only and gets an initial /__status message with
// the current channel id, which message-bus handles internally.
window.Folio.MessageBus.lastId = -1

window.Folio.MessageBus.handleMessage = (msg, globalMsgId, msgId) => {
  window.Folio.MessageBus.lastId = msgId

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
