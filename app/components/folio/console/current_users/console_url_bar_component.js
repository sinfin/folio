window.Folio.Stimulus.register('f-c-current-users-console-url-bar', class extends window.Stimulus.Controller {
  static values = {
    takeoverApiUrl: String,
    deleteRevisionUrl: String,
    fromUserId: Number,
    recordId: Number,
    recordType: String,
    variant: String
  }

  connect () {
    this.boundOnPresencePing = (e) => this.onPresencePing(e)
    window.addEventListener('folio:console:presence-ping', this.boundOnPresencePing)
  }

  disconnect () {
    window.removeEventListener('folio:console:presence-ping', this.boundOnPresencePing)
  }

  // the heartbeat lives in f-c-current-users-presence-ping (rendered separately
  // so it runs even for a lone editor); here we only react to its broadcast
  onPresencePing (e) {
    // hide the warning once the other user is no longer editing the url -
    // only for the plain presence variant, revision-based variants
    // (takeover, outdated) depend on more than the other user's presence
    if (this.variantValue !== 'other_user') return

    const data = e.detail
    if (!data || data.other_user_at_url !== false) return

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
