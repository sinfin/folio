import React from 'react'
import { FormGroup, Input, Label } from 'reactstrap'
import { makeConfirmed } from 'utils/confirmed'

import { MENU_ITEM_URL } from 'ducks/menus'

import MenuItemWrap from './styled/MenuItemWrap'

const makeOnChange = (path, node, onChange) => (e) => {
  const newNode = {
    ...node
  }

  if (e.target.name === 'openInNew') {
    newNode.open_in_new = e.target.checked
  } else if (e.target.value === MENU_ITEM_URL || e.target.name === 'url') {
    newNode.target_id = null
    newNode.target_type = null
    newNode.rails_path = null
    if (e.target.name === 'url') {
      newNode.url = e.target.value
    } else {
      newNode.url = ''
    }
  } else {
    if (e.target.value.indexOf(' -=- ') === -1) {
      newNode.rails_path = e.target.value
      newNode.target_id = null
      newNode.target_type = null
      newNode.url = null
    } else {
      const [type, id] = e.target.value.split(' -=- ')
      newNode.target_id = id
      newNode.target_type = type
      newNode.rails_path = null
      newNode.url = null
    }
  }

  onChange(path, newNode)
}

function MenuItem ({ node, path, onChange, options, remove }) {
  let linkValue = node.rails_path

  if (node.url !== null) {
    linkValue = MENU_ITEM_URL
  }

  if (!linkValue) {
    linkValue = `${node.target_type} -=- ${node.target_id}`
  }

  const onChangeFn = makeOnChange(path, node, onChange)

  return (
    <MenuItemWrap className='form-inline'>
      <Label className='mr-h'>{window.FolioConsole.translations.title}:</Label>

      <Input
        className='mr-g'
        value={node.title || ''}
        onChange={(e) => onChange(path, { ...node, title: e.target.value })}
        autoFocus={node.id === null}
      />

      <Label className='mr-h'>{window.FolioConsole.translations.link}:</Label>

      <Input
        type='select'
        value={linkValue || ''}
        onChange={onChangeFn}
        className='mr-g'
      >
        {options}
      </Input>

      {node.url !== null && (
        <React.Fragment>
          <Label className='mr-h'>URL:</Label>

          <Input
            type='string'
            value={node.url}
            onChange={onChangeFn}
            name='url'
            className='mr-g'
          />
        </React.Fragment>
      )}

      <FormGroup check className='mr-g'>
        <Label check>
          <Input
            type='checkbox'
            checked={!!node.open_in_new}
            onChange={onChangeFn}
            name='openInNew'
          />{' '}

          {window.FolioConsole.translations.menuItemOpenInNew}
        </Label>
      </FormGroup>

      <button
        className='btn btn-danger fa fa-times'
        type='button'
        onClick={makeConfirmed(() => remove(path, node))}
      />
    </MenuItemWrap>
  )
}

export default MenuItem
