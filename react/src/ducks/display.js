import { takeLatest } from 'redux-saga/effects'

// Constants

const SET_DISPLAY = 'display/SET_DISPLAY'
const LOCALSTORAGE_DISPLAY_KEY = 'display/LOCALSTORAGE_DISPLAY_KEY'
export const DISPLAY_CARDS = 'display/DISPLAY_CARDS'
export const DISPLAY_THUMBS = 'display/DISPLAY_THUMBS'

// Actions

export function setDisplay (display) {
  return { type: SET_DISPLAY, display }
}

export function setCardsDisplay () {
  return setDisplay(DISPLAY_CARDS)
}

export function setThumbsDisplay () {
  return setDisplay(DISPLAY_THUMBS)
}

// Selectors

export const displaySelector = (state) => {
  return state.display
}

// State

const initialState = localStorage.getItem(LOCALSTORAGE_DISPLAY_KEY) || DISPLAY_THUMBS

// Reducer

function displayReducer (state = initialState, action) {
  switch (action.type) {
    case SET_DISPLAY: {
      switch (action.display) {
        case DISPLAY_CARDS:
          return action.display
        default:
          return DISPLAY_THUMBS
      }
    }

    default:
      return state
  }
}

// Sagas

function * setDisplayPerform (action) {
  if (action.display === DISPLAY_CARDS || action.display === DISPLAY_THUMBS) {
    yield localStorage.setItem(LOCALSTORAGE_DISPLAY_KEY, action.display)
  }
}

function * setDisplaySaga (): Generator<*, *, *> {
  yield takeLatest(SET_DISPLAY, setDisplayPerform)
}

export const displaySagas = [
  setDisplaySaga,
]

export default displayReducer
