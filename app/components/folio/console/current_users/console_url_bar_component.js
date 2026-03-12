window.Folio.Stimulus.register('f-c-current-users-console-url-bar', class extends window.Stimulus.Controller {
  static values = {
    apiUrl: String,
    takeoverApiUrl: String,
    deleteRevisionUrl: String,
    fromUserId: Number,
    recordId: Number,
    recordType: String
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
    if (this.apiUrlValue != "dont_ping") {
      const data = {
        url: currentUrl,
        record_type: this.recordTypeValue,
        record_id: this.recordIdValue
      }
      window.Folio.Api.apiPost(this.apiUrlValue, data).then((response) => {
        console.log(response)
      }).catch((err) => {
        console.error('Ping failed:', err)
      })
    }
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
