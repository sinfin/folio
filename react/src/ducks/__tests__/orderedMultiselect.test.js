import reducer, {
  addItem,
  removeItem,
  renameItem,
  removeDeletedItem,
  updateItems
} from '../orderedMultiselect'

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeItem (value, label, id = null) {
  return { value, label, id, uniqueId: String(value) }
}

function stateWith (items) {
  return { items, removedItems: [] }
}

// ---------------------------------------------------------------------------
// addItem
// ---------------------------------------------------------------------------

describe('addItem', () => {
  test('adds a new item to the list', () => {
    const state = stateWith([])
    const next = reducer(state, addItem({ id: 1, label: 'Foo' }))
    expect(next.items).toHaveLength(1)
    expect(next.items[0].value).toBe(1)
    expect(next.items[0].label).toBe('Foo')
  })

  test('does not add a duplicate (same value already in items)', () => {
    const state = stateWith([makeItem(1, 'Foo')])
    const next = reducer(state, addItem({ id: 1, label: 'Foo' }))
    expect(next.items).toHaveLength(1)
  })
})

// ---------------------------------------------------------------------------
// removeItem
// ---------------------------------------------------------------------------

describe('removeItem', () => {
  test('removes item by uniqueId', () => {
    const item = makeItem(5, 'Bar')
    const state = stateWith([item])
    const next = reducer(state, removeItem(item))
    expect(next.items).toHaveLength(0)
  })

  test('moves item with an id to removedItems', () => {
    const item = makeItem(5, 'Bar', 99) // id = 99 (join-table id)
    const state = stateWith([item])
    const next = reducer(state, removeItem(item))
    expect(next.removedItems).toHaveLength(1)
    expect(next.removedItems[0].id).toBe(99)
  })

  test('does not add to removedItems when item has no id', () => {
    const item = makeItem(5, 'Bar', null)
    const state = stateWith([item])
    const next = reducer(state, removeItem(item))
    expect(next.removedItems).toHaveLength(0)
  })
})

// ---------------------------------------------------------------------------
// renameItem
// ---------------------------------------------------------------------------

describe('renameItem', () => {
  test('renames the item with matching value', () => {
    const state = stateWith([makeItem(5, 'Old Name')])
    const next = reducer(state, renameItem(5, 'New Name'))
    expect(next.items[0].label).toBe('New Name')
  })

  test('matches by value even when stored as string and action as number', () => {
    const state = stateWith([makeItem('5', 'Old')])
    const next = reducer(state, renameItem(5, 'New'))
    expect(next.items[0].label).toBe('New')
  })

  test('does not rename other items', () => {
    const state = stateWith([makeItem(1, 'One'), makeItem(2, 'Two')])
    const next = reducer(state, renameItem(1, 'One Renamed'))
    expect(next.items[0].label).toBe('One Renamed')
    expect(next.items[1].label).toBe('Two')
  })
})

// ---------------------------------------------------------------------------
// removeDeletedItem
// ---------------------------------------------------------------------------

describe('removeDeletedItem', () => {
  test('removes from items list', () => {
    const state = stateWith([makeItem(3, 'Delete Me')])
    const next = reducer(state, removeDeletedItem(3))
    expect(next.items).toHaveLength(0)
  })

  test('removes from removedItems list as well', () => {
    const state = { items: [], removedItems: [makeItem(3, 'Delete Me')] }
    const next = reducer(state, removeDeletedItem(3))
    expect(next.removedItems).toHaveLength(0)
  })

  test('matches by value even with type mismatch (string vs number)', () => {
    const state = stateWith([makeItem('7', 'Type Mismatch Test')])
    const next = reducer(state, removeDeletedItem(7))
    expect(next.items).toHaveLength(0)
  })
})

// ---------------------------------------------------------------------------
// updateItems (reordering)
// ---------------------------------------------------------------------------

describe('updateItems', () => {
  test('replaces items entirely (used for drag-and-drop reorder)', () => {
    const original = [makeItem(1, 'A'), makeItem(2, 'B')]
    const state = stateWith(original)
    const reordered = [makeItem(2, 'B'), makeItem(1, 'A')]
    const next = reducer(state, updateItems(reordered))
    expect(next.items[0].value).toBe(2)
    expect(next.items[1].value).toBe(1)
  })
})
