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
  onSelect = (item) => {
    window.jQuery('.f-c-r-ordered-multiselect-app').trigger('change.folioDirtyForms')
    this.props.dispatch(addItem(item))
  }

  update = (items) => {
    window.jQuery('.f-c-r-ordered-multiselect-app').trigger('change.folioDirtyForms')
    this.props.dispatch(updateItems(items))
  }

  removeItem = (item) => {
    window.jQuery('.f-c-r-ordered-multiselect-app').trigger('change.folioDirtyForms')
    this.props.dispatch(removeItem(item))
  }

  render () {
    const { orderedMultiselect } = this.props
    const without = orderedMultiselect.items.map((item) => item.value).join(',')
    const url = `${orderedMultiselect.url}&without=${without}`

    // using key={without} forces Select to reload default options

    return (
      <div className='f-c-r-ordered-multiselect-app'>
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
          selectize
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
