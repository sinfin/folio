import filePlacementsReducer, {
  initialState,
  setOriginalPlacements,
  setAttachmentable,
  selectFile,
  unselectFilePlacement,
  onSortEnd,
  setPlacementType,
  changeTitle,
  changeAlt
} from '../filePlacements'

const mockImages = [
  { id: 1, file_id: 1 },
  { id: 2, file_id: 2 },
  { id: 3, file_id: 3 }
]
const fileMock = { id: '999', type: 'file', attributes: { id: 999, file_size: 326774, file_name: 'bar.jpg', type: 'Folio::Image', thumb: 'foo/bar.jpg', source_url: 'foo/bar.jpg', url: '/foo/bar.jpg', dominant_color: '#2F312F', tags: [], placements: [], extension: 'JPEG' }, links: { edit: '/console/images/999/edit' } }

describe('filePlacementsReducer', () => {
  let state

  beforeEach(() => {
    state = filePlacementsReducer(initialState, setOriginalPlacements('Folio::Image', mockImages))
  })

  it('setOriginalPlacements', () => {
    expect(state['Folio::Image'].original).toEqual(mockImages)
    expect(state['Folio::Image'].selected).toEqual(mockImages)
  })

  it('setAttachmentable', () => {
    state = filePlacementsReducer(state, setAttachmentable('Folio::Image', 'menu'))
    expect(state['Folio::Image'].attachmentable).toEqual('menu')
  })

  it('selectFile', () => {
    expect(state['Folio::Image'].selected.length).toEqual(3)
    state = filePlacementsReducer(state, selectFile('Folio::Image', fileMock))
    expect(state['Folio::Image'].selected.length).toEqual(4)
  })

  it('unselectFilePlacement', () => {
    expect(state['Folio::Image'].selected.length).toEqual(3)
    state = filePlacementsReducer(state, unselectFilePlacement('Folio::Image', mockImages[0]))
    expect(state['Folio::Image'].selected.length).toEqual(2)
  })

  it('onSortEnd', () => {
    expect(state['Folio::Image'].selected[0].id).toEqual(1)
    expect(state['Folio::Image'].selected[1].id).toEqual(2)
    expect(state['Folio::Image'].selected[2].id).toEqual(3)
    state = filePlacementsReducer(state, onSortEnd('Folio::Image', 2, 0))
    expect(state['Folio::Image'].selected[0].id).toEqual(3)
    expect(state['Folio::Image'].selected[1].id).toEqual(1)
    expect(state['Folio::Image'].selected[2].id).toEqual(2)
  })

  it('setPlacementType', () => {
    state = filePlacementsReducer(state, setPlacementType('Folio::Image', 'foo_placements'))
    expect(state['Folio::Image'].placementType).toEqual('foo_placements')
  })

  it('changeTitle', () => {
    expect(state['Folio::Image'].selected[0]['title']).toEqual(undefined)
    state = filePlacementsReducer(state, changeTitle('Folio::Image', mockImages[0], 'foo'))
    expect(state['Folio::Image'].selected[0]['title']).toEqual('foo')
  })

  it('changeAlt', () => {
    expect(state['Folio::Image'].selected[0]['alt']).toEqual(undefined)
    state = filePlacementsReducer(state, changeAlt('Folio::Image', mockImages[0], 'foo'))
    expect(state['Folio::Image'].selected[0]['alt']).toEqual('foo')
  })
})
