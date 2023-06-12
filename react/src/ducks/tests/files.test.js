import 'folioTestSetup'

import filesReducer, {
  initialState,
  getFiles,
  getFilesSuccess,
  uploadedFile,
  messageBusFileUpdated,
  updatedFiles,
  updateFile,
  updateFileSuccess,
  updateFileFailure,
  deleteFile,
  deleteFileFailure,
  removedFiles
} from '../files'

import { IMAGES } from 'constants/tests/files'

export const fileMock = { id: '999', type: 'file', attributes: { id: 999, file_size: 326774, file_name: 'bar.jpg', type: 'Folio::File::Image', thumb: 'foo/bar.jpg', source_url: 'foo/bar.jpg', url: '/foo/bar.jpg', dominant_color: '#2F312F', tags: [], placements: [], extension: 'JPEG' }, links: { edit: '/console/images/999/edit' } }
const firstThumb = IMAGES[0].attributes.thumb
const pagination = {
  from: 1,
  to: IMAGES.length,
  count: IMAGES.length,
  page: 1,
  pages: 1
}

describe('filesReducer', () => {
  let state

  beforeEach(() => {
    state = filesReducer(initialState, getFilesSuccess('Folio::File::Image', IMAGES, pagination))
  })

  it('getFiles', () => {
    state = filesReducer(initialState, getFiles('Folio::File::Image'))
    expect(state['Folio::File::Image'].loading).toEqual(true)
    expect(state['Folio::File::Image'].loaded).toEqual(false)
    expect(state['Folio::File::Image'].records).toEqual([])
  })

  it('getFilesSuccess', () => {
    expect(state['Folio::File::Image'].loading).toEqual(false)
    expect(state['Folio::File::Image'].loaded).toEqual(true)
    expect(state['Folio::File::Image'].records).toEqual(IMAGES)
  })

  it('uploadedFile', () => {
    expect(state['Folio::File::Image'].records.length).toEqual(3)
    state = filesReducer(state, uploadedFile('Folio::File::Image', fileMock))
    expect(state['Folio::File::Image'].records.length).toEqual(4)
  })

  it('messageBusFileUpdated', () => {
    expect(state['Folio::File::Image'].records[0].attributes.thumb).toEqual(firstThumb)
    state = filesReducer(state, messageBusFileUpdated('Folio::File::Image', '/console/api/images', fileMock))
    expect(state['Folio::File::Image'].records[0].attributes.thumb).toEqual('/system/dragonfly/development/files/2019/08/01/5i4xexj0kb_image_blakecheekk_vcan0gpydtq.jpg')
  })

  it('updatedFiles', () => {
    expect(state['Folio::File::Image'].records[0].attributes.thumb).toEqual(firstThumb)
    const records = [{
      ...IMAGES[0],
      attributes: {
        ...IMAGES[0].attributes,
        thumb: '/foo.jpg'
      }
    }]
    state = filesReducer(state, updatedFiles('Folio::File::Image', records))
    expect(state['Folio::File::Image'].records[0].attributes.thumb).toEqual('/foo.jpg')
  })

  it('updateFile', () => {
    expect(state['Folio::File::Image'].records[0].attributes.updating).toEqual(undefined)
    expect(state['Folio::File::Image'].records[0].attributes.tags).toEqual([])
    state = filesReducer(state, updateFile('Folio::File::Image', '/console/api/images', state['Folio::File::Image'].records[0], { tags: ['foo'] }))
    expect(state['Folio::File::Image'].records[0].attributes.updating).toEqual(true)
    expect(state['Folio::File::Image'].records[0].attributes.tags).toEqual(['foo'])
  })

  it('updateFile', () => {
    expect(state['Folio::File::Image'].records[0].attributes.updating).toEqual(undefined)
    expect(state['Folio::File::Image'].records[0].attributes.tags).toEqual([])
    state = filesReducer(state, updateFile('Folio::File::Image', '/console/api/images', state['Folio::File::Image'].records[0], { tags: ['foo'] }))
    expect(state['Folio::File::Image'].records[0].attributes.updating).toEqual(true)
    expect(state['Folio::File::Image'].records[0].attributes.tags).toEqual(['foo'])
  })

  it('updateFileSuccess', () => {
    state = filesReducer(state, updateFile('Folio::File::Image', '/console/api/images', state['Folio::File::Image'].records[0], { thumb: '/foo.jpg' }))
    const response = {
      ...IMAGES[0],
      attributes: {
        ...IMAGES[0].attributes,
        thumb: '/foo.jpg'
      }
    }
    state = filesReducer(state, updateFileSuccess('Folio::File::Image', state['Folio::File::Image'].records[0], response))
    expect(state['Folio::File::Image'].records[0].attributes.updating).toEqual(undefined)
    expect(state['Folio::File::Image'].records[0].attributes.thumb).toEqual('/foo.jpg')
  })

  it('updateFileFailure', () => {
    const image = state['Folio::File::Image'].records[0]
    state = filesReducer(state, updateFile('Folio::File::Image', '/console/api/images', image, { thumb: '/foo.jpg' }))
    expect(state['Folio::File::Image'].records[0].attributes.thumb).toEqual('/foo.jpg')
    state = filesReducer(state, updateFileFailure('Folio::File::Image', image))
    expect(state['Folio::File::Image'].records[0].attributes.thumb).not.toEqual('/foo.jpg')
  })

  it('deleteFile', () => {
    const image = state['Folio::File::Image'].records[0]
    state = filesReducer(state, deleteFile('Folio::File::Image', '/console/api/images', image))
    expect(state['Folio::File::Image'].records[0]._destroying).toEqual(true)
    state = filesReducer(state, deleteFileFailure('Folio::File::Image', image))
    expect(state['Folio::File::Image'].records[0]._destroying).toEqual(undefined)
    expect(state['Folio::File::Image'].records[0].id).toEqual(image.id)
    state = filesReducer(state, removedFiles('Folio::File::Image', [image.id]))
    expect(state['Folio::File::Image'].records[0].id).not.toEqual(image.id)
  })
})
