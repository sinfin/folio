// Constants

const SET_MODE = 'app/SET_MODE'
const SET_FILE_TYPE = 'app/SET_FILE_TYPE'

// Actions

export function setMode (mode) {
  return { type: SET_MODE, mode }
}

export function setFileType (fileType) {
  return { type: SET_FILE_TYPE, fileType }
}

// Selectors

export const fileTypeSelector = (state) => state.app.fileType
export const fileTypeIsImageSelector = (state) => state.app.fileType === 'Folio::Image'

// State

const initialState = {
  mode: null,
  fileType: 'Folio::Image'
}

// Reducer

function appReducer (state = initialState, action) {
  switch (action.type) {
    case SET_MODE:
      return {
        ...state,
        mode: action.mode
      }

    case SET_FILE_TYPE:
      return {
        ...state,
        fileType: action.fileType
      }

    default:
      return state
  }
}

export default appReducer
