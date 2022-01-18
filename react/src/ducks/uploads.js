import { takeLatest, takeEvery, call, select, put } from 'redux-saga/effects'
import { omit, without } from 'lodash'

import { apiPost } from 'utils/api'
import { uploadedFile, updatedFiles } from 'ducks/files'
import { filesUrlSelector } from 'ducks/app'

// Constants

const S3_UPLOAD_SUCCESS = 'uploads/S3_UPLOAD_SUCCESS'
const THUMBNAIL = 'uploads/THUMBNAIL'
const ERROR = 'uploads/ERROR'
const PROGRESS = 'uploads/PROGRESS'
const SET_UPLOAD_ATTRIBUTES = 'uploads/SET_UPLOAD_ATTRIBUTES'
const CLEAR_UPLOADED_IDS = 'uploads/CLEAR_UPLOADED_IDS'
const CLOSE_TAGGER = 'uploads/CLOSE_TAGGER'
const CREATE_FILE_FROM_S3_JOB_ADDED = 'uploads/CREATE_FILE_FROM_S3_JOB_ADDED'
const CREATE_FILE_FROM_S3_JOB_START = 'uploads/CREATE_FILE_FROM_S3_JOB_START'
const CREATE_FILE_FROM_S3_JOB_SUCCESS = 'uploads/CREATE_FILE_FROM_S3_JOB_SUCCESS'
const CREATE_FILE_FROM_S3_JOB_FAILURE = 'uploads/CREATE_FILE_FROM_S3_JOB_FAILURE'
const CREATE_FILE_FROM_S3_JOB_REMOVE_SUCCESSFUL = 'uploads/CREATE_FILE_FROM_S3_JOB_REMOVE_SUCCESSFUL'

const idFromFile = (file) => {
  return [file.name, file.lastModified, file.size].join('|')
}

// Actions

export function s3UploadSuccess (fileType, file) {
  return { type: S3_UPLOAD_SUCCESS, fileType, file }
}

export function thumbnail (fileType, file, dataUrl) {
  return { type: THUMBNAIL, fileType, file, dataUrl }
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

export function createFileFromS3JobAdded (fileType, file, file_name, s3_path, s3_url) {
  return { type: CREATE_FILE_FROM_S3_JOB_ADDED, fileType, file, file_name, s3_path, s3_url }
}

export function createFileFromS3JobStart (fileType, s3_path, startedAt) {
  return { type: CREATE_FILE_FROM_S3_JOB_START, fileType, s3_path, startedAt }
}

export function createFileFromS3JobSuccess (fileType, s3_path, fileFromApi) {
  return { type: CREATE_FILE_FROM_S3_JOB_SUCCESS, fileType, s3_path, fileFromApi }
}

export function createFileFromS3JobFailure (fileType, s3_path, errors) {
  return { type: CREATE_FILE_FROM_S3_JOB_FAILURE, fileType, s3_path, errors }
}

export function createFileFromS3JobRemoveSuccessful (fileType, s3_path, fileFromApiId) {
  return { type: CREATE_FILE_FROM_S3_JOB_REMOVE_SUCCESSFUL, fileType, s3_path, fileFromApiId }
}

// Sagas

function * uploadedFilePerform (action) {
  const upload = yield select(makeUploadS3PathSelector(action.fileType)(action.s3_path))

  yield put(uploadedFile(action.fileType, {
    ...action.fileFromApi,
    attributes: {
      ...action.fileFromApi.attributes,
      thumb: upload ? (upload.attribute.thumb || action.fileFromApi.attributes.thumb) : action.fileFromApi.attributes.thumb
    }
  }))

  yield put(createFileFromS3JobRemoveSuccessful(action.fileType, action.s3_path, action.fileFromApi.id))
}

function * uploadedFileSaga () {
  yield takeLatest(CREATE_FILE_FROM_S3_JOB_SUCCESS, uploadedFilePerform)
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

function * s3UploadSuccessPerform (action) {
  try {
    const id = idFromFile(action.file)
    const upload = yield select(makeUploadSelector(action.fileType)(id))
    const filesUrl = yield select(filesUrlSelector)
    const url = `${filesUrl}/s3_after`
    yield call(apiPost, url, { s3_path: upload.attributes.s3_path, type: action.fileType })
  } catch (e) {
    window.FolioConsole.Flash.alert(e.message)
  }
}

function * s3UploadSuccessSaga () {
  yield takeLatest(S3_UPLOAD_SUCCESS, s3UploadSuccessPerform)
}

export const uploadsSagas = [
  uploadedFileSaga,
  setUploadAttributesSaga,
  // addedFileSaga,
  s3UploadSuccessSaga
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

export const makeUploadS3PathSelector = (fileType) => (s3_path) => (state) => {
  const base = state.uploads[fileType] || defaultUploadsKeyState
  return base[Object.keys(base.records).find((key) => base.records[key].attributes.s3_path === s3_path)]
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
  console.log(action)
  const state = rawState

  if (action.fileType && !state[action.fileType]) {
    state[action.fileType] = { ...defaultUploadsKeyState }
  }

  const id = action.file ? idFromFile(action.file) : null

  switch (action.type) {
    case CREATE_FILE_FROM_S3_JOB_ADDED:
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
                file_name: action.file_name,
                extension: action.file.type.split('/').pop().toUpperCase(),
                tags: state[action.fileType].uploadAttributes.tags,
                author: state[action.fileType].uploadAttributes.author,
                description: state[action.fileType].uploadAttributes.description,
                thumb: null,
                progress: 0,
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

    case CREATE_FILE_FROM_S3_JOB_START: {
      const records = state[action.fileType].records

      Object.keys(records).forEach((key) => {
        if (records[key].attributes.s3_path === action.s3_path) {
          records[key].attributes.s3_job = { startedAt: action.startedAt }
        }
      })

      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records
        }
      }
    }

    case CREATE_FILE_FROM_S3_JOB_FAILURE: {
      const records = {}

      Object.keys(state[action.fileType].records).forEach((key) => {
        if (state[action.fileType].records[key].attributes.s3_path === action.s3_path) return
        records[key] = state[action.fileType].records[key]
      })

      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records
        }
      }
    }

    case CREATE_FILE_FROM_S3_JOB_REMOVE_SUCCESSFUL: {
      const records = {}

      Object.keys(state[action.fileType].records).forEach((key) => {
        if (state[action.fileType].records[key].attributes.s3_path === action.s3_path) return
        records[key] = state[action.fileType].records[key]
      })

      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records,
          showTagger: true,
          uploadedIds: [...state[action.fileType].uploadedIds, action.fileFromApiId]
        }
      }
    }

    default:
      return state
  }
}

export default uploadsReducer
