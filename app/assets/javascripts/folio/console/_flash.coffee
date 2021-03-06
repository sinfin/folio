window.FolioConsole ||= {}

window.FolioConsole.flash = (msg, type = 'success') ->
  if type is 'success'
    className = 'alert-success'
    icon = 'fa fa-mr fa-check-circle'
  else
    className = 'alert-danger'
    icon = 'fa fa-mr fa-times-circle'

  $('.f-c-flash-wrap').append("""
    <div class="alert alert-dismissible fade show #{className}" role="alert">
      <button class="close" data-dismiss="alert"><span>&times;</span></button>
      <i class="#{icon}"></i>
      #{msg}
    </div>
  """)

window.FolioConsole.clearFlashes = ->
  $('.f-c-flash-wrap').html('')

window.FolioConsole.flashMessageFromMeta = (response) ->
  if typeof response is 'object' and response.meta and response.meta.flash
    if response.meta.flash.success
      window.FolioConsole.flash response.meta.flash.success
    else if response.meta.flash.alert
      window.FolioConsole.flash response.meta.flash.alert, 'alert'

window.FolioConsole.flashMessageFromApiErrors = (response) ->
  if typeof response is 'object' and response.errors
    flash = response.errors.map (obj) -> "#{obj.title} #{obj.detail}"
    window.FolioConsole.flash flash, 'alert'
