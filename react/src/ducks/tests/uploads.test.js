import uploadsReducer, {
  initialState,
  addedFile,
  thumbnail,
  finishedUpload,
  error,
  progress,
  setUploadTags,
  clearUploadedIds,
  defaultTag
} from '../uploads'

describe('uploadsReducer', () => {
  let state
  const fileMock = { name: 'foo.jpg', lastModified: 1, size: 1, type: 'foo/bar' }

  beforeEach(() => {
    state = uploadsReducer(initialState, addedFile('images', fileMock))
  })

  it('addedFile', () => {
    expect(state['images'].records['foo.jpg|1|1']).not.toEqual(undefined)
  })

  it('thumbnail', () => {
    expect(state['images'].records['foo.jpg|1|1'].attributes.thumb).toEqual(null)
    state = uploadsReducer(state, thumbnail('images', fileMock, 'foo'))
    expect(state['images'].records['foo.jpg|1|1'].attributes.thumb).toEqual('foo')
  })

  it('finishedUpload', () => {
    expect(state['images'].showTagger).toEqual(false)
    expect(state['images'].records['foo.jpg|1|1']).not.toEqual(undefined)
    expect(state['images'].uploadedIds).toEqual([])
    state = uploadsReducer(state, finishedUpload('images', fileMock, 999))
    expect(state['images'].showTagger).toEqual(true)
    expect(state['images'].records['foo.jpg|1|1']).toEqual(undefined)
    expect(state['images'].uploadedIds).toEqual([999])
  })

  it('error', () => {
    expect(state['images'].records['foo.jpg|1|1']).not.toEqual(undefined)
    state = uploadsReducer(state, error('images', fileMock, 'ooops'))
    expect(state['images'].records['foo.jpg|1|1']).toEqual(undefined)
  })

  it('progress', () => {
    expect(state['images'].records['foo.jpg|1|1'].attributes.progress).toEqual(0)
    state = uploadsReducer(state, progress('images', fileMock, 25))
    expect(state['images'].records['foo.jpg|1|1'].attributes.progress).toEqual(25)
  })

  it('setUploadTags', () => {
    expect(state['images'].uploadTags).toEqual([defaultTag])
    state = uploadsReducer(state, setUploadTags('images', ['foo']))
    expect(state['images'].uploadTags).toEqual(['foo'])
    expect(state['images'].showTagger).toEqual(false)
  })

  it('clearUploadedIds', () => {
    state = uploadsReducer(state, finishedUpload('images', fileMock, 999))
    expect(state['images'].uploadedIds).toEqual([999])
    state = uploadsReducer(state, clearUploadedIds('images', [999]))
    expect(state['images'].uploadedIds).toEqual([])
  })
})
