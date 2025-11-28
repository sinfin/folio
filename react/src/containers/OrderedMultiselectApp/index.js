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

import Select from 'components/Select'

import Item from './Item'
import Serialized from './Serialized'

class OrderedMultiselectApp extends React.Component {
  constructor (props) {
    super(props)
    this.wrapRef = React.createRef()
  }

  componentDidMount () {
    this.wrapRef.current.addEventListener('f-c-r-ordered-multiselect-app:add-entry', this.onAddEntryEvent)
  }

  componentWillUnmount () {
    this.wrapRef.current.removeEventListener('f-c-r-ordered-multiselect-app:add-entry', this.onAddEntryEvent)
  }

  onAddEntryEvent = (e) => {
    if (!e || !e.detail || !e.detail.entry) return
    this.onSelect(e.detail.entry)
  }

  onSelect = (option) => {
    // option is {value, label, id} from react-select
    // value is the STI string like "Economia::List::Category -=- 310"
    // id is the numeric ID like 310
    // Use id for the item ID, fallback to extracting from value if id not available
    let itemId = option.id
    if (itemId === undefined && typeof option.value === 'string' && option.value.includes(' -=- ')) {
      // Extract numeric ID from STI format: "Class -=- 48" -> 48
      const parts = option.value.split(' -=- ')
      itemId = parts.length > 1 ? parts[1] : option.value
    } else if (itemId === undefined) {
      // Fallback to value if no id available
      itemId = option.value
    }

    // Transform to {id, label} format expected by Redux
    const item = {
      id: itemId,
      label: option.label
    }
    document.querySelector('.f-c-r-ordered-multiselect-app').dispatchEvent(new window.Event('change', { bubbles: true }))
    this.props.dispatch(addItem(item))
  }

  update = (items) => {
    document.querySelector('.f-c-r-ordered-multiselect-app').dispatchEvent(new window.Event('change', { bubbles: true }))
    this.props.dispatch(updateItems(items))
  }

  removeItem = (item) => {
    document.querySelector('.f-c-r-ordered-multiselect-app').dispatchEvent(new window.Event('change', { bubbles: true }))
    this.props.dispatch(removeItem(item))
  }

  settingValue () {
    if (this.props.orderedMultiselect.atomSetting) {
      return JSON.stringify(this.props.orderedMultiselect.items.map((item) => item.value))
    } else {
      return undefined
    }
  }

  render () {
    const { orderedMultiselect } = this.props
    const without = orderedMultiselect.items.map((item) => item.value).join(',')
    const url = `${orderedMultiselect.url}&without=${without}`

    // using key={without} forces Select to reload default options

    return (
      <div
        className={`f-c-r-ordered-multiselect-app`}
        ref={this.wrapRef}
        data-atom-setting-value={this.settingValue()}
      >
        {orderedMultiselect.atomSetting ? (
          <div
            hidden
            data-atom-setting={orderedMultiselect.atomSetting}
            data-atom-setting-value-json={this.settingValue()}
            className='f-c-js-atoms-placement-setting'
          />
        ) : null}

        {orderedMultiselect.items.length ? (
          <SortableTree
            maxDepth={1}
            rowHeight={34}
            treeData={orderedMultiselect.items}
            onChange={this.update}
            isVirtualized={false}
            generateNodeProps={({ node, path }) => ({
              title: (
                <Item
                  node={node}
                  path={path}
                  remove={this.removeItem}
                />
              )
            })}
          />
        ) : null}

        <Select
          onChange={this.onSelect}
          createable={false}
          isClearable={false}
          async={url}
          placeholder={window.FolioConsole.translations.addPlaceholder}
          key={without}
          defaultOptions
          addAtomSettings
          menuPlacement={orderedMultiselect.menuPlacement}
        />

        <Serialized orderedMultiselect={orderedMultiselect} />
      </div>
    )
  }
}

const mapStateToProps = (state, props) => ({
  orderedMultiselect: orderedMultiselectSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(OrderedMultiselectApp)
