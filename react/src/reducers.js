import { combineReducers } from 'redux-immutable'
// import { fromJS } from 'immutable'

import appReducer from 'ducks/app'

export default combineReducers({
  app: appReducer,
})
