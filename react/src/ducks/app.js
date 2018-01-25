import { fromJS } from 'immutable'

// Constants

const SET_MODE = 'app/SET_MODE'

// Actions

export function setMode (mode) {
  return { type: SET_MODE, mode }
}

// State

const initialState = fromJS({
  mode: null,
})

// Reducer

function appReducer (state = initialState, action) {
  switch (action.type) {
    case SET_MODE:
      return state.set('mode', action.mode)

    default:
      return state
  }
}

export default appReducer
