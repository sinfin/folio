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
  thumbnailDropzoneFile,
  UPLOAD_STATE_UPLOADING_TO_S3,
  UPLOAD_STATE_UPLOADED_TO_S3,
  UPLOAD_STATE_PROCESSING,
  UPLOAD_STATE_SAVED,
  UPLOAD_STATE_FAILED
} from '../uploads'

describe('uploadsReducer', () => {
  let state
  const S3_PATH = '/file/s3_path'

  beforeEach(() => {
    state = { 'Folio::File::Image': { ...defaultUploadsKeyState } }
  })

  it('exports upload state constants', () => {
    expect(UPLOAD_STATE_UPLOADING_TO_S3).toEqual('uploading_to_s3')
    expect(UPLOAD_STATE_UPLOADED_TO_S3).toEqual('uploaded_to_s3')
    expect(UPLOAD_STATE_PROCESSING).toEqual('processing')
    expect(UPLOAD_STATE_SAVED).toEqual('saved')
    expect(UPLOAD_STATE_FAILED).toEqual('failed')
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
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({
      [S3_PATH]: {
        attributes: {
          progress: 0,
          uploadState: UPLOAD_STATE_UPLOADING_TO_S3
        }
      }
    })
  })

  it('addDropzoneFile starts with uploading_to_s3 state', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH, { file_name: 'april.jpg' }))

    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes).toEqual({
      file_name: 'april.jpg',
      progress: 0,
      uploadState: UPLOAD_STATE_UPLOADING_TO_S3
    })
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes).toHaveProperty('uploadState')
  })

  it('updateDropzoneFile', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.progress).toEqual(0)

    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, { progress: 33 }))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes).toEqual({
      progress: 33,
      uploadState: UPLOAD_STATE_UPLOADING_TO_S3
    })
  })

  it('updateDropzoneFile stores explicit upload states', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, {
      progress: 100,
      progressText: 'Uploaded to S3',
      uploadState: UPLOAD_STATE_UPLOADED_TO_S3
    }))

    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes).toEqual({
      progress: 100,
      progressText: 'Uploaded to S3',
      uploadState: UPLOAD_STATE_UPLOADED_TO_S3
    })

    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, {
      progressText: 'Processing',
      uploadState: UPLOAD_STATE_PROCESSING
    }))

    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.uploadState).toEqual(UPLOAD_STATE_PROCESSING)
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.progressText).toEqual('Processing')
  })

  it('can mark upload as saved or failed before removing it', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))

    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, {
      progress: 100,
      progressText: 'Saved',
      uploadState: UPLOAD_STATE_SAVED
    }))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.uploadState).toEqual(UPLOAD_STATE_SAVED)

    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, {
      progressText: 'Failed',
      uploadState: UPLOAD_STATE_FAILED
    }))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.uploadState).toEqual(UPLOAD_STATE_FAILED)
  })

  it('does not downgrade terminal upload states to intermediate states', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, {
      progress: 100,
      progressText: 'Saved',
      uploadState: UPLOAD_STATE_SAVED
    }))

    state = uploadsReducer(state, updateDropzoneFile('Folio::File::Image', S3_PATH, {
      progressText: 'Processing',
      uploadState: UPLOAD_STATE_PROCESSING
    }))

    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.uploadState).toEqual(UPLOAD_STATE_SAVED)
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.progressText).toEqual('Saved')
  })

  it('removeDropzoneFile', () => {
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({})
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({
      [S3_PATH]: {
        attributes: {
          progress: 0,
          uploadState: UPLOAD_STATE_UPLOADING_TO_S3
        }
      }
    })

    state = uploadsReducer(state, removeDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({})
  })

  it('thumbnailDropzoneFile', () => {
    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes.dataThumbnail).toEqual(undefined)

    state = uploadsReducer(state, thumbnailDropzoneFile('Folio::File::Image', S3_PATH, 'foo'))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH].attributes).toEqual({
      dataThumbnail: 'foo',
      progress: 0,
      uploadState: UPLOAD_STATE_UPLOADING_TO_S3
    })
  })

  it('pending thumbnailDropzoneFile', () => {
    state = uploadsReducer(state, thumbnailDropzoneFile('Folio::File::Image', S3_PATH, 'foo'))
    expect(state['Folio::File::Image'].dropzoneFiles[S3_PATH]).toEqual(undefined)
    expect(state['Folio::File::Image'].pendingDataThumbnails[S3_PATH]).toEqual('foo')

    state = uploadsReducer(state, addDropzoneFile('Folio::File::Image', S3_PATH))
    expect(state['Folio::File::Image'].dropzoneFiles).toEqual({
      [S3_PATH]: {
        attributes: {
          progress: 0,
          dataThumbnail: 'foo',
          uploadState: UPLOAD_STATE_UPLOADING_TO_S3
        }
      }
    })
    expect(state['Folio::File::Image'].pendingDataThumbnails[S3_PATH]).toEqual(undefined)
  })
})
