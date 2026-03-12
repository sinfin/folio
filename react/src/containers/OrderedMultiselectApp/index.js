import React from 'react'
import { connect } from 'react-redux'
import SortableTree from 'react-sortable-tree'

import 'react-sortable-tree/style.css'

import {
  orderedMultiselectSelector,
  addItem,
  updateItems,
  removeItem,
  renameItem,
  removeDeletedItem
} from 'ducks/orderedMultiselect'

import { apiPost, apiPatch, apiDelete } from 'utils/api'
import Select from 'components/Select'

import Item from './Item'
import Serialized from './Serialized'

class OrderedMultiselectApp extends React.Component {
  constructor (props) {
    super(props)
    this.wrapRef = React.createRef()
    this.state = {
      selectKey: 0,
      menuIsOpen: undefined,
      inlineEditing: false,
      loadedOptions: []
    }
  }

  onEditingChange = (isEditing) => {
    if (isEditing) {
      this.setState({ menuIsOpen: true, inlineEditing: true })
    } else {
      this.setState({ inlineEditing: false })
    }
  }

  onLoadedOptionsChange = (options) => {
    this.setState({ loadedOptions: options })
  }

  onMenuClose = () => {
    if (this.state.inlineEditing) return
    this.setState({ menuIsOpen: undefined })
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
    let itemId = option.id
    if (itemId === undefined && typeof option.value === 'string' && option.value.includes(' -=- ')) {
      const parts = option.value.split(' -=- ')
      itemId = parts.length > 1 ? parts[1] : option.value
    } else if (itemId === undefined) {
      itemId = option.value
    }

    const item = {
      id: itemId,
      label: option.label
    }
    this.wrapRef.current.dispatchEvent(new window.Event('change', { bubbles: true }))
    this.props.dispatch(addItem(item))
  }

  update = (items) => {
    this.wrapRef.current.dispatchEvent(new window.Event('change', { bubbles: true }))
    this.props.dispatch(updateItems(items))
  }

  removeItem = (item) => {
    this.wrapRef.current.dispatchEvent(new window.Event('change', { bubbles: true }))
    this.props.dispatch(removeItem(item))
  }

  onCreateOption = (inputValue) => {
    const { orderedMultiselect } = this.props
    if (!orderedMultiselect.createUrl) return

    const normalized = inputValue.toLowerCase().trim()

    const selectedDuplicate = orderedMultiselect.items.find(
      (item) => item.label.toLowerCase().trim() === normalized
    )
    if (selectedDuplicate) {
      window.alert(window.FolioConsole.translations.alreadyExists || 'An item with this name already exists.')
      return
    }

    const loadedDuplicate = this.state.loadedOptions.find(
      (opt) => opt.label && opt.label.toLowerCase().trim() === normalized
    )
    if (loadedDuplicate) {
      window.alert(window.FolioConsole.translations.alreadyExists || 'An item with this name already exists.')
      return
    }

    apiPost(orderedMultiselect.createUrl, { label: inputValue })
      .then((res) => {
        if (res && res.data) {
          this.onSelect(res.data)
          this.forceSelectRefresh()
        }
      })
      .catch((err) => {
        window.alert(err.message || 'Failed to create record')
      })
  }

  onRenameSubmit = (option, newLabel) => {
    const { orderedMultiselect } = this.props
    if (!orderedMultiselect.updateUrl) return

    // Always use option.value (the record's own ID), not option.id
    // which may be a join-table ID for server-loaded items.
    const recordId = this.extractIdFromValue(option.value)

    apiPatch(orderedMultiselect.updateUrl, { id: recordId, label: newLabel })
      .then((res) => {
        if (res && res.data) {
          this.props.dispatch(renameItem(recordId, res.data.label))
        }
      })
      .catch((err) => {
        window.alert(err.message || 'Failed to rename record')
      })
  }

  onDeleteOption = (option) => {
    const { orderedMultiselect } = this.props
    if (!orderedMultiselect.deleteUrl) return

    const recordId = this.extractIdFromValue(option.value)

    apiDelete(orderedMultiselect.deleteUrl, { id: recordId })
      .then((res) => {
        if (res && res.data) {
          let shouldDelete = false

          if (res.data.confirm_required) {
            const labels = res.data.usage_labels
            let msg
            if (labels && labels.length > 0) {
              const list = labels.map((l) => `- ${l}`).join('\n')
              msg = (window.FolioConsole.translations.deleteWarningWithLabels || 'This item is assigned to %{count} records:\n%{list}\n\nDeleting it from the database will remove it from all of them.')
                .replace('%{count}', labels.length)
                .replace('%{list}', list)
            } else {
              msg = (window.FolioConsole.translations.deleteWarning || 'This item is assigned to %{count} other records. Deleting it will remove it from all of them. Continue?')
                .replace('%{count}', res.data.usage_count)
            }
            shouldDelete = window.confirm(msg)
          } else {
            shouldDelete = window.confirm(window.FolioConsole.translations.deleteFromDbConfirm || 'Delete this record from database?')
          }

          if (shouldDelete) {
            apiDelete(orderedMultiselect.deleteUrl, { id: recordId, confirmed: 'true' })
              .then(() => {
                this.wrapRef.current.dispatchEvent(new window.Event('change', { bubbles: true }))
                this.props.dispatch(removeDeletedItem(recordId))
                this.forceSelectRefresh()
              })
              .catch((err) => {
                window.alert(err.message || 'Failed to delete record')
              })
          }
        }
      })
      .catch((err) => {
        window.alert(err.message || 'Failed to delete record')
      })
  }

  extractIdFromValue (value) {
    if (typeof value === 'string' && value.includes(' -=- ')) {
      const parts = value.split(' -=- ')
      return parts.length > 1 ? parts[1] : value
    }
    return value
  }

  forceSelectRefresh () {
    this.setState((prev) => ({ selectKey: prev.selectKey + 1 }))
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
    const selectKey = `${without}-${this.state.selectKey}`
    const { menuIsOpen } = this.state
    const existingLabels = orderedMultiselect.createable
      ? orderedMultiselect.items.map((item) => item.label)
      : undefined

    return (
      <div
        className='f-c-r-ordered-multiselect-app'
        ref={this.wrapRef}
        data-atom-setting-value={this.settingValue()}
        onKeyDown={orderedMultiselect.createable ? (e) => { if (e.key === 'Enter') e.preventDefault() } : undefined}
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
                  onRename={orderedMultiselect.createable ? this.onRenameSubmit : undefined}
                  existingLabels={orderedMultiselect.createable ? existingLabels : undefined}
                  loadedOptions={orderedMultiselect.createable ? this.state.loadedOptions : undefined}
                />
              )
            })}
          />
        ) : null}

        <Select
          onChange={this.onSelect}
          createable={orderedMultiselect.createable}
          onCreateOption={orderedMultiselect.createable ? this.onCreateOption : undefined}
          onRenameSubmit={orderedMultiselect.createable ? this.onRenameSubmit : undefined}
          onDeleteOption={orderedMultiselect.createable ? this.onDeleteOption : undefined}
          onEditingChange={orderedMultiselect.createable ? this.onEditingChange : undefined}
          onMenuClose={orderedMultiselect.createable ? this.onMenuClose : undefined}
          onLoadedOptionsChange={orderedMultiselect.createable ? this.onLoadedOptionsChange : undefined}
          menuIsOpen={menuIsOpen}
          existingLabels={existingLabels}
          isClearable={false}
          async={url}
          placeholder={window.FolioConsole.translations.addPlaceholder}
          key={selectKey}
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
