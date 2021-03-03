import React from 'react'
import { connect } from 'react-redux'
import SortableTree from 'react-sortable-tree'

import 'react-sortable-tree/style.css'

import {
  orderedMultiselectSelector,
  addItem,
  updateItems,
  removeItem
} from 'ducks/orderedMultiselect'

import Item from './Item'
import Serialized from './Serialized'

function OrderedMultiselectApp ({ orderedMultiselect, dispatch }) {
  return (
    <div className='f-c-r-ordered-multiselect-app'>
      <SortableTree
        maxDepth={1}
        rowHeight={34}
        treeData={orderedMultiselect.items}
        onChange={(items) => { dispatch(updateItems(items)) }}
        isVirtualized={false}
        generateNodeProps={({ node, path }) => ({
          title: (
            <Item
              node={node}
              path={path}
              remove={(item) => { dispatch(removeItem(item)) }}
            />
          )
        })}
      />

      <Serialized orderedMultiselect={orderedMultiselect} />
    </div>
  )
}

const mapStateToProps = (state, props) => ({
  orderedMultiselect: orderedMultiselectSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(OrderedMultiselectApp)
