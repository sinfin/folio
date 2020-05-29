import React from 'react'
import { connect } from 'react-redux'
import SortableTree from 'react-sortable-tree'

import 'react-sortable-tree/style.css'

import {
  ancestrySelector,
  updateAncestry
} from 'ducks/ancestry'

import AncestryAppWrap from './styled/AncestryAppWrap'
import SerializedAncestry from './SerializedAncestry'
import AncestryItem from './AncestryItem'

function AncestryApp ({ ancestry, onChange }) {
  const onChangeWithDirty = (treeData) => {
    window.jQuery('.f-c-react-ancestry').trigger('change.folioDirtyForms')
    return onChange(treeData)
  }

  return (
    <AncestryAppWrap>
      <SortableTree
        maxDepth={ancestry.maxNestingDepth}
        rowHeight={80}
        treeData={ancestry.items}
        onChange={onChangeWithDirty}
        isVirtualized={false}
        canDrag={!ancestry.hasInvalid}
        generateNodeProps={({ node, path }) => ({
          title: <AncestryItem node={node} path={path} />
        })}
      />

      <SerializedAncestry ancestry={ancestry} />
    </AncestryAppWrap>
  )
}

const mapStateToProps = (state, props) => ({
  ancestry: ancestrySelector(state)
})

function mapDispatchToProps (dispatch) {
  return {
    onChange: (treeData) => { dispatch(updateAncestry(treeData)) }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AncestryApp)
