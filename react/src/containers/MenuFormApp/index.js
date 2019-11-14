import React from 'react'
import { connect } from 'react-redux'
import SortableTree, { changeNodeAtPath, removeNodeAtPath } from 'react-sortable-tree'
import { Button } from 'reactstrap'

import 'react-sortable-tree/style.css'

import { menusSelector, addItem, updateItems, removeItem } from 'ducks/menus'

import MenuFormAppWrap from './styled/MenuFormAppWrap'
import MenuItem from './MenuItem'
import SerializedMenu from './SerializedMenu'

const getNodeKey = ({ treeIndex }) => treeIndex

function MenuFormApp ({ menus, onChange, makeOnMenuItemChange, makeOnMenuItemRemove, add }) {
  const itemOnChange = makeOnMenuItemChange(menus.items)
  const itemOnRemove = makeOnMenuItemRemove(menus.items)

  const options = menus.paths.map((path, i) => {
    const value = path.rails_path || `${path.target_type} -=- ${path.target_id}`
    return (
      <option
        key={i}
        value={value}
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

      <div className='my-4'>
        <Button color='success' type='button' onClick={add}>
          {window.FolioConsole.translations.add}
        </Button>
      </div>

      <SerializedMenu menus={menus} />
    </MenuFormAppWrap>
  )
}

const mapStateToProps = (state, props) => ({
  menus: menusSelector(state)
})

function mapDispatchToProps (dispatch) {
  return {
    add: () => { dispatch(addItem()) },
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
