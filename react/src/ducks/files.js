import { fromJS } from 'immutable'
import { apiGet } from 'utils/api'
import { flashError } from 'utils/flash'
import { takeLatest, call, put, select } from 'redux-saga/effects'
import { find, filter } from 'lodash'
import { arrayMove } from 'react-sortable-hoc'

import { fileTypeSelector } from 'ducks/app'

// Constants

const PREFILL_SELECTED = 'files/PREFILL_SELECTED'
const GET_FILES = 'files/GET_FILES'
const GET_FILES_SUCCESS = 'files/GET_FILES_SUCCESS'
const SELECT_FILE = 'files/SELECT_FILE'
const UNSELECT_FILE = 'files/UNSELECT_FILE'
const ON_SORT_END = 'files/ON_SORT_END'
const UPLOADED_FILE = 'files/UPLOADED_FILE'

// Actions

export function prefillSelected (selected) {
  return { type: PREFILL_SELECTED, selected }
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

// Sagas

function * getFilesPerform (action) {
  try {
    const fileType = yield select(fileTypeSelector)
    const filesUrl = fileType === 'Folio::Document' ? '/console/files?type=document' : '/console/files?type=image'
    const records = yield call(apiGet, filesUrl)
    yield put(getFilesSuccess(records))
  } catch (e) {
    flashError(e.message)
  }
}

function * getFilesSaga (): Generator<*, *, *> {
  yield takeLatest(GET_FILES, getFilesPerform)
}

export const filesSagas = [
  getFilesSaga,
]

// Selectors

export const allFilesSelector = (state) => {
  const base = state.get('files').toJS()
  return base.records
}

export const filesSelector = (state) => {
  const base = state.get('files').toJS()
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
    selected,
    selectable,
  }
}

// State

const initialState = fromJS({
  loading: false,
  loaded: false,
  filesUrl: '/console/files',
  records: [],
  selected: [],
})

// Reducer

function filesReducer (state = initialState, action) {
  switch (action.type) {
    case GET_FILES:
      return state.set('loading', true)

    case GET_FILES_SUCCESS: {
      const selected = state.get('selected').toJS()
      const records = action.records.map((record) => {
        const sel = find(selected, { file_id: record.id })
        let id = ''
        const file_id = record.id

        if (sel) id = sel.id

        return {
          ...record,
          id,
          file_id,
        }
      })

      return state.merge({
        loading: false,
        loaded: true,
        records,
      })
    }

    case PREFILL_SELECTED:
      return state.merge({
        selected: action.selected,
      })

    case SELECT_FILE:
      return state.updateIn(['selected'], (selected) => (
        selected.push(fromJS({
          id: action.file.id,
          file_id: action.file.file_id,
        }))
      ))

    case UNSELECT_FILE:
      return state.updateIn(['selected'], (selected) => (
        selected.filter((sel) => sel.get('file_id') !== action.file.file_id)
      ))

    case ON_SORT_END: {
      return state.updateIn(['selected'], (selected) => (
        fromJS(
          arrayMove(selected.toJS(), action.oldIndex, action.newIndex)
        )
      ))
    }

    case UPLOADED_FILE: {
      return state.updateIn(['records'], (records) => (
        records.push(fromJS(action.file))
      ))
    }

    default:
      return state
  }
}

export default filesReducer
