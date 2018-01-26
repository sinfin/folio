import { combineReducers } from 'redux-immutable'

import appReducer from 'ducks/app'
import filesReducer from 'ducks/files'
import uploadsReducer from 'ducks/uploads'

export default combineReducers({
  app: appReducer,
  files: filesReducer,
  uploads: uploadsReducer,
})
