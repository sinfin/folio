// Constants

const SET_MODE = 'app/SET_MODE'
const SET_FILE_TYPE = 'app/SET_FILE_TYPE'
const SET_FILE_REACT_TYPE = 'app/SET_FILE_REACT_TYPE'
const SET_FILES_URL = 'app/SET_FILES_URL'
const SET_INDEX_URL = 'app/SET_INDEX_URL'
const SET_READ_ONLY = 'app/SET_READ_ONLY'
const SET_TAGGABLE = 'app/SET_TAGGABLE'
const SET_NO_FILE_USAGE = 'app/SET_NO_FILE_USAGE'
const SET_CAN_DESTROY_FILES = 'app/SET_CAN_DESTROY_FILES'
const SET_PHOTO_ARCHIVE_ENABLED = 'app/SET_PHOTO_ARCHIVE_ENABLED'

// Actions

export function setMode (mode) {
  return { type: SET_MODE, mode }
}

export function setFileType (fileType) {
  return { type: SET_FILE_TYPE, fileType }
}

export function setFileReactType (reactType) {
  return { type: SET_FILE_REACT_TYPE, reactType }
}

export function setFilesUrl (filesUrl) {
  return { type: SET_FILES_URL, filesUrl }
}

export function setIndexUrl (indexUrl) {
  return { type: SET_INDEX_URL, indexUrl }
}

export function setReadOnly (readOnly) {
  return { type: SET_READ_ONLY, readOnly }
}

export function setTaggable (taggable) {
  return { type: SET_TAGGABLE, taggable }
}

export function setCanDestroyFiles (canDestroyFiles) {
  return { type: SET_CAN_DESTROY_FILES, canDestroyFiles }
}

export function setPhotoArchiveEnabled (photoArchiveEnabled) {
  return { type: SET_PHOTO_ARCHIVE_ENABLED, photoArchiveEnabled }
}

export function setNoFileUsage () {
  return { type: SET_NO_FILE_USAGE }
}

// Selectors

export const appSelector = (state) => state.app
export const fileTypeSelector = (state) => state.app.fileType
export const filesUrlSelector = (state) => state.app.filesUrl
export const fileUsageSelector = (state) => state.app.fileUsage
export const photoArchiveEnabledSelector = (state) => state.app.photoArchiveEnabled
export const indexUrlSelector = (state) => state.app.mode === 'index' ? state.app.indexUrl : null

// State

const initialState = {
  mode: null,
  fileType: null,
  filesUrl: null,
  indexUrl: null,
  readOnly: false,
  fileUsage: true,
  canDestroyFiles: true,
  taggable: false,
  photoArchiveEnabled: false
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

    case SET_FILE_REACT_TYPE:
      return {
        ...state,
        reactType: action.reactType
      }

    case SET_FILES_URL:
      return {
        ...state,
        filesUrl: action.filesUrl
      }

    case SET_INDEX_URL:
      return {
        ...state,
        indexUrl: action.indexUrl
      }

    case SET_READ_ONLY:
      return {
        ...state,
        readOnly: action.readOnly
      }

    case SET_TAGGABLE:
      return {
        ...state,
        taggable: !!action.taggable
      }

    case SET_CAN_DESTROY_FILES:
      return {
        ...state,
        canDestroyFiles: !!action.canDestroyFiles
      }

    case SET_PHOTO_ARCHIVE_ENABLED:
      return {
        ...state,
        photoArchiveEnabled: !!action.photoArchiveEnabled
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
