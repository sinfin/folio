import 'folioTestSetup'

import uploadsReducer, {
  defaultUploadsKeyState,
  defaultTag,
  setUploadAttributes,
  clearUploadedIds,
  showTagger,
  closeTagger,
  addDropzoneFile,
  updateDropzoneFile,
  removeDropzoneFile,
  thumbnailDropzoneFile
} from '../uploads'

describe('uploadsReducer', () => {
  let state
  const S3_PATH = '/file/s3_path'

  beforeEach(() => {
    state = { 'Folio::File::Image': { ...defaultUploadsKeyState } }
  })

  it('setUploadAttributes', () => {
    expect(state['Folio::File::Image'].uploadAttributes.tags).toEqual([defaultTag])
    state = uploadsReducer(state, setUploadAttributes('Folio::File::Image', { tags: ['foo'] }))
    expect(state['Folio::File::Image'].uploadAttributes.tags).toEqual(['foo'])
    expect(state['Folio::File::Image'].showTagger).toEqual(false)
  })

  it('showTagger, clearUploadedIds', () => {
    expect(state['Folio::File::Image'].showTagger).toEqual(false)
    expect(state['Folio::File::Image'].uploadedIds).toEqual([])

    state = uploadsReducer(state, showTagger('Folio::File::Image', '1'))
    expect(state['Folio::File::Image'].showTagger).toEqual(true)
    expect(state['Folio::File::Image'].uploadedIds).toEqual(['1'])

    state = uploadsReducer(state, clearUploadedIds('Folio::File::Image', ['1']))
    expect(state['Folio::File::Image'].uploadedIds).toEqual([])
  })

  it('showTagger, closeTagger', () => {
    expect(state['Folio::File::Image'].showTagger).toEqual(false)
    expect(state['Folio::File::Image'].uploadedIds).toEqual([])

    state = uploadsReducer(state, showTagger('Folio::File::Image', '1'))
    expect(state['Folio::File::Image'].showTagger).toEqual(true)
    expect(state['Folio::File::Image'].uploadedIds).toEqual(['1'])

    state = uploadsReducer(state, closeTagger('Folio::File::Image'))
    expect(state['Folio::File::Image'].showTagger).toEqual(false)
    expect(state['Folio::File::Image'].uploadedIds).toEqual([])
  })

  it('addDropzoneFile', () => {
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({})
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({ [S3_PATH]: { attributes: { progress: 0 } } })
  })

  it('updateDropzoneFile', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.progress).toEqual(0)

    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, { progress: 33 }))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes).toEqual({ progress: 33 })
  })

  it('removeDropzoneFile', () => {
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({})
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({ [S3_PATH]: { attributes: { progress: 0 } } })

    state = uploadsReducer(state, removeDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({})
  })

  it('thumbnailDropzoneFile', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.dataThumbnail).toEqual(undefined)

    state = uploadsReducer(state, thumbnailDropzoneFile('Folio::File::Image', S3_PATH, 'foo'))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes).toEqual({ dataThumbnail: 'foo', progress: 0 })
  })

  it('pending thumbnailDropzoneFile', () => {
    state = uploadsReducer(state, thumbnailDropzoneFile('Folio::File::Image', S3_PATH, 'foo'))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH]).toEqual(undefined)
    expect(state['Folio::File::Image'].pendingDataThumbnails[S3_PATH]).toEqual('foo')

    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({ [S3_PATH]: { attributes: { progress: 0, dataThumbnail: 'foo' } } })
    expect(state['Folio::File::Image'].pendingDataThumbnails[S3_PATH]).toEqual(undefined)
  })
})
