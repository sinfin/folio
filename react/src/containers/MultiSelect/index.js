import React, { Component } from 'react'
import { connect } from 'react-redux'

import {
  imagesSelector,
  selectImage,
  unselectImage,
} from 'ducks/images'

import Image from 'components/Image'
import Loader from 'components/Loader'
import Card from 'components/Card'

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
          {images.selected.map((image) => (
            <Image
              image={image}
              key={image.id}
              onClick={() => dispatch(unselectImage(image))}
              selected
            />
          ))}
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
