import React, { Component } from 'react'
import { connect } from 'react-redux'
import { SortableContainer, SortableElement } from 'react-sortable-hoc'

import {
  imagesSelector,
  selectImage,
  unselectImage,
  onSortEnd,
} from 'ducks/images'

import Image from 'components/Image'
import Loader from 'components/Loader'
import Card from 'components/Card'

const SortableList = SortableContainer(({ items, dispatch }) => {
  return (
    <div>
      {items.map((image, index) => (
        <SortableItem key={image.id} index={index} image={image} dispatch={dispatch} />
      ))}
    </div>
  )
})

const SortableItem = SortableElement(({ image, dispatch }) => {
  return (
    <Image
      image={image}
      key={image.id}
      onClick={() => dispatch(unselectImage(image))}
      selected
    />
  )
})

class MultiSelect extends Component {
  render() {
    const { images, dispatch } = this.props
    if (images.loading) return <Loader />

    return (
      <div>
        <Card
          highlighted
          header='Selected'
        >
          <SortableList
            items={images.selected}
            onSortEnd={({ oldIndex, newIndex }) => dispatch(onSortEnd(oldIndex, newIndex))}
            dispatch={dispatch}
            axis='xy'
          />
        </Card>

        <Card
          header='Available'
          filters='filter?'
        >
          {images.selectable.map((image) => (
            <Image
              image={image}
              key={image.id}
              onClick={() => dispatch(selectImage(image))}
              selected={false}
            />
          ))}
        </Card>
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  images: imagesSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
