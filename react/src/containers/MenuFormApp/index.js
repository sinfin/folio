import React from 'react'
import { connect } from 'react-redux'
import SortableTree, { changeNodeAtPath, removeNodeAtPath } from 'react-sortable-tree'

import 'react-sortable-tree/style.css'

import { menusSelector, updateItems, removeItem } from 'ducks/menus'

import MenuFormAppWrap from './styled/MenuFormAppWrap'
import MenuItem from './MenuItem'
import SerializedMenu from './SerializedMenu'

const getNodeKey = ({ treeIndex }) => treeIndex

function MenuFormApp ({ menus, onChange, makeOnMenuItemChange, makeOnMenuItemRemove }) {
  const itemOnChange = makeOnMenuItemChange(menus.items)
  const itemOnRemove = makeOnMenuItemRemove(menus.items)

  const options = menus.paths.map((path, i) => {
    const value = path.rails_path || `${path.target_type} - ${path.target_id}`
    return (
      <option
        key={i}
        value={value}
        data-targetid={path.target_id}
        data-targettype={path.target_type}
        data-railspath={path.rails_path}
      >
        {path.title}
      </option>
    )
  })

  return (
    <MenuFormAppWrap>
      <SortableTree
        maxDepth={menus.maxNestingDepth}
        rowHeight={80}
        treeData={menus.items}
        onChange={onChange}
        isVirtualized={false}
        generateNodeProps={({ node, path }) => ({
          title: <MenuItem node={node} path={path} onChange={itemOnChange} options={options} remove={itemOnRemove} />
        })}
      />

      <SerializedMenu menus={menus} />
    </MenuFormAppWrap>
  )
}

const mapStateToProps = (state, props) => ({
  menus: menusSelector(state)
})

function mapDispatchToProps (dispatch) {
  return {
    onChange: (treeData) => { dispatch(updateItems(treeData)) },
    makeOnMenuItemChange: (items) => (path, newNode) => {
      dispatch(
        updateItems(
          changeNodeAtPath({
            treeData: items,
            path,
            newNode,
            getNodeKey
          })
        )
      )
    },
    makeOnMenuItemRemove: (items) => (path, removed) => {
      const tree = removeNodeAtPath({ treeData: items, path, getNodeKey })

      dispatch(
        removeItem(tree, removed)
      )
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(MenuFormApp)
