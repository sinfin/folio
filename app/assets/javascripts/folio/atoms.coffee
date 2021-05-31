if Turbolinks?
  loadEvent = "turbolinks:load"
  unloadEvent = "turbolinks:before-render"
else
  loadEvent = "folioConsoleReplacedHtml"
  unloadEvent = "folioConsoleWillReplaceHtml"

$(document)
  .on(loadEvent, -> $(this).trigger("folioAtomLoad"))
  .on(unloadEvent, -> $(this).trigger("folioAtomUnload"))
