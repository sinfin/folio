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

export function addedFile (file) {
  return { type: ADDED_FILE, file }
}

export function thumbnail (file, dataUrl) {
  return { type: THUMBNAIL, file, dataUrl }
}

export function success (file, response) {
  return { type: SUCCESS, file, response }
}

export function finishedUpload (file, uploadedFileId) {
  return { type: FINISHED_UPLOAD, file, uploadedFileId }
}

export function error (file, error) {
  return { type: ERROR, file, error }
}

export function progress (file, percentage) {
  return { type: PROGRESS, file, percentage }
}

export function setUploadTags (tags) {
  return { type: SET_UPLOAD_TAGS, tags }
}

export function clearUploadedIds (ids) {
  return { type: CLEAR_UPLOADED_IDS, ids }
}

// Sagas

function * uploadsErrorPerform (action) {
  yield call(flashError, action.error)
}

function * uploadsErrorSaga (): Generator<*, *, *> {
  yield takeLatest(ERROR, uploadsErrorPerform)
}

function * uploadedFilePerform (action) {
  const id = idFromFile(action.file)
  const upload = yield select(uploadSelector(id))
  const data = action.response.data
  yield put(finishedUpload(action.file, data.id))
  yield put(uploadedFile({
    ...data,
    attributes: {
      ...data.attributes,
      thumb: upload.thumb || data.attributes.thumb,
    }
  }))
}

function * uploadedFileSaga (): Generator<*, *, *> {
  yield takeLatest(SUCCESS, uploadedFilePerform)
}

function * setUploadTagsPerform (action) {
  const { uploadedIds, uploadTags } = yield select(uploadsSelector)
  if (uploadedIds.length) {
    const fileType = yield select(fileTypeSelector)
    const url = fileType === 'Folio::Document' ? '/console/api/documents/tag' : '/console/api/images/tag'
    const response = yield call(apiPost, url, { file_ids: uploadedIds, tags: uploadTags })
    yield put(updatedFiles(response.data))
    yield put(clearUploadedIds(uploadedIds))
  }
}

function * setUploadTagsSaga (): Generator<*, *, *> {
  yield takeEvery(SET_UPLOAD_TAGS, setUploadTagsPerform)
}

export const uploadsSagas = [
  uploadsErrorSaga,
  uploadedFileSaga,
  setUploadTagsSaga,
]

// Selectors

export const uploadsSelector = (state) => {
  return state.uploads
}

export const uploadSelector = (id) => (state) => {
  const base = state.uploads
  return base.records[id]
}

// State

const date = new Date()
const defaultTag = `${date.getFullYear()}/${date.getMonth() + 1}`

const initialState = {
  records: {},
  showTagger: false,
  uploadTags: [defaultTag],
  uploadedIds: [],
}

// Reducer

function uploadsReducer (state = initialState, action) {
  const id = action.file ? idFromFile(action.file) : null

  switch (action.type) {
    case ADDED_FILE:
      return {
        ...state,
        didUpload: true,
        records: {
          ...state.records,
          [id]: {
            id,
            attributes: {
              file: action.file,
              file_size: action.file.size,
              file_name: action.file.name,
              extension: action.file.type.split('/').pop().toUpperCase(),
              tags: state.uploadTags,
              thumb: null,
              progress: 0,
            },
          },
        }
      }

    case THUMBNAIL: {
      if (!state.records[id]) return state

      return {
        ...state,
        records: {
          ...state.records,
          [id]: {
            ...state.records[id],
            attributes: {
              ...state.records[id].attributes,
              thumb: action.dataUrl,
            },
          },
        }
      }
    }

    case PROGRESS:
      return {
        ...state,
        records: {
          ...state.records,
          [id]: {
            ...state.records[id],
            attributes: {
              ...state.records[id].attributes,
              progress: action.percentage,
            },
          },
        }
      }

    case FINISHED_UPLOAD:
      return {
        ...state,
        showTagger: true,
        records: omit(state.records, [id]),
        uploadedIds: [...state.uploadedIds, action.uploadedFileId]
      }

    case ERROR:
      return {
        ...state,
        records: omit(state.records, [id]),
      }

    case SET_UPLOAD_TAGS:
      return {
        ...state,
        uploadTags: action.tags,
        showTagger: false,
      }

    case CLEAR_UPLOADED_IDS:
      return {
        ...state,
        uploadedIds: without(state.uploadedIds, ...action.ids)
      }

    default:
      return state
  }
}

export default uploadsReducer
