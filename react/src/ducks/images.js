import { fromJS } from 'immutable'
import { apiGet } from 'utils/api'
import { flashError } from 'utils/flash'
import { takeLatest, call, put } from 'redux-saga/effects'

// Constants

const GET_IMAGES = 'images/GET_IMAGES'
const GET_IMAGES_SUCCESS = 'images/GET_IMAGES_SUCCESS'

const IMAGES_URL = '/console/files'

// Actions

export function getImages () {
  return { type: GET_IMAGES }
}

export function getImagesSuccess (records) {
  return { type: GET_IMAGES_SUCCESS, records }
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

// State

const initialState = fromJS({
  loading: false,
  loaded: false,
  records: [],
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

    default:
      return state
  }
}

export default imagesReducer
