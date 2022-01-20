import { takeEvery, call, select, put } from 'redux-saga/effects'
import { without, omit } from 'lodash'

import { apiPost } from 'utils/api'
import { updatedFiles } from 'ducks/files'
import { filesUrlSelector } from 'ducks/app'

// Constants

const SET_UPLOAD_ATTRIBUTES = 'uploads/SET_UPLOAD_ATTRIBUTES'
const CLEAR_UPLOADED_IDS = 'uploads/CLEAR_UPLOADED_IDS'
const SHOW_TAGGER = 'uploads/SHOW_TAGGER'
const CLOSE_TAGGER = 'uploads/CLOSE_TAGGER'
const ADD_DROPZONE_FILE = 'uploads/ADD_DROPZONE_FILE'
const UPDATE_DROPZONE_FILE = 'uploads/UPDATE_DROPZONE_FILE'
const REMOVE_DROPZONE_FILE = 'uploads/REMOVE_DROPZONE_FILE'
const THUMBNAIL_DROPZONE_FILE = 'uploads/THUMBNAIL_DROPZONE_FILE'

// Actions

export function setUploadAttributes (fileType, attributes) {
  return { type: SET_UPLOAD_ATTRIBUTES, fileType, attributes }
}

export function clearUploadedIds (fileType, ids) {
  return { type: CLEAR_UPLOADED_IDS, fileType, ids }
}

export function showTagger (fileType, fileFromApiId) {
  return { type: SHOW_TAGGER, fileType, fileFromApiId }
}

export function closeTagger (fileType) {
  return { type: CLOSE_TAGGER, fileType }
}

export function addDropzoneFile (fileType, s3Path, attributes) {
  return { type: ADD_DROPZONE_FILE, fileType, s3Path, attributes }
}

export function updateDropzoneFile (fileType, s3Path, attributes) {
  return { type: UPDATE_DROPZONE_FILE, fileType, s3Path, attributes }
}

export function removeDropzoneFile (fileType, s3Path) {
  return { type: REMOVE_DROPZONE_FILE, fileType, s3Path }
}

export function thumbnailDropzoneFile (fileType, s3Path, dataThumbnail) {
  console.log({ type: THUMBNAIL_DROPZONE_FILE, fileType, s3Path, dataThumbnail })
  return { type: THUMBNAIL_DROPZONE_FILE, fileType, s3Path, dataThumbnail }
}

// Sagas

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
  setUploadAttributesSaga
]

// Selectors

export const makeUploadsSelector = (fileType) => (state) => {
  const base = state.uploads[fileType] || defaultUploadsKeyState
  return base
}

// State

const date = new Date()
export const defaultTag = `${date.getFullYear()}/${date.getMonth() + 1}`

export const defaultUploadsKeyState = {
  showTagger: false,
  uploadAttributes: {
    tags: [defaultTag],
    author: null,
    description: null
  },
  uploadedIds: [],
  dropzoneFiles: {},
  pendingDataThumbnails: {}
}

const initialState = {}

// Reducer

function uploadsReducer (rawState = initialState, action) {
  const state = rawState

  if (action.fileType && !state[action.fileType]) {
    state[action.fileType] = { ...defaultUploadsKeyState }
  }

  switch (action.type) {
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
          uploadedIds: []
        }
      }

    case SHOW_TAGGER: {
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          showTagger: true,
          uploadedIds: [
            ...state[action.fileType].uploadedIds,
            action.fileFromApiId
          ]
        }
      }
    }

    case ADD_DROPZONE_FILE: {
      const pendingDataThumbnail = state[action.fileType].pendingDataThumbnails[action.s3Path]

      const newAttributes = { ...action.attributes, progress: 0 }

      if (pendingDataThumbnail) {
        newAttributes.dataThumbnail = pendingDataThumbnail
      }

      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          dropzoneFiles: {
            ...state[action.fileType].dropzoneFiles,
            [action.s3Path]: {
              attributes: newAttributes
            }
          },
          pendingDataThumbnails: omit(state[action.fileType].pendingDataThumbnails, action.s3Path)
        }
      }
    }

    case UPDATE_DROPZONE_FILE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          dropzoneFiles: {
            ...state[action.fileType].dropzoneFiles,
            [action.s3Path]: {
              ...state[action.fileType][action.s3Path],
              attributes: {
                ...state[action.fileType].dropzoneFiles[action.s3Path].attributes,
                ...action.attributes
              }
            }
          }
        }
      }

    case REMOVE_DROPZONE_FILE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          dropzoneFiles: omit(state[action.fileType].dropzoneFiles, action.s3Path)
        }
      }

    case THUMBNAIL_DROPZONE_FILE: {
      if (state[action.fileType].dropzoneFiles[action.s3Path]) {
        return {
          ...state,
          [action.fileType]: {
            ...state[action.fileType],
            dropzoneFiles: {
              ...state[action.fileType].dropzoneFiles,
              [action.s3Path]: {
                ...state[action.fileType][action.s3Path],
                attributes: {
                  ...state[action.fileType].dropzoneFiles[action.s3Path].attributes,
                  dataThumbnail: action.dataThumbnail
                }
              }
            }
          }
        }
      } else {
        return {
          ...state,
          [action.fileType]: {
            ...state[action.fileType],
            pendingDataThumbnails: {
              ...state[action.fileType].pendingDataThumbnails,
              [action.s3Path]: action.dataThumbnail
            }
          }
        }
      }
    }

    default:
      return state
  }
}

export default uploadsReducer
