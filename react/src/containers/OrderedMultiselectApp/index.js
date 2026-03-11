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
    this.renameInputRef = React.createRef()
    this.state = {
      selectKey: 0,
      renamingOption: null,
      renameValue: ''
    }
  }

  componentDidMount () {
    this.wrapRef.current.addEventListener('f-c-r-ordered-multiselect-app:add-entry', this.onAddEntryEvent)
  }

  componentWillUnmount () {
    this.wrapRef.current.removeEventListener('f-c-r-ordered-multiselect-app:add-entry', this.onAddEntryEvent)
  }

  componentDidUpdate (prevProps, prevState) {
    if (this.state.renamingOption && !prevState.renamingOption && this.renameInputRef.current) {
      this.renameInputRef.current.focus()
      this.renameInputRef.current.select()
    }
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

  onCreateOption = (inputValue) => {
    const { orderedMultiselect } = this.props
    if (!orderedMultiselect.createUrl) return

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

  // Called from OptionWithActions when user clicks Rename in the sub-menu
  onStartRename = (option) => {
    this.setState({
      renamingOption: option,
      renameValue: option.label || ''
    })
  }

  onRenameSubmit = () => {
    const { renamingOption, renameValue } = this.state
    const { orderedMultiselect } = this.props
    if (!renamingOption || !orderedMultiselect.updateUrl) return

    const trimmed = renameValue.trim()
    if (!trimmed || trimmed === renamingOption.label) {
      this.setState({ renamingOption: null, renameValue: '' })
      return
    }

    const recordId = renamingOption.id || this.extractIdFromValue(renamingOption.value)

    apiPatch(orderedMultiselect.updateUrl, { id: recordId, label: trimmed })
      .then((res) => {
        if (res && res.data) {
          document.querySelector('.f-c-r-ordered-multiselect-app').dispatchEvent(new window.Event('change', { bubbles: true }))
          this.props.dispatch(renameItem(recordId, res.data.label))
          this.forceSelectRefresh()
        }
      })
      .catch((err) => {
        window.alert(err.message || 'Failed to rename record')
      })

    this.setState({ renamingOption: null, renameValue: '' })
  }

  onRenameCancel = () => {
    this.setState({ renamingOption: null, renameValue: '' })
  }

  onRenameKeyDown = (e) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      this.onRenameSubmit()
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      this.onRenameCancel()
    }
  }

  onDeleteOption = (option) => {
    const { orderedMultiselect } = this.props
    if (!orderedMultiselect.deleteUrl) return

    const recordId = option.id || this.extractIdFromValue(option.value)

    apiDelete(orderedMultiselect.deleteUrl, { id: recordId })
      .then((res) => {
        if (res && res.data) {
          let shouldDelete = false

          if (res.data.confirm_required) {
            const count = res.data.usage_count
            const msg = (window.FolioConsole.translations.deleteWarning || 'This item is assigned to %{count} other records. Deleting it will remove it from all of them. Continue?')
              .replace('%{count}', count)
            shouldDelete = window.confirm(msg)
          } else {
            shouldDelete = window.confirm(window.FolioConsole.translations.removePrompt)
          }

          if (shouldDelete) {
            apiDelete(orderedMultiselect.deleteUrl, { id: recordId, confirmed: 'true' })
              .then(() => {
                document.querySelector('.f-c-r-ordered-multiselect-app').dispatchEvent(new window.Event('change', { bubbles: true }))
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
    const { renamingOption, renameValue } = this.state
    const without = orderedMultiselect.items.map((item) => item.value).join(',')
    const url = `${orderedMultiselect.url}&without=${without}`
    const selectKey = `${without}-${this.state.selectKey}`

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

        {renamingOption ? (
          <div className='f-c-r-ordered-multiselect-app__rename'>
            <input
              ref={this.renameInputRef}
              className='f-c-r-ordered-multiselect-app__rename-input'
              value={renameValue}
              onChange={(e) => this.setState({ renameValue: e.target.value })}
              onKeyDown={this.onRenameKeyDown}
              onBlur={this.onRenameSubmit}
              placeholder={renamingOption.label}
            />
          </div>
        ) : (
          <Select
            onChange={this.onSelect}
            createable={orderedMultiselect.createable}
            onCreateOption={orderedMultiselect.createable ? this.onCreateOption : undefined}
            onStartRename={orderedMultiselect.createable ? this.onStartRename : undefined}
            onDeleteOption={orderedMultiselect.createable ? this.onDeleteOption : undefined}
            isClearable={false}
            async={url}
            placeholder={window.FolioConsole.translations.addPlaceholder}
            key={selectKey}
            defaultOptions
            addAtomSettings
            menuPlacement={orderedMultiselect.menuPlacement}
          />
        )}

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
