$ ->
  rememberedTab = localStorage.getItem('folioConsoleOpenTab')
  localStorage.removeItem('folioConsoleOpenTab')

  if rememberedTab
    $('.simple_form .nav-link')
      .filter -> @href == rememberedTab
      .click()

$(document).on 'shown.bs.tab', '.simple_form .nav-link', ->
  localStorage.setItem('folioConsoleOpenTab', @href)
