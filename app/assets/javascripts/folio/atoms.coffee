if Turbolinks?
  loadEvent = "turbolinks:load"
  unloadEvent = "turbolinks:before-render"
else
  loadEvent = "folioConsoleReplacedHtml"
  unloadEvent = "folioConsoleWillReplaceHtml"

$(document)
  .on(loadEvent, -> $(document).trigger("folioAtomsLoad"))
  .on(unloadEvent, -> $(document).trigger("folioAtomsUnload"))
