// Constants

const SET_MODE = 'app/SET_MODE'
const SET_FILE_TYPE = 'app/SET_FILE_TYPE'
const SET_PLACEMENT_TYPE = 'app/SET_PLACEMENT_TYPE'

// Actions

export function setMode (mode) {
  return { type: SET_MODE, mode }
}

export function setFileType (fileType) {
  return { type: SET_FILE_TYPE, fileType }
}

export function setPlacementType (placementType) {
  return { type: SET_PLACEMENT_TYPE, placementType }
}

// Selectors

export const fileTypeSelector = (state) => state.app.fileType
export const placementTypeSelector = (state) => state.app.placementType

// State

const initialState = {
  mode: null,
  fileType: 'Folio::Image',
  placementType: 'file_placements',
}

// Reducer

function appReducer (state = initialState, action) {
  switch (action.type) {
    case SET_MODE:
      return {
        ...state,
        mode: action.mode,
      }

    case SET_FILE_TYPE:
      return {
        ...state,
        fileType: action.fileType,
      }

    case SET_PLACEMENT_TYPE:
      return {
        ...state,
        placementType: action.placementType,
      }

    default:
      return state
  }
}

export default appReducer
