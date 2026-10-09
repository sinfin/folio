(() => {
  window.Folio = window.Folio || {}
  window.Folio.Ai = window.Folio.Ai || {}

  window.Folio.Ai.asyncJobRequest = ({ timeoutMs = () => 0, onTimeout = () => {} } = {}) => ({
    timeoutMs,
    onTimeout,
    requestSequence: 0,
    requestTimeoutId: null,
    requestTimedOut: false,
    pendingRequestId: null,
    cancelledRequestIds: new Set(),
    messages: {},
    abortController: null,
    active: false,

    post ({ url, body, onResponse = () => {}, onError = () => {}, onFinally = () => {} }) {
      this.abort()

      const requestId = this.nextRequestId()

      this.abortController = new AbortController()
      this.active = true
      this.requestTimedOut = false
      this.setRequestTimeout(requestId)

      window.Folio.Api.apiPost(url, body, this.abortController.signal)
        .then((response) => {
          if (this.staleRequest(requestId)) return

          this.pendingRequestId = response.meta?.request_id || null

          onResponse(response, {
            pending: !!this.pendingRequestId,
            applyBufferedMessage: (callback) => this.applyBufferedMessage(callback)
          })
        })
        .catch((error) => {
          if (this.staleRequest(requestId)) return

          if (error.name === 'AbortError') {
            if (this.requestTimedOut) this.onTimeout()
            return
          }

          onError(error)
        })
        .finally(() => {
          if (this.staleRequest(requestId)) return

          this.abortController = null
          onFinally({ pending: !!this.pendingRequestId })
        })
    },

    receiveMessage (message, onMessage) {
      if (!this.active || !message?.data?.request_id) return false

      const requestId = message.data.request_id

      if (this.cancelledRequestIds.delete(requestId)) return true

      if (!this.pendingRequestId) {
        this.messages[requestId] = message
        return true
      }

      if (requestId !== this.pendingRequestId) return false

      onMessage(message)
      return true
    },

    applyBufferedMessage (onMessage) {
      if (!this.pendingRequestId) return false

      const message = this.messages[this.pendingRequestId]
      if (!message) return false

      delete this.messages[this.pendingRequestId]
      onMessage(message)
      return true
    },

    finish () {
      this.clearRequestTimeout()
      this.requestTimedOut = false
      this.pendingRequestId = null
      this.messages = {}
      this.active = false
    },

    abort ({ advance = true } = {}) {
      if (advance) this.requestSequence += 1

      this.cancelPendingRequest()
      this.clearRequestTimeout()
      this.requestTimedOut = false
      this.pendingRequestId = null
      this.messages = {}
      this.active = false

      if (!this.abortController) return

      this.abortController.abort()
      this.abortController = null
    },

    cancelPendingRequest () {
      if (!this.pendingRequestId) return

      this.cancelledRequestIds.add(this.pendingRequestId)
    },

    setRequestTimeout (requestId) {
      const wait = this.timeoutMs()
      if (wait <= 0) return

      this.requestTimeoutId = window.setTimeout(() => {
        if (this.staleRequest(requestId)) return

        this.requestTimedOut = true

        if (this.abortController) {
          this.abortController.abort()
          return
        }

        this.pendingRequestId = null
        this.onTimeout()
      }, wait)
    },

    clearRequestTimeout () {
      if (!this.requestTimeoutId) return

      window.clearTimeout(this.requestTimeoutId)
      this.requestTimeoutId = null
    },

    nextRequestId () {
      this.requestSequence += 1
      return this.requestSequence
    },

    staleRequest (requestId) {
      return requestId !== this.requestSequence
    }
  })
})()
