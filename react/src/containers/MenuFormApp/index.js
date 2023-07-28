import React from 'react'
import { connect } from 'react-redux'
import SortableTree, { changeNodeAtPath, removeNodeAtPath } from 'react-sortable-tree'

import 'react-sortable-tree/style.css'

import {
  menusSelector,
  addItem,
  updateItems,
  removeItem,
  MENU_ITEM_URL
} from 'ducks/menus'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

import MenuFormAppWrap from './styled/MenuFormAppWrap'
import MenuItem from './MenuItem'
import SerializedMenu from './SerializedMenu'

const getNodeKey = ({ treeIndex }) => treeIndex

function MenuFormApp ({ menus, onChange, makeOnMenuItemChange, makeOnMenuItemRemove, add }) {
  React.useEffect(() => {
    const $add = window.jQuery('.f-c-js-menus-form-add')
    $add.on('click', add)
    return function cleanup () {
      $add.off('click', add)
    }
  }, [add])

  const itemOnChange = makeOnMenuItemChange(menus.items)
  const itemOnRemove = makeOnMenuItemRemove(menus.items)

  const styleOptions = []
  menus.styles.forEach((ary) => {
    styleOptions.push(
      <option key={ary[1]} value={ary[1]}>{ary[0]}</option>
    )
  })

  const linkOptions = [
    { value: '', label: window.FolioConsole.translations.menuNoLink },
    { value: MENU_ITEM_URL, label: window.FolioConsole.translations.menuItemUrl }
  ]

  menus.paths.forEach((path, i) => {
    const value = path.rails_path || `${path.target_type} -=- ${path.target_id}`
    linkOptions.push({
      value: value,
      title: path.title,
      label: path.label
    })
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
          title: (
            <MenuItem
              node={node}
              path={path}
              onChange={itemOnChange}
              linkOptions={linkOptions}
              styleOptions={styleOptions}
              remove={itemOnRemove}
            />
          )
        })}
      />

      <div className='my-4'>
        <FolioConsoleUiButton
          variant='success'
          onClick={add}
          icon='plus'
          label={window.FolioConsole.translations.addMenuItem}
        />
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
