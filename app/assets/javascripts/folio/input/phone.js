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

window.Folio.Input.Phone.onAddressCountryCodeChange = ($wrap, countryCode) => {
  $wrap.find(window.Folio.Input.Phone.SELECTOR).each((i, input) => {
    if (input.value) return

    input.intlTelInput.setCountry(countryCode)
    window.Folio.Input.Phone.onChangeForInput(input)
  })
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

window.Folio.Input.Phone.onChangeForInput = (input) => {
  const dialCode = `+${input.intlTelInput.selectedCountryData.dialCode}`

  let value = input.value.replace(/ /g, '')

  if (value.indexOf(dialCode) === 0) {
    value = value.replace(dialCode, '')
  }

  input.folioInputPhoneHiddenInput.value = `${dialCode} ${value}`
}

window.Folio.Input.Phone.onChange = (e) => {
  window.Folio.Input.Phone.onChangeForInput(e.target)
}

window.Folio.Input.Phone.onBlur = (e) => {
  if (window.Folio.Input.Phone.removeDialCodeIfNeeded(e.target)) {
    window.Folio.Input.Phone.onChange(e)
  }
}

window.Folio.Input.Phone.copyBootstrapValidationClassNames = (input) => {
  if (input.classList.contains("is-invalid")) {
    input.closest('.iti').classList.add('is-invalid')
  }
}

window.Folio.Input.Phone.bind = (input) => {
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

  const fullOpts = $.extend({}, window.Folio.Input.Phone.intlTelInputOptions)
  if (input.dataset.defaultCountryCode) fullOpts.initialCountry = input.dataset.defaultCountryCode

  input.intlTelInput = window.intlTelInput(input, fullOpts)

  window.Folio.Input.Phone.removeDialCodeIfNeeded(input)
  window.Folio.Input.Phone.copyBootstrapValidationClassNames(input)
}

window.Folio.Input.Phone.unbind = (input) => {
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
}

window.Folio.Input.framework(window.Folio.Input.Phone)
