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
const fileMock = { id: '999', type: 'file', attributes: { id: 999, file_size: 326774, file_name: 'bar.jpg', type: 'Folio::Image', thumb: 'foo/bar.jpg', source_image: 'foo/bar.jpg', url: '/foo/bar.jpg', dominant_color: '#2F312F', tags: [], placements: [], extension: 'JPEG' }, links: { edit: '/console/images/999/edit' } }

describe('filePlacementsReducer', () => {
  let state

  beforeEach(() => {
    state = filePlacementsReducer(initialState, setOriginalPlacements('images', mockImages))
  })

  it('setOriginalPlacements', () => {
    expect(state['images'].original).toEqual(mockImages)
    expect(state['images'].selected).toEqual(mockImages)
  })

  it('setAttachmentable', () => {
    state = filePlacementsReducer(state, setAttachmentable('images', 'menu'))
    expect(state['images'].attachmentable).toEqual('menu')
  })

  it('selectFile', () => {
    expect(state['images'].selected.length).toEqual(3)
    state = filePlacementsReducer(state, selectFile('images', fileMock))
    expect(state['images'].selected.length).toEqual(4)
  })

  it('unselectFilePlacement', () => {
    expect(state['images'].selected.length).toEqual(3)
    state = filePlacementsReducer(state, unselectFilePlacement('images', mockImages[0]))
    expect(state['images'].selected.length).toEqual(2)
  })

  it('onSortEnd', () => {
    expect(state['images'].selected[0].id).toEqual(1)
    expect(state['images'].selected[1].id).toEqual(2)
    expect(state['images'].selected[2].id).toEqual(3)
    state = filePlacementsReducer(state, onSortEnd('images', 2, 0))
    expect(state['images'].selected[0].id).toEqual(3)
    expect(state['images'].selected[1].id).toEqual(1)
    expect(state['images'].selected[2].id).toEqual(2)
  })

  it('setPlacementType', () => {
    state = filePlacementsReducer(state, setPlacementType('images', 'foo_placements'))
    expect(state['images'].placementType).toEqual('foo_placements')
  })

  it('changeTitle', () => {
    expect(state['images'].selected[0]['title']).toEqual(undefined)
    state = filePlacementsReducer(state, changeTitle('images', mockImages[0], 'foo'))
    expect(state['images'].selected[0]['title']).toEqual('foo')
  })

  it('changeAlt', () => {
    expect(state['images'].selected[0]['alt']).toEqual(undefined)
    state = filePlacementsReducer(state, changeAlt('images', mockImages[0], 'foo'))
    expect(state['images'].selected[0]['alt']).toEqual('foo')
  })
})
