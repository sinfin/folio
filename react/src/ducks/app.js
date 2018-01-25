import { fromJS } from 'immutable'

const initialState = fromJS({
  loading: false,
  loaded: false,
})

function appReducer (state = initialState, action) {
  switch (action.type) {
    default:
      return state
  }
}

export default appReducer
