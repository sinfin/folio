$(document)
  .on('click', '.f-js-devise-omniauth-forms-trigger', (e) => {
    e.preventDefault()
    $(`.f-devise-omniauth-forms__button[data-provider="${e.currentTarget.dataset.provider}"]`).click()
  })
