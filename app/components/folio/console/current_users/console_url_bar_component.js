window.Folio.Stimulus.register('f-c-current-users-console-url-bar', class extends window.Stimulus.Controller {
  static values = {
    apiUrl: String,
    takeoverApiUrl: String,
    deleteRevisionUrl: String,
    fromUserId: Number,
    recordId: Number,
    recordType: String,
    variant: String
  }

  connect () {
    this.startUrlPinging()
  }

  disconnect () {
    this.stopUrlPinging()
  }

  startUrlPinging () {
    this.urlPingInterval = setInterval(() => {
      this.pingUrl()
    }, 10000)
  }

  stopUrlPinging () {
    if (this.urlPingInterval) {
      clearInterval(this.urlPingInterval)
      this.urlPingInterval = null
    }
  }

  pingUrl () {
    const currentUrl = window.location.href.split('?')[0]
    if (this.apiUrlValue !== 'dont_ping') {
      window.Folio.Api.apiPost(this.apiUrlValue, { url: currentUrl }).then((res) => {
        this.onPingResponse(res)
      }).catch(() => {})
    }
  }

  onPingResponse (res) {
    // hide the warning once the other user is no longer editing the url -
    // only for the plain presence variant, revision-based variants
    // (takeover, outdated) depend on more than the other user's presence
    if (this.variantValue !== 'other_user') return
    if (!res || !res.data || res.data.other_user_at_url !== false) return

    this.element.remove()
  }

  onTakeoverButtonClick () {
    const data = {
      from_user_id: this.fromUserIdValue,
      placement: {
        type: this.recordTypeValue,
        id: this.recordIdValue
      }
    }
    window.Folio.Api.apiPost(this.takeoverApiUrlValue, data).then(() => {
      window.location.reload()
    }).catch((err) => {
      console.error('Takeover failed:', err)
    })
  }

  onOutdatedContinueButtonClick () {
    const data = {
      placement: {
        type: this.recordTypeValue,
        id: this.recordIdValue
      }
    }

    window.Folio.Api.apiDelete(this.deleteRevisionUrlValue, data).then(() => {
      window.location.reload()
    }).catch((err) => {
      console.error('Delete revision failed:', err)
    })
  }
})
