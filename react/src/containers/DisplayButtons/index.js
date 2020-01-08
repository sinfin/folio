import React from 'react'
import { connect } from 'react-redux'

import {
  DISPLAY_CARDS,
  DISPLAY_THUMBS,
  setCardsDisplay,
  setThumbsDisplay,
  displaySelector
} from 'ducks/display'

import Button from './styled/Button'

const DisplayButton = ({ active, onClick, icon }) => (
  <Button
    type='button'
    className={`btn btn-secondary ${icon}`}
    onClick={onClick}
    active={active}
  />
)

const DisplayButtons = ({ display, dispatch }) => (
  <div className='btn-group folio-console-react-display-controls'>
    <DisplayButton
      active={display === DISPLAY_CARDS}
      onClick={() => { dispatch(setCardsDisplay()) }}
      icon='fa fa-th-list'
    />
    <DisplayButton
      active={display === DISPLAY_THUMBS}
      onClick={() => { dispatch(setThumbsDisplay()) }}
      icon='fa fa-th-large'
    />
  </div>
)

const mapStateToProps = (state, props) => ({
  display: displaySelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(DisplayButtons)
