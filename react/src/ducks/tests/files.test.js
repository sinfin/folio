import filesReducer, {
  initialState,
  getFiles,
  getFilesSuccess,
  uploadedFile,
  thumbnailGenerated,
  updatedFiles,
  updateFile,
  updateFileSuccess,
  updateFileFailure,
  deleteFile,
  deleteFileFailure,
  removedFiles
} from '../files'

import { IMAGES } from 'constants/tests/files'
const fileMock = { id: '999', type: 'file', attributes: { id: 999, file_size: 326774, file_name: 'bar.jpg', type: 'Folio::Image', thumb: 'foo/bar.jpg', source_url: 'foo/bar.jpg', url: '/foo/bar.jpg', dominant_color: '#2F312F', tags: [], placements: [], extension: 'JPEG' }, links: { edit: '/console/images/999/edit' } }
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
    state = filesReducer(initialState, getFilesSuccess('images', IMAGES, pagination))
  })

  it('getFiles', () => {
    state = filesReducer(initialState, getFiles('images'))
    expect(state['images'].loading).toEqual(true)
    expect(state['images'].loaded).toEqual(false)
    expect(state['images'].records).toEqual([])
  })

  it('getFilesSuccess', () => {
    expect(state['images'].loading).toEqual(false)
    expect(state['images'].loaded).toEqual(true)
    expect(state['images'].records).toEqual(IMAGES)
  })

  it('uploadedFile', () => {
    expect(state['images'].records.length).toEqual(3)
    state = filesReducer(state, uploadedFile('images', fileMock))
    expect(state['images'].records.length).toEqual(4)
  })

  it('thumbnailGenerated', () => {
    expect(state['images'].records[0].attributes.thumb).toEqual(firstThumb)
    state = filesReducer(state, thumbnailGenerated('images', firstThumb, '/foo.jpg'))
    expect(state['images'].records[0].attributes.thumb).toEqual('/foo.jpg')
  })

  it('updatedFiles', () => {
    expect(state['images'].records[0].attributes.thumb).toEqual(firstThumb)
    const records = [{
      ...IMAGES[0],
      attributes: {
        ...IMAGES[0].attributes,
        thumb: '/foo.jpg'
      }
    }]
    state = filesReducer(state, updatedFiles('images', records))
    expect(state['images'].records[0].attributes.thumb).toEqual('/foo.jpg')
  })

  it('updateFile', () => {
    expect(state['images'].records[0].attributes.updating).toEqual(undefined)
    expect(state['images'].records[0].attributes.tags).toEqual([])
    state = filesReducer(state, updateFile('images', state['images'].records[0], { tags: ['foo'] }))
    expect(state['images'].records[0].attributes.updating).toEqual(true)
    expect(state['images'].records[0].attributes.tags).toEqual(['foo'])
  })

  it('updateFile', () => {
    expect(state['images'].records[0].attributes.updating).toEqual(undefined)
    expect(state['images'].records[0].attributes.tags).toEqual([])
    state = filesReducer(state, updateFile('images', state['images'].records[0], { tags: ['foo'] }))
    expect(state['images'].records[0].attributes.updating).toEqual(true)
    expect(state['images'].records[0].attributes.tags).toEqual(['foo'])
  })

  it('updateFileSuccess', () => {
    state = filesReducer(state, updateFile('images', state['images'].records[0], { thumb: '/foo.jpg' }))
    const response = {
      ...IMAGES[0],
      attributes: {
        ...IMAGES[0].attributes,
        thumb: '/foo.jpg'
      }
    }
    state = filesReducer(state, updateFileSuccess('images', state['images'].records[0], response))
    expect(state['images'].records[0].attributes.updating).toEqual(undefined)
    expect(state['images'].records[0].attributes.thumb).toEqual('/foo.jpg')
  })

  it('updateFileFailure', () => {
    const image = state['images'].records[0]
    state = filesReducer(state, updateFile('images', image, { thumb: '/foo.jpg' }))
    expect(state['images'].records[0].attributes.thumb).toEqual('/foo.jpg')
    state = filesReducer(state, updateFileFailure('images', image))
    expect(state['images'].records[0].attributes.thumb).not.toEqual('/foo.jpg')
  })

  it('deleteFile', () => {
    const image = state['images'].records[0]
    state = filesReducer(state, deleteFile('images', image))
    expect(state['images'].records[0]._destroying).toEqual(true)
    state = filesReducer(state, deleteFileFailure('images', image))
    expect(state['images'].records[0]._destroying).toEqual(undefined)
    expect(state['images'].records[0].id).toEqual(image.id)
    state = filesReducer(state, removedFiles('images', [image.id]))
    expect(state['images'].records[0].id).not.toEqual(image.id)
  })
})
