//= require slideout

window.Folio.Stimulus.register('f-c-layout-sidebar', class extends window.Stimulus.Controller {
  connect () {
    this.slideout = new window.Slideout({
      panel: document.getElementById('f-c-layout-main'),
      menu: this.element,
      padding: 220,
      tolerance: 70
    })

    this.boundToggle = this.toggle.bind(this)

    this.toggles = document.querySelectorAll('.f-c-js-sidebar-toggle')

    for (let i = 0; i < this.toggles.length; i += 1) {
      this.toggles[i].addEventListener('click', this.boundToggle)
    }
  }

  disconnect () {
    if (this.slideout) {
      this.slideout.destroy()
      this.slideout = null
    }

    for (let i = 0; i < this.toggles.length; i += 1) {
      this.toggles[i].removeEventListener('click', this.boundToggle)
    }

    this.toggles = null

    this.boundToggle = null
  }

  toggle (e) {
    e.preventDefault()
    this.slideout.toggle()
  }

  onTitleClick (e) {
    e.preventDefault()

    const $group = $(e.currentTarget).closest('.f-c-layout-sidebar__group')

    $group
      .siblings('.f-c-layout-sidebar__group--expanded')
      .addClass('f-c-layout-sidebar__group--collapsed')
      .removeClass('f-c-layout-sidebar__group--expanded')

    if ($group.hasClass('f-c-layout-sidebar__group--expanded')) {
      $group
        .addClass('f-c-layout-sidebar__group--collapsed')
        .removeClass('f-c-layout-sidebar__group--expanded')
    } else {
      $group
        .addClass('f-c-layout-sidebar__group--expanded')
        .removeClass('f-c-layout-sidebar__group--collapsed')
    }
  }
})
