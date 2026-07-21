import 'folioTestSetup'

import orderedMultiselectReducer, {
  addItem,
  setOrderedMultiselectData
} from '../orderedMultiselect'

describe('orderedMultiselectReducer', () => {
  it('does not add more items than the configured limit', () => {
    let state = orderedMultiselectReducer(undefined, setOrderedMultiselectData({
      items: [],
      removedItems: [],
      maxItems: 3
    }))

    state = orderedMultiselectReducer(state, addItem({ id: 123, label: 'First' }))
    state = orderedMultiselectReducer(state, addItem({ id: 456, label: 'Second' }))
    state = orderedMultiselectReducer(state, addItem({ id: 789, label: 'Third' }))
    state = orderedMultiselectReducer(state, addItem({ id: 101, label: 'Fourth' }))

    expect(state.items.map((item) => item.value)).toEqual([123, 456, 789])
  })
})
