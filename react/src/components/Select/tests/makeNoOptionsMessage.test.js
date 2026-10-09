import 'folioTestSetup'

import makeNoOptionsMessage from '../makeNoOptionsMessage'

describe('makeNoOptionsMessage', () => {
  beforeEach(() => {
    document.documentElement.lang = 'en'
    window.FolioConsole = {
      translations: {
        noResults: 'No results',
        used: 'Used already'
      }
    }
  })

  it('returns inputTooShort message for short non-blank input', () => {
    expect(makeNoOptionsMessage(null, 3)({ inputValue: 'a' })).toEqual('Type at least 3 characters.')
  })

  it('allows blank input with minimum input length', () => {
    expect(makeNoOptionsMessage(null, 3)({ inputValue: '' })).toEqual('No results')
  })

  it('localizes the inputTooShort message', () => {
    document.documentElement.lang = 'cs'

    expect(makeNoOptionsMessage(null, 3)({ inputValue: 'ab' })).toEqual('Zadejte alespoň 3 znaky.')
  })

  it('keeps used option message for existing options', () => {
    expect(makeNoOptionsMessage(['foo'])({ inputValue: 'foo' })).toEqual('Used already')
  })
})
