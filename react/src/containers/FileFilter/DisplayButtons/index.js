import React from 'react'

import {
  DISPLAY_CARDS,
  DISPLAY_THUMBS,
} from 'ducks/display'

import Button from './styled/Button';
import Wrap from './styled/Wrap';

const DisplayButton = ({ active, onClick, icon }) => (
  <Button
    type="button"
    className={'btn btn-secondary'}
    onClick={onClick}
    active={active}
  >
    <i className={icon}></i>
  </Button>
)

const DisplayButtons = ({ display, setCardsDisplay, setThumbsDisplay }) => (
  <Wrap className='btn-group'>
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
