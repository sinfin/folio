(() => {
  window.Folio = window.Folio || {}
  window.Folio.Ai = window.Folio.Ai || {}

  const addSnapshotValue = (snapshot, key, value) => {
    if (Object.prototype.hasOwnProperty.call(snapshot, key)) {
      snapshot[key] = Array.isArray(snapshot[key])
        ? [...snapshot[key], value]
        : [snapshot[key], value]
    } else {
      snapshot[key] = value
    }
  }

  const errorDetail = (responseData) => {
    if (!responseData.errors || responseData.errors.length === 0) return null

    return responseData.errors[0].detail || responseData.errors[0].title
  }

  window.Folio.Ai.cssEscape = (value) => {
    value = value.toString()

    if (window.CSS?.escape) return window.CSS.escape(value)

    return value.replace(/["\\]/g, '\\$&')
  }

  window.Folio.Ai.formSnapshot = (form) => {
    if (!form) return {}

    const snapshot = {}
    const formData = new FormData(form)

    formData.forEach((value, key) => {
      if (value instanceof File) return

      addSnapshotValue(snapshot, key, value.toString())
    })

    return snapshot
  }

  window.Folio.Ai.errorMessage = (error, fallback) => {
    const responseData = error?.responseData || {}
    const detail = responseData.message || errorDetail(responseData)

    return detail || error?.message || fallback
  }

  window.Folio.Ai.timeoutErrorText = (controller, fallback) => {
    if (controller?.hasRequestTimeoutTextValue && controller.requestTimeoutTextValue) {
      return controller.requestTimeoutTextValue
    }

    return fallback
  }

  window.Folio.Ai.AsyncJobRequest = class {
    constructor ({ timeoutMs = () => 0, onTimeout = () => {} } = {}) {
      this.timeoutMs = timeoutMs
      this.onTimeout = onTimeout
      this.requestSequence = 0
      this.requestTimeoutId = null
      this.requestTimedOut = false
      this.pendingRequestId = null
      this.cancelledRequestIds = new Set()
      this.messages = {}
      this.abortController = null
      this.active = false
    }

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
    }

    receiveMessage (message, onMessage) {
      if (!this.active) return false
      if (!message?.data?.request_id) return false

      const requestId = message.data.request_id

      if (this.cancelledRequestIds.delete(requestId)) return true

      if (!this.pendingRequestId) {
        this.messages[requestId] = message
        return true
      }

      if (requestId !== this.pendingRequestId) return false

      onMessage(message)
      return true
    }

    applyBufferedMessage (onMessage) {
      if (!this.pendingRequestId) return false

      const message = this.messages[this.pendingRequestId]
      if (!message) return false

      delete this.messages[this.pendingRequestId]
      onMessage(message)
      return true
    }

    finish () {
      this.clearRequestTimeout()
      this.requestTimedOut = false
      this.pendingRequestId = null
      this.messages = {}
      this.active = false
    }

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
    }

    cancelPendingRequest () {
      if (!this.pendingRequestId) return

      this.cancelledRequestIds.add(this.pendingRequestId)
    }

    setRequestTimeout (requestId) {
      const timeoutMs = this.timeoutMs()
      if (timeoutMs <= 0) return

      this.requestTimeoutId = window.setTimeout(() => {
        if (this.staleRequest(requestId)) return

        this.requestTimedOut = true

        if (this.abortController) {
          this.abortController.abort()
          return
        }

        this.pendingRequestId = null
        this.onTimeout()
      }, timeoutMs)
    }

    clearRequestTimeout () {
      if (!this.requestTimeoutId) return

      window.clearTimeout(this.requestTimeoutId)
      this.requestTimeoutId = null
    }

    nextRequestId () {
      this.requestSequence += 1
      return this.requestSequence
    }

    staleRequest (requestId) {
      return requestId !== this.requestSequence
    }
  }
})()
