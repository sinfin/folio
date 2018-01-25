import { combineReducers } from 'redux-immutable'

import appReducer from 'ducks/app'
import imagesReducer from 'ducks/images'

export default combineReducers({
  app: appReducer,
  images: imagesReducer,
})
