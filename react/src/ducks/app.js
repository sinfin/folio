// Constants

const SET_MODE = 'app/SET_MODE'
const SET_FILE_TYPE = 'app/SET_FILE_TYPE'
const SET_FILES_URL = 'app/SET_FILES_URL'
const SET_READ_ONLY = 'app/SET_READ_ONLY'
const SET_NO_FILE_USAGE = 'app/SET_NO_FILE_USAGE'

// Actions

export function setMode (mode) {
  return { type: SET_MODE, mode }
}

export function setFileType (fileType) {
  return { type: SET_FILE_TYPE, fileType }
}

export function setFilesUrl (filesUrl) {
  return { type: SET_FILES_URL, filesUrl }
}

export function setReadOnly (readOnly) {
  return { type: SET_READ_ONLY, readOnly }
}

export function setNoFileUsage () {
  return { type: SET_NO_FILE_USAGE }
}

// Selectors

export const appSelector = (state) => state.app
export const fileTypeSelector = (state) => state.app.fileType
export const filesUrlSelector = (state) => state.app.filesUrl
export const fileTypeIsImageSelector = (state) => state.app.fileType === 'Folio::Image'
export const fileUsageSelector = (state) => state.app.fileUsage

// State

const initialState = {
  mode: null,
  fileType: null,
  filesUrl: null,
  readOnly: false,
  fileUsage: true
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

    case SET_FILES_URL:
      return {
        ...state,
        filesUrl: action.filesUrl
      }

    case SET_READ_ONLY:
      return {
        ...state,
        readOnly: action.readOnly
      }

    case SET_NO_FILE_USAGE:
      return {
        ...state,
        fileUsage: false
      }

    default:
      return state
  }
}

export default appReducer
