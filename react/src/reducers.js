import { combineReducers } from 'redux-immutable'

import appReducer from 'ducks/app'
import filesReducer from 'ducks/files'

export default combineReducers({
  app: appReducer,
  files: filesReducer,
})
