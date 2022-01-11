import { takeLatest, takeEvery, call, select, put } from 'redux-saga/effects'
import { omit, without } from 'lodash'

import { apiPost } from 'utils/api'
import { uploadedFile, updatedFiles } from 'ducks/files'
import { filesUrlSelector } from 'ducks/app'

// Constants

const ADDED_FILE = 'uploads/ADDED_FILE'
const SET_FILE_S3_DATA = 'uploads/SET_FILE_S3_DATA'
const THUMBNAIL = 'uploads/THUMBNAIL'
const SUCCESS = 'uploads/SUCCESS'
const ERROR = 'uploads/ERROR'
const FINISHED_UPLOAD = 'uploads/FINISHED_UPLOAD'
const PROGRESS = 'uploads/PROGRESS'
const SET_UPLOAD_ATTRIBUTES = 'uploads/SET_UPLOAD_ATTRIBUTES'
const CLEAR_UPLOADED_IDS = 'uploads/CLEAR_UPLOADED_IDS'
const CLOSE_TAGGER = 'uploads/CLOSE_TAGGER'

const idFromFile = (file) => {
  return [file.name, file.lastModified, file.size].join('|')
}

// Actions

export function addedFile (fileType, file, dropzone) {
  return { type: ADDED_FILE, fileType, file, dropzone }
}

export function setFileS3Data (fileType, file, s3_path, s3_url) {
  return { type: SET_FILE_S3_DATA, fileType, file, s3_path, s3_url }
}

export function thumbnail (fileType, file, dataUrl) {
  return { type: THUMBNAIL, fileType, file, dataUrl }
}

export function success (fileType, file, response) {
  return { type: SUCCESS, fileType, file, response }
}

export function finishedUpload (fileType, file, uploadedFileId) {
  return { type: FINISHED_UPLOAD, fileType, file, uploadedFileId }
}

export function error (fileType, file) {
  return { type: ERROR, fileType, file }
}

export function progress (fileType, file, percentage) {
  return { type: PROGRESS, fileType, file, percentage }
}

export function setUploadAttributes (fileType, attributes) {
  return { type: SET_UPLOAD_ATTRIBUTES, fileType, attributes }
}

export function clearUploadedIds (fileType, ids) {
  return { type: CLEAR_UPLOADED_IDS, fileType, ids }
}

export function closeTagger (fileType) {
  return { type: CLOSE_TAGGER, fileType }
}

// Sagas

function * addedFileSagaPerform (action) {
  try {
    const filesUrl = yield select(filesUrlSelector)
    const result = yield call(window.FolioConsole.S3Upload.newUpload, { filesUrl, file: action.file })
    yield put(setFileS3Data(action.fileType, action.file, result.s3_path, result.s3_url))
    console.log(result)
    action.dropzone.options.url = result.s3_url
    yield call(action.dropzone.processFile.bind(action.dropzone), action.file)
  } catch (e) {
    window.FolioConsole.Flash.alert(e.message)
  }
}

function * addedFileSaga () {
  yield takeLatest(ADDED_FILE, addedFileSagaPerform)
}

function * uploadedFilePerform (action) {
  const id = idFromFile(action.file)
  const upload = yield select(makeUploadSelector(action.fileType)(id))
  const data = action.response.data
  yield put(finishedUpload(action.fileType, action.file, data.id))
  yield put(uploadedFile(action.fileType, {
    ...data,
    attributes: {
      ...data.attributes,
      thumb: upload.thumb || data.attributes.thumb
    }
  }))
}

function * uploadedFileSaga () {
  yield takeLatest(SUCCESS, uploadedFilePerform)
}

function * setUploadAttributesPerform (action) {
  const { uploadedIds, uploadAttributes } = yield select(makeUploadsSelector(action.fileType))
  if (uploadedIds.length) {
    // TODO check that we can do this
    const filesUrl = yield select(filesUrlSelector)
    const url = `${filesUrl}/tag`
    const response = yield call(apiPost, url, { ...uploadAttributes, file_ids: uploadedIds })
    yield put(updatedFiles(action.fileType, response.data))
    yield put(clearUploadedIds(action.fileType, uploadedIds))
  }
}

function * setUploadAttributesSaga () {
  yield takeEvery(SET_UPLOAD_ATTRIBUTES, setUploadAttributesPerform)
}

export const uploadsSagas = [
  uploadedFileSaga,
  setUploadAttributesSaga,
  addedFileSaga
]

// Selectors

export const makeUploadsSelector = (fileType) => (state) => {
  const base = state.uploads[fileType] || defaultUploadsKeyState
  return base
}

export const makeUploadSelector = (fileType) => (id) => (state) => {
  const base = state.uploads[fileType] || defaultUploadsKeyState
  return base.records[id]
}

// State

const date = new Date()
export const defaultTag = `${date.getFullYear()}/${date.getMonth() + 1}`

const defaultUploadsKeyState = {
  records: {},
  showTagger: false,
  uploadAttributes: {
    tags: [defaultTag],
    author: null,
    description: null
  },
  uploadedIds: []
}

const initialState = {}

// Reducer

function uploadsReducer (rawState = initialState, action) {
  const state = rawState

  if (action.fileType && !state[action.fileType]) {
    state[action.fileType] = { ...defaultUploadsKeyState }
  }

  const id = action.file ? idFromFile(action.file) : null

  switch (action.type) {
    case ADDED_FILE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: {
            ...state[action.fileType].records,
            [id]: {
              id,
              attributes: {
                file: action.file,
                file_size: action.file.size,
                file_name: action.file.name,
                extension: action.file.type.split('/').pop().toUpperCase(),
                tags: state[action.fileType].uploadAttributes.tags,
                author: state[action.fileType].uploadAttributes.author,
                description: state[action.fileType].uploadAttributes.description,
                thumb: null,
                progress: 0
              }
            }
          }
        }
      }

    case SET_FILE_S3_DATA:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: {
            ...state[action.fileType].records,
            [id]: {
              id,
              attributes: {
                ...state[action.fileType].records[id].attributes,
                s3_path: action.s3_path,
                s3_url: action.s3_url
              }
            }
          }
        }
      }

    case THUMBNAIL: {
      if (!state[action.fileType].records[id]) return state

      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: {
            ...state[action.fileType].records,
            [id]: {
              ...state[action.fileType].records[id],
              attributes: {
                ...state[action.fileType].records[id].attributes,
                thumb: action.dataUrl
              }
            }
          }
        }
      }
    }

    case PROGRESS:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: {
            ...state[action.fileType].records,
            [id]: {
              ...state[action.fileType].records[id],
              attributes: {
                ...state[action.fileType].records[id].attributes,
                progress: action.percentage
              }
            }
          }
        }
      }

    case FINISHED_UPLOAD:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          showTagger: true,
          records: omit(state[action.fileType].records, [id]),
          uploadedIds: [...state[action.fileType].uploadedIds, action.uploadedFileId]
        }
      }

    case ERROR:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: omit(state[action.fileType].records, [id])
        }
      }

    case SET_UPLOAD_ATTRIBUTES:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          uploadAttributes: action.attributes,
          showTagger: false
        }
      }

    case CLEAR_UPLOADED_IDS:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          uploadedIds: without(state[action.fileType].uploadedIds, ...action.ids)
        }
      }

    case CLOSE_TAGGER:
      return {
        ...state,
        [action.fileType]: {
          ...defaultUploadsKeyState,
          records: state[action.fileType].records
        }
      }

    default:
      return state
  }
}

export default uploadsReducer
