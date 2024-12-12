window.Folio.Stimulus.register('f-atoms-flash-trigger-for-broken', class extends window.Stimulus.Controller {
  static values = {
    applicationNamespace: String,
    message: String,
  }

  connect () {
    if (!window[this.applicationNamespaceValue]) return
    if (!window[this.applicationNamespaceValue]["Ui"]) return
    if (!window[this.applicationNamespaceValue]["Ui"]["Flash"]) return
    if (!window[this.applicationNamespaceValue]["Ui"]["Flash"]["alert"]) return

    window[this.applicationNamespaceValue]["Ui"]["Flash"]["alert"].call(window, this.messageValue)
  }
})
