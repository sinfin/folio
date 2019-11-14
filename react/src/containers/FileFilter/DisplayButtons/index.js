import React from 'react'

import {
  DISPLAY_CARDS,
  DISPLAY_THUMBS
} from 'ducks/display'

import Button from './styled/Button'
import Wrap from './styled/Wrap'

const DisplayButton = ({ active, onClick, icon }) => (
  <Button
    type='button'
    className={`btn btn-secondary ${icon}`}
    onClick={onClick}
    active={active}
  />
)

const DisplayButtons = ({ display, setCardsDisplay, setThumbsDisplay }) => (
  <Wrap className='btn-group folio-console-react-display-controls'>
    <DisplayButton
      active={display === DISPLAY_CARDS}
      onClick={setCardsDisplay}
      icon='fa fa-th-list'
    />
    <DisplayButton
      active={display === DISPLAY_THUMBS}
      onClick={setThumbsDisplay}
      icon='fa fa-th-large'
    />
  </Wrap>
)

export default DisplayButtons
