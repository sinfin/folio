import uploadsReducer, {
  initialState,
  addedFile,
  thumbnail,
  finishedUpload,
  error,
  progress,
  setUploadAttributes,
  clearUploadedIds,
  defaultTag
} from '../uploads'

describe('uploadsReducer', () => {
  let state
  const fileMock = { name: 'foo.jpg', lastModified: 1, size: 1, type: 'foo/bar' }

  beforeEach(() => {
    state = uploadsReducer(initialState, addedFile('Folio::Image', fileMock))
  })

  it('addedFile', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1']).not.toEqual(undefined)
  })

  it('thumbnail', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.thumb).toEqual(null)
    state = uploadsReducer(state, thumbnail('Folio::Image', fileMock, 'foo'))
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.thumb).toEqual('foo')
  })

  it('finishedUpload', () => {
    expect(state['Folio::Image'].showTagger).toEqual(false)
    expect(state['Folio::Image'].records['foo.jpg|1|1']).not.toEqual(undefined)
    expect(state['Folio::Image'].uploadedIds).toEqual([])
    state = uploadsReducer(state, finishedUpload('Folio::Image', fileMock, 999))
    expect(state['Folio::Image'].showTagger).toEqual(true)
    expect(state['Folio::Image'].records['foo.jpg|1|1']).toEqual(undefined)
    expect(state['Folio::Image'].uploadedIds).toEqual([999])
  })

  it('error', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1']).not.toEqual(undefined)
    state = uploadsReducer(state, error('Folio::Image', fileMock, 'ooops'))
    expect(state['Folio::Image'].records['foo.jpg|1|1']).toEqual(undefined)
  })

  it('progress', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.progress).toEqual(0)
    state = uploadsReducer(state, progress('Folio::Image', fileMock, 25))
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.progress).toEqual(25)
  })

  it('setUploadAttributes', () => {
    expect(state['Folio::Image'].uploadAttributes.tags).toEqual([defaultTag])
    state = uploadsReducer(state, setUploadAttributes('Folio::Image', { tags: ['foo'] }))
    expect(state['Folio::Image'].uploadAttributes.tags).toEqual(['foo'])
    expect(state['Folio::Image'].showTagger).toEqual(false)
  })

  it('clearUploadedIds', () => {
    state = uploadsReducer(state, finishedUpload('Folio::Image', fileMock, 999))
    expect(state['Folio::Image'].uploadedIds).toEqual([999])
    state = uploadsReducer(state, clearUploadedIds('Folio::Image', [999]))
    expect(state['Folio::Image'].uploadedIds).toEqual([])
  })
})
