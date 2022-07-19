//= require folio/input/_framework
//= require intlTelInput

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Phone = {}

window.Folio.Input.Phone.SELECTOR = '.f-input--phone'

window.Folio.Input.Phone.intlTelInputOptions = {
  separateDialCode: true,
  dropdownContainer: document.body,
  autoPlaceholder: 'aggressive'
}

window.Folio.Input.Phone.removeDialCodeIfNeeded = (input) => {
  const dialCode = `+${input.intlTelInput.selectedCountryData.dialCode}`

  if (input.value.indexOf(dialCode) === 0) {
    input.value = input.value.replace(dialCode, '')
    return true
  } else {
    return false
  }
}

window.Folio.Input.Phone.onChange = (e) => {
  const input = e.target
  const dialCode = `+${input.intlTelInput.selectedCountryData.dialCode}`

  let value = input.value.replace(/ /g, '')

  if (value.indexOf(dialCode) === 0) {
    value = value.replace(dialCode, '')
  }

  input.folioInputPhoneHiddenInput.value = `${dialCode} ${value}`
}

window.Folio.Input.Phone.onBlur = (e) => {
  if (window.Folio.Input.Phone.removeDialCodeIfNeeded(e.target)) {
    window.Folio.Input.Phone.onChange(e)
  }
}

window.Folio.Input.Phone.bindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)

  $wrap.find(window.Folio.Input.Phone.SELECTOR).each((i, input) => {
    const hiddenInput = document.createElement('input')
    hiddenInput.type = 'hidden'
    hiddenInput.name = input.name
    hiddenInput.value = input.value

    input.removeAttribute('name')
    input.parentElement.appendChild(hiddenInput)
    input.folioInputPhoneHiddenInput = hiddenInput

    input.addEventListener('change', window.Folio.Input.Phone.onChange)
    input.addEventListener('countrychange', window.Folio.Input.Phone.onChange)
    input.addEventListener('blur', window.Folio.Input.Phone.onBlur)

    input.intlTelInput = window.intlTelInput(input, window.Folio.Input.Phone.intlTelInputOptions)

    window.Folio.Input.Phone.removeDialCodeIfNeeded(input)
  })
}

window.Folio.Input.Phone.unbindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)

  $wrap.find(window.Folio.Input.Phone.SELECTOR).each((i, input) => {
    input.removeEventListener('change', window.Folio.Input.Phone.onChange)
    input.removeEventListener('countrychange', window.Folio.Input.Phone.onChange)
    input.removeEventListener('blur', window.Folio.Input.Phone.onBlur)

    if (input.folioInputPhoneHiddenInput) {
      input.name = input.folioInputPhoneHiddenInput.name
      input.value = input.folioInputPhoneHiddenInput.value
      input.folioInputPhoneHiddenInput.parentElement.removeChild(input.folioInputPhoneHiddenInput)
      input.folioInputPhoneHiddenInput = null
    }

    if (input.intlTelInput) {
      input.intlTelInput.destroy()
      input.intlTelInput = null
    }
  })
}

window.Folio.Input.Framework.bindInputEvents(window.Folio.Input.Phone.bindAll,
                                             window.Folio.Input.Phone.unbindAll)
