import React from 'react'
import { connect } from 'react-redux'

import FolioUiIcon from 'components/FolioUiIcon'

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
    className='btn btn-secondary'
    onClick={onClick}
    active={active}
  >
    <FolioUiIcon name={icon} />
  </Button>
)

const DisplayButtons = ({ display, dispatch }) => (
  <div className='btn-group folio-console-react-display-controls'>
    <DisplayButton
      active={display === DISPLAY_CARDS}
      onClick={(e) => { e.currentTarget.blur(); dispatch(setCardsDisplay()) }}
      icon='th-list'
    />
    <DisplayButton
      active={display === DISPLAY_THUMBS}
      onClick={(e) => { e.currentTarget.blur(); dispatch(setThumbsDisplay()) }}
      icon='th-large'
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
