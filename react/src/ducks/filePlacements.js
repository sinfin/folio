import { arrayMove } from 'react-sortable-hoc'
import { find, filter } from 'lodash'

import { filesSelector } from 'ducks/files'

// Constants

const SET_ORIGINAL_PLACEMENTS = 'filePlacements/SET_ORIGINAL_PLACEMENTS'
const SELECT_FILE = 'filePlacements/SELECT_FILE'
const UNSELECT_FILE_PLACEMENT = 'filePlacements/UNSELECT_FILE_PLACEMENT'
const ON_SORT_END = 'filePlacements/ON_SORT_END'
const SET_ATTACHMENTABLE = 'filePlacements/SET_ATTACHMENTABLE'
const SET_PLACEMENT_TYPE = 'filePlacements/SET_PLACEMENT_TYPE'

// Actions

export function setOriginalPlacements (original) {
  return { type: SET_ORIGINAL_PLACEMENTS, original }
}

export function setAttachmentable (attachmentable) {
  return { type: SET_ATTACHMENTABLE, attachmentable }
}

export function selectFile (file) {
  return { type: SELECT_FILE, file }
}

export function unselectFilePlacement (filePlacement) {
  return { type: UNSELECT_FILE_PLACEMENT, filePlacement }
}

export function onSortEnd (oldIndex, newIndex) {
  return { type: ON_SORT_END, oldIndex, newIndex }
}

export function setPlacementType (placementType) {
  return { type: SET_PLACEMENT_TYPE, placementType }
}

// Selectors

export const selectedFileIdsSelector = (state) => {
  const base = state.filePlacements
  return base.selected.map((filePlacement) => filePlacement.file_id)
}

export const filePlacementsSelector = (state) => {
  const base = state.filePlacements
  const files = filesSelector(state)
  let selectedIds = []

  const selected = base.selected.map((filePlacement) => {
    selectedIds.push(filePlacement.id)
    const file = find(files, { id: filePlacement.file_id })
    return {
      ...filePlacement,
      file: file,
    }
  })

  const deleted = filter(base.original, (filePlacement) => (
    selectedIds.indexOf(filePlacement.id) === -1
  ))

  return {
    selected,
    deleted,
    attachmentable: base.attachmentable,
    placementType: base.placementType,
  }
}

// State

const initialState = {
  original: [],
  selected: [],
  attachmentable: 'node',
  placementType: 'file_placements',
}

// Reducer

function filePlacementsReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ATTACHMENTABLE:
      return {
        ...state,
        attachmentable: action.attachmentable,
      }

    case SET_ORIGINAL_PLACEMENTS:
      return {
        ...state,
        original: action.original,
        selected: action.original,
      }

    case SELECT_FILE:
      return {
        ...state,
        selected: [
          ...state.selected,
          { id: null, file_id: action.file.id, selectedAt: Date.now() },
        ]
      }

    case UNSELECT_FILE_PLACEMENT:
      return {
        ...state,
        selected: state.selected.filter((filePlacement) => filePlacement.file_id !== action.filePlacement.file_id),
      }

    case ON_SORT_END:
      return {
        ...state,
        selected: arrayMove(state.selected, action.oldIndex, action.newIndex)
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

export default filePlacementsReducer
