window.Folio.Stimulus.register('f-c-current-users-show', class extends window.Stimulus.Controller {
  edit (e) {
    const box = e.target.closest('.f-c-current-users-show__box')
    box.classList.add('f-c-current-users-show__box--active')

    const input = box.querySelector('.form-control')
    if (input) input.focus()
  }

  cancel (e) {
    e.target.closest('.f-c-current-users-show__box').classList.remove('f-c-current-users-show__box--active')
  }
})
