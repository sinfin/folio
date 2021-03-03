import React from 'react'
import { connect } from 'react-redux'
import SortableTree, { removeNodeAtPath } from 'react-sortable-tree'
import { Button } from 'reactstrap'

import 'react-sortable-tree/style.css'

import {
  orderedMultiselectSelector,
  addItem,
  updateItems,
  removeItem
} from 'ducks/orderedMultiselect'

import Item from './Item'
import Serialized from './Serialized'

const getNodeKey = ({ treeIndex }) => treeIndex

function OrderedMultiselectApp ({ orderedMultiselect, onChange, makeOnMenuItemChange, makeOnMenuItemRemove, add }) {
  const itemOnRemove = makeOnMenuItemRemove(orderedMultiselect.items)

  return (
    <div className='f-c-r-ordered-multiselect-app'>
      <SortableTree
        maxDepth={1}
        rowHeight={34}
        treeData={orderedMultiselect.items}
        onChange={onChange}
        isVirtualized={false}
        generateNodeProps={({ node, path }) => ({
          title: (
            <Item
              node={node}
              path={path}
              remove={itemOnRemove}
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
  return {
    add: () => { dispatch(addItem()) },
    onChange: (treeData) => { dispatch(updateItems(treeData)) },
    makeOnMenuItemRemove: (items) => (path, removed) => {
      const tree = removeNodeAtPath({ treeData: items, path, getNodeKey })

      dispatch(
        removeItem(tree, removed)
      )
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(OrderedMultiselectApp)
