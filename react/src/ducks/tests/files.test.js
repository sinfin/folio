import filesReducer, {
  initialState,
  getFiles,
  getFilesSuccess,
  uploadedFile,
  thumbnailGenerated,
  updatedFiles,
  updateFile,
  updateFileSuccess,
  updateFileFailure
} from '../files'

import { IMAGES } from 'constants/tests/files'

describe('filesReducer', () => {
  let state

  beforeEach(() => {
    state = filesReducer(initialState, getFilesSuccess('images', IMAGES))
  })

  it('getFiles', () => {
    state = filesReducer(initialState, getFiles('images'))
    expect(state.images.loading).toEqual(true)
    expect(state.images.loaded).toEqual(false)
    expect(state.images.records).toEqual([])
  })

  it('getFilesSuccess', () => {
    expect(state.images.loading).toEqual(false)
    expect(state.images.loaded).toEqual(true)
    expect(state.images.records).toEqual(IMAGES)
  })
})
