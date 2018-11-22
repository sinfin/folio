import { apiGet, apiPut } from 'utils/api'
import { flashError } from 'utils/flash'
import { takeLatest, takeEvery, call, put, select } from 'redux-saga/effects'
import { find, filter } from 'lodash'
import { arrayMove } from 'react-sortable-hoc'

import { fileTypeSelector } from 'ducks/app'
import { filteredFilesSelector } from 'ducks/filters'
import { uploadsSelector } from 'ducks/uploads'

import { File, UploadingFile } from 'components/File'

// Constants

const PREFILL_SELECTED = 'files/PREFILL_SELECTED'
const GET_FILES = 'files/GET_FILES'
const GET_FILES_SUCCESS = 'files/GET_FILES_SUCCESS'
const SELECT_FILE = 'files/SELECT_FILE'
const UNSELECT_FILE = 'files/UNSELECT_FILE'
const ON_SORT_END = 'files/ON_SORT_END'
const UPLOADED_FILE = 'files/UPLOADED_FILE'
const SET_ATTACHMENTABLE = 'files/SET_ATTACHMENTABLE'
const THUMBNAIL_GENERATED = 'files/THUMBNAIL_GENERATED'
const UPDATE_FILE = 'files/UPDATE_FILE'
const UPDATE_FILE_SUCCESS = 'files/UPDATE_FILE_SUCCESS'
const UPDATE_FILE_FAILURE = 'files/UPDATE_FILE_FAILURE'

// Actions

export function prefillSelected (selected) {
  return { type: PREFILL_SELECTED, selected }
}

export function setAttachmentable (attachmentable) {
  return { type: SET_ATTACHMENTABLE, attachmentable }
}

export function getFiles () {
  return { type: GET_FILES }
}

export function getFilesSuccess (records) {
  return { type: GET_FILES_SUCCESS, records }
}

export function selectFile (file) {
  return { type: SELECT_FILE, file }
}

export function unselectFile (file) {
  return { type: UNSELECT_FILE, file }
}

export function onSortEnd (oldIndex, newIndex) {
  return { type: ON_SORT_END, oldIndex, newIndex }
}

export function uploadedFile (file) {
  return { type: UPLOADED_FILE, file }
}

export function thumbnailGenerated (temporary_url, url) {
  return { type: THUMBNAIL_GENERATED, temporary_url, url }
}

export function updateFile (file, attributes) {
  return { type: UPDATE_FILE, file, attributes }
}

export function updateFileSuccess (file, response) {
  return { type: UPDATE_FILE_SUCCESS, file, response }
}

export function updateFileFailure (file) {
  return { type: UPDATE_FILE_FAILURE, file }
}

// Sagas

function * getFilesPerform (action) {
  try {
    const fileType = yield select(fileTypeSelector)
    const filesUrl = fileType === 'Folio::Document' ? '/console/documents' : '/console/images'
    const records = yield call(apiGet, filesUrl)
    yield put(getFilesSuccess(records))
  } catch (e) {
    flashError(e.message)
  }
}

function * getFilesSaga (): Generator<*, *, *> {
  yield takeLatest(GET_FILES, getFilesPerform)
}

function * updateFilePerform (action) {
  try {
    const { file, attributes } = action
    const fileType = yield select(fileTypeSelector)
    const filesUrl = fileType === 'Folio::Document' ? '/console/documents' : '/console/images'
    const response = yield call(apiPut, `${filesUrl}/${file.file_id}`, { file: attributes })
    yield put(updateFileSuccess(action.file, response.file))
  } catch (e) {
    flashError(e.message)
    yield put(updateFileFailure(action.file))
  }
}

function * updateFileSaga (): Generator<*, *, *> {
  yield takeEvery(UPDATE_FILE, updateFilePerform)
}

export const filesSagas = [
  getFilesSaga,
  updateFileSaga,
]

// Selectors

export const filesLoadingSelector = (state) => {
  return state.files.loading
}

export const filesLoadedSelector = (state) => {
  return state.files.loaded
}

export const allFilesSelector = (state) => {
  return state.files.records
}

export const filesSelector = (state) => {
  const base = state.files
  let file_ids = []

  const selected = base.selected.map((sel) => {
    file_ids.push(sel.file_id)
    return find(base.records, { file_id: sel.file_id })
  })

  const selectable = filter(base.records, (file) => (
    file_ids.indexOf(file.file_id) === -1
  ))

  return {
    loading: base.loading,
    attachmentable: base.attachmentable,
    selected,
    selectable,
  }
}

export const filesForListSelector = (state) => {
  let files = []

  const uploads = uploadsSelector(state).records.map((file, index) => {
    files.push({ key: file.id, file })
  })

  const filteredFiles = filteredFilesSelector(state).selectable.map((file) => {
    files.push({ key: file.file_id, file })
  })

  return files
}

// State

const initialState = {
  loading: false,
  loaded: false,
  filesUrl: '/console/files',
  records: [],
  selected: [],
  attachmentable: 'node',
}

// Reducer

const addFileId = (state, record) => {
  const sel = find(state.selected, { file_id: record.id })
  let id = ''
  const file_id = record.id

  if (sel) id = sel.id

  return {
    ...record,
    id,
    file_id,
  }
}

function filesReducer (state = initialState, action) {
  switch (action.type) {
    case GET_FILES:
      return {
        ...state,
        loading: true,
      }

    case GET_FILES_SUCCESS:
      return {
        ...state,
        records: action.records.map((record) => addFileId(state, record)),
        loading: false,
        loaded: true,
      }

    case SET_ATTACHMENTABLE:
      return {
        ...state,
        attachmentable: action.attachmentable,
      }

    case PREFILL_SELECTED:
      return {
        ...state,
        selected: action.selected,
      }

    case SELECT_FILE:
      return {
        ...state,
        selected: [
          ...state.selected,
          { id: action.file.id, file_id: action.file.file_id },
        ]
      }

    case UNSELECT_FILE:
      return {
        ...state,
        selected: state.selected.filter((sel) => sel.file_id !== action.file.file_id)
      }

    case ON_SORT_END:
      return {
        ...state,
        selected: arrayMove(state.selected, action.oldIndex, action.newIndex)
      }

    case UPLOADED_FILE:
      return {
        ...state,
        records: [action.file, ...state.records]
      }

    case THUMBNAIL_GENERATED: {
      const mapper = (record) => {
        if (record.thumb !== action.temporary_url) return { ...record }
        return {
          ...record,
          thumb: action.url,
        }
      }

      return {
        ...state,
        records: state.records.map(mapper),
        selected: state.selected.map(mapper),
      }
    }

    case UPDATE_FILE:
      return {
        ...state,
        records: state.records.map((record) => {
          if (record.file_id === action.file.file_id) {
            return {
              ...record,
              ...action.attributes,
              updating: true,
            }
          } else {
            return { ...record }
          }
        }),
      }

    case UPDATE_FILE_SUCCESS:
      return {
        ...state,
        records: state.records.map((record) => {
          if (record.file_id === action.response.id) {
            return addFileId(state, action.response)
          } else {
            return { ...record }
          }
        }),
      }

    case UPDATE_FILE_FAILURE:
      return {
        ...state,
        records: state.records.map((record) => {
          if (record.id === action.file.id) {
            return { ...record }
          } else {
            return { ...action.file }
          }
        }),
      }

    default:
      return state
  }
}

export default filesReducer
