import { fromJS } from 'immutable'
import { apiGet } from 'utils/api'
import { flashError } from 'utils/flash'
import { takeLatest, call, put } from 'redux-saga/effects'
import { find, filter } from 'lodash'
import { arrayMove } from 'react-sortable-hoc'

// Constants

const PREFILL_SELECTED = 'images/PREFILL_SELECTED'
const GET_IMAGES = 'images/GET_IMAGES'
const GET_IMAGES_SUCCESS = 'images/GET_IMAGES_SUCCESS'
const SELECT_IMAGE = 'images/SELECT_IMAGE'
const UNSELECT_IMAGE = 'images/UNSELECT_IMAGE'
const ON_SORT_END = 'images/ON_SORT_END'

const IMAGES_URL = '/console/files?type=image'

// Actions

export function prefillSelected (selected) {
  return { type: PREFILL_SELECTED, selected }
}

export function getImages () {
  return { type: GET_IMAGES }
}

export function getImagesSuccess (records) {
  return { type: GET_IMAGES_SUCCESS, records }
}

export function selectImage (image) {
  return { type: SELECT_IMAGE, image }
}

export function unselectImage (image) {
  return { type: UNSELECT_IMAGE, image }
}

export function onSortEnd (oldIndex, newIndex) {
  return { type: ON_SORT_END, oldIndex, newIndex }
}

// Sagas

function * getImagesPerform (action) {
  try {
    const records = yield call(apiGet, IMAGES_URL)
    yield put(getImagesSuccess(records))
  } catch (e) {
    flashError(e.message)
  }
}

function * getImagesSaga (): Generator<*, *, *> {
  yield takeLatest(GET_IMAGES, getImagesPerform)
}

export const imagesSagas = [
  getImagesSaga,
]

// Selectors

export const imagesSelector = (state) => {
  const base = state.get('images').toJS()

  const selected = base.selected.map((id) => (
    find(base.records, { id })
  ))

  const selectable = filter(base.records, (image) => (
    base.selected.indexOf(image.id) === -1
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
  records: [],
  selected: [],
})

// Reducer

function imagesReducer (state = initialState, action) {
  switch (action.type) {
    case GET_IMAGES:
      return state.set('loading', true)

    case GET_IMAGES_SUCCESS:
      return state.merge({
        loading: false,
        loaded: true,
        records: action.records,
      })

    case PREFILL_SELECTED:
      return state.merge({
        selected: action.selected,
      })

    case SELECT_IMAGE:
      return state.updateIn(['selected'], (selected) => (
        selected.push(action.image.id)
      ))

    case UNSELECT_IMAGE:
      return state.updateIn(['selected'], (selected) => (
        selected.filterNot((id) => id === action.image.id)
      ))

    case ON_SORT_END: {
      return state.updateIn(['selected'], (selected) => (
        fromJS(
          arrayMove(selected.toJS(), action.oldIndex, action.newIndex)
        )
      ))
    }

    default:
      return state
  }
}

export default imagesReducer
