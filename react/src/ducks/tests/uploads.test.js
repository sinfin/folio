import 'folioTestSetup'

import uploadsReducer, {
  initialState,
  addedFile,
  thumbnail,
  error,
  progress,
  setUploadAttributes,
  clearUploadedIds,
  defaultTag,
  setFileS3Data,
  createFileFromS3JobStart,
  createFileFromS3JobSuccess,
  createFileFromS3JobFailure
} from '../uploads'

import { fileMock } from './files.test'

describe('uploadsReducer', () => {
  let state
  const jsFileMock = { name: 'foo.jpg', lastModified: 1, size: 1, type: 'foo/bar' }

  beforeEach(() => {
    state = uploadsReducer(initialState, addedFile('Folio::Image', jsFileMock))
  })

  it('addedFile', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1']).not.toEqual(undefined)
  })

  it('setFileS3Data', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.s3_path).toEqual(undefined)
    state = uploadsReducer(state, setFileS3Data('Folio::Image', jsFileMock, '/foo', 'http://foo/foo'))
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.s3_path).toEqual('/foo')
  })

  it('thumbnail', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.thumb).toEqual(null)
    state = uploadsReducer(state, thumbnail('Folio::Image', jsFileMock, 'foo'))
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.thumb).toEqual('foo')
  })

  it('error', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1']).not.toEqual(undefined)
    state = uploadsReducer(state, error('Folio::Image', jsFileMock, 'ooops'))
    expect(state['Folio::Image'].records['foo.jpg|1|1']).toEqual(undefined)
  })

  it('progress', () => {
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.progress).toEqual(0)
    state = uploadsReducer(state, progress('Folio::Image', jsFileMock, 25))
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.progress).toEqual(25)
  })

  it('setUploadAttributes', () => {
    expect(state['Folio::Image'].uploadAttributes.tags).toEqual([defaultTag])
    state = uploadsReducer(state, setUploadAttributes('Folio::Image', { tags: ['foo'] }))
    expect(state['Folio::Image'].uploadAttributes.tags).toEqual(['foo'])
    expect(state['Folio::Image'].showTagger).toEqual(false)
  })

  it('clearUploadedIds', () => {
    state = uploadsReducer(state, setFileS3Data('Folio::Image', jsFileMock, '/foo', 'http://foo/foo'))
    state = uploadsReducer(state, createFileFromS3JobSuccess('Folio::Image', '/foo', fileMock))
    expect(state['Folio::Image'].uploadedIds).toEqual(['999'])
    state = uploadsReducer(state, clearUploadedIds('Folio::Image', ['999']))
    expect(state['Folio::Image'].uploadedIds).toEqual([])
  })

  it('createFileFromS3JobStart', () => {
    const startedAt = Number(new Date())
    state = uploadsReducer(state, setFileS3Data('Folio::Image', jsFileMock, '/foo', 'http://foo/foo'))
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.s3_job).toBe(undefined)
    state = uploadsReducer(state, createFileFromS3JobStart('Folio::Image', '/foo', startedAt))
    expect(state['Folio::Image'].records['foo.jpg|1|1'].attributes.s3_job).toEqual({ startedAt })
  })

  it('createFileFromS3JobSuccess', () => {
    state = uploadsReducer(state, setFileS3Data('Folio::Image', jsFileMock, '/foo', 'http://foo/foo'))
    expect(state['Folio::Image'].showTagger).toEqual(false)
    expect(state['Folio::Image'].records['foo.jpg|1|1']).not.toEqual(undefined)
    expect(state['Folio::Image'].uploadedIds).toEqual([])
    state = uploadsReducer(state, createFileFromS3JobSuccess('Folio::Image', '/foo', fileMock))
    expect(state['Folio::Image'].showTagger).toEqual(true)
    expect(state['Folio::Image'].records['foo.jpg|1|1']).toEqual(undefined)
    expect(state['Folio::Image'].uploadedIds).toEqual(['999'])
  })

  it('createFileFromS3JobFailure', () => {
    state = uploadsReducer(state, setFileS3Data('Folio::Image', jsFileMock, '/foo', 'http://foo/foo'))
    state = uploadsReducer(state, createFileFromS3JobFailure('Folio::Image', '/foo', ['foo', 'bar']))
    expect(state['Folio::Image'].showTagger).toEqual(false)
    expect(state['Folio::Image'].records['foo.jpg|1|1']).toEqual(undefined)
    expect(state['Folio::Image'].uploadedIds).toEqual([])
  })
})
