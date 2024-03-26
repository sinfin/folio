//= require folio/is_visible
//= require folio/debounce

window.Folio.Stimulus.register('d-ui-menu', class extends window.Stimulus.Controller {
  static targets = ['mq', 'moreLi', 'moreUl']

  static values = {
    id: Number,
    updatedAt: Number
  }

  connect () {
    this.handleOverflow()

    this.boundDebouncedOnResize = window.Folio.debounce(() => { this.handleOverflow() })

    window.addEventListener('resize', this.boundDebouncedOnResize)
    window.addEventListener('orientationchange', this.boundDebouncedOnResize)
  }

  disconnect () {
    window.removeEventListener('resize', this.boundDebouncedOnResize)
    window.removeEventListener('orientationchange', this.boundDebouncedOnResize)

    delete this.boundDebouncedOnResize
  }

  onExpandableClick (e) {
    e.preventDefault()
    e.currentTarget.closest('.d-ui-menu__li').classList.toggle('d-ui-menu__li--expanded')
  }

  handleOverflow () {
    const isDesktop = window.Folio.isVisible(this.mqTarget)

    if (!isDesktop) return

    this.moreLiTarget.hidden = false
    const width = this.element.clientWidth
    const moreLiWidth = this.moreLiTarget.clientWidth
    const limit = width - moreLiWidth

    this.moreUlTarget.innerHTML = ''
    const allLi = this.element.querySelectorAll('.d-ui-menu__li:not(.d-ui-menu__li--more)')
    const allLiLength = allLi.length

    const toCollapse = []

    const menuLeft = this.element.getBoundingClientRect().left
    let hiddenAny = false

    for (let i = 0; i < allLiLength; i++) {
      const li = allLi[i]

      if (li.classList.contains('d-ui-menu__li--collapsed')) {
        li.classList.remove('d-ui-menu__li--collapsed')
      }

      const rect = li.getBoundingClientRect()
      const endsAt = rect.left + rect.width - menuLeft

      if (hiddenAny || endsAt > limit) {
        if (!hiddenAny && (i === allLiLength - 1 && endsAt <= width && toCollapse.length === 0)) {
          // last one fits, no need to respect moreLiWidth
        } else {
          hiddenAny = true

          const clone = li.cloneNode(true)

          if (clone.querySelectorAll('a').length < 4) {
            clone.classList.add('d-ui-menu__li--expanded')
          }

          this.moreUlTarget.appendChild(clone)
          toCollapse.push(li)
        }
      }
    }

    toCollapse.forEach((li) => {
      li.classList.add('d-ui-menu__li--collapsed')
    })

    this.moreLiTarget.hidden = toCollapse.length === 0

    this.element.classList.add('d-ui-menu--bound')

    const key = `d-ui-menu--${this.idValue}`
    const item = window.localStorage.getItem(key)
    const fullHash = item ? JSON.parse(item) : {}

    const hash = {}
    hash[this.updatedAtValue] = fullHash[this.updatedAtValue] || {}
    hash[this.updatedAtValue][window.innerWidth] = toCollapse.length

    window.localStorage.setItem(key, JSON.stringify(hash))
  }
})
