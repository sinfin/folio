import 'folioTestSetup'

import uploadsReducer, {
  defaultUploadsKeyState,
  defaultTag,
  setUploadAttributes,
  clearUploadedIds,
  showTagger,
  closeTagger
} from '../uploads'

describe('uploadsReducer', () => {
  let state

  beforeEach(() => {
    state = { 'Folio::Image': { ...defaultUploadsKeyState } }
  })

  it('setUploadAttributes', () => {
    expect(state['Folio::Image'].uploadAttributes.tags).toEqual([defaultTag])
    state = uploadsReducer(state, setUploadAttributes('Folio::Image', { tags: ['foo'] }))
    expect(state['Folio::Image'].uploadAttributes.tags).toEqual(['foo'])
    expect(state['Folio::Image'].showTagger).toEqual(false)
  })

  it('showTagger, clearUploadedIds', () => {
    expect(state['Folio::Image'].showTagger).toEqual(false)
    expect(state['Folio::Image'].uploadedIds).toEqual([])

    state = uploadsReducer(state, showTagger('Folio::Image', '1'))
    expect(state['Folio::Image'].showTagger).toEqual(true)
    expect(state['Folio::Image'].uploadedIds).toEqual(['1'])

    state = uploadsReducer(state, clearUploadedIds('Folio::Image', ['1']))
    expect(state['Folio::Image'].uploadedIds).toEqual([])
  })

  it('showTagger, closeTagger', () => {
    expect(state['Folio::Image'].showTagger).toEqual(false)
    expect(state['Folio::Image'].uploadedIds).toEqual([])

    state = uploadsReducer(state, showTagger('Folio::Image', '1'))
    expect(state['Folio::Image'].showTagger).toEqual(true)
    expect(state['Folio::Image'].uploadedIds).toEqual(['1'])

    state = uploadsReducer(state, closeTagger('Folio::Image'))
    expect(state['Folio::Image'].showTagger).toEqual(false)
    expect(state['Folio::Image'].uploadedIds).toEqual([])
  })
})
