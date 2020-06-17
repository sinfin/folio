import { flashError } from 'utils/flash'
import { takeLatest, takeEvery, call, select, put } from 'redux-saga/effects'
import { omit, without } from 'lodash'

import { apiPost } from 'utils/api'
import { uploadedFile, updatedFiles } from 'ducks/files'
import { fileTypeSelector } from 'ducks/app'

// Constants

const ADDED_FILE = 'uploads/ADDED_FILE'
const THUMBNAIL = 'uploads/THUMBNAIL'
const SUCCESS = 'uploads/SUCCESS'
const ERROR = 'uploads/ERROR'
const FINISHED_UPLOAD = 'uploads/FINISHED_UPLOAD'
const PROGRESS = 'uploads/PROGRESS'
const SET_UPLOAD_TAGS = 'uploads/SET_UPLOAD_TAGS'
const CLEAR_UPLOADED_IDS = 'uploads/CLEAR_UPLOADED_IDS'

const idFromFile = (file) => {
  return [file.name, file.lastModified, file.size].join('|')
}

// Actions

export function addedFile (fileType, file) {
  return { type: ADDED_FILE, fileType, file }
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

export function error (fileType, file, error) {
  return { type: ERROR, fileType, file, error }
}

export function progress (fileType, file, percentage) {
  return { type: PROGRESS, fileType, file, percentage }
}

export function setUploadTags (fileType, tags) {
  return { type: SET_UPLOAD_TAGS, fileType, tags }
}

export function clearUploadedIds (fileType, ids) {
  return { type: CLEAR_UPLOADED_IDS, fileType, ids }
}

// Sagas

function * uploadsErrorPerform (action) {
  yield call(flashError, action.error)
}

function * uploadsErrorSaga () {
  yield takeLatest(ERROR, uploadsErrorPerform)
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

function * setUploadTagsPerform (action) {
  const { uploadedIds, uploadTags } = yield select(makeUploadsSelector(action.fileType))
  if (uploadedIds.length) {
    const fileType = yield select(fileTypeSelector)
    const url = fileType === 'Folio::Document' ? '/console/api/documents/tag' : '/console/api/images/tag'
    const response = yield call(apiPost, url, { file_ids: uploadedIds, tags: uploadTags })
    yield put(updatedFiles(action.fileType, response.data))
    yield put(clearUploadedIds(action.fileType, uploadedIds))
  }
}

function * setUploadTagsSaga () {
  yield takeEvery(SET_UPLOAD_TAGS, setUploadTagsPerform)
}

export const uploadsSagas = [
  uploadsErrorSaga,
  uploadedFileSaga,
  setUploadTagsSaga
]

// Selectors

export const makeUploadsSelector = (fileType) => (state) => {
  return state.uploads[fileType]
}

export const makeUploadSelector = (fileType) => (id) => (state) => {
  return state.uploads[fileType].records[id]
}

// State

const date = new Date()
export const defaultTag = `${date.getFullYear()}/${date.getMonth() + 1}`

const defaultFilesKeyState = {
  records: {},
  showTagger: false,
  uploadTags: [defaultTag],
  uploadedIds: []
}

const initialState = {}

// Reducer

function uploadsReducer (rawState = initialState, action) {
  const state = rawState

  if (action.fileType && !state[action.fileType]) {
    state[action.fileType] = { ...defaultFilesKeyState }
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
                tags: state.uploadTags,
                thumb: null,
                progress: 0
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

    case SET_UPLOAD_TAGS:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          uploadTags: action.tags,
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

    default:
      return state
  }
}

export default uploadsReducer
