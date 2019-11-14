sidebar = document.getElementById('f-c-layout-sidebar')

if sidebar
  slideout = new Slideout
    panel: document.getElementById('f-c-layout-main')
    menu: sidebar
    padding: 220
    tolerance: 70

  $(document).on 'click', '.f-c-js-sidebar-toggle', (e) ->
    e.preventDefault()
    slideout.toggle()
