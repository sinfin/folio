import React from 'react'
import { FormGroup, Input, Label } from 'reactstrap'
import { makeConfirmed } from 'utils/confirmed'
import Select from 'components/Select'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import FolioUiIcon from 'components/FolioUiIcon'

import { MENU_ITEM_URL } from 'ducks/menus'

const makeOnChange = (path, node, onChange) => (e) => {
  const newNode = {
    ...node
  }

  if (typeof e.value === 'string') {
    if (e.value === MENU_ITEM_URL) {
      newNode.target_id = null
      newNode.target_type = null
      newNode.rails_path = null
      newNode.url = ''
    } else if (e.value.indexOf(' -=- ') === -1) {
      newNode.rails_path = e.value
      newNode.target_id = null
      newNode.target_type = null
      newNode.url = null
    } else {
      const [type, id] = e.value.split(' -=- ')
      newNode.target_id = id
      newNode.target_type = type
      newNode.rails_path = null
      newNode.url = null
    }

    newNode.title = e.title
  } else if (e.target.name === 'openInNew') {
    newNode.open_in_new = e.target.checked
  } else if (e.target.name === 'style') {
    newNode.style = e.target.value || null
  } else if (e.target.name === 'url') {
    newNode.url = e.target.value
  }

  onChange(path, newNode)
}

function MenuItem ({ node, path, onChange, linkOptions, styleOptions, remove }) {
  let linkValue = node.rails_path

  if (node.url !== null) {
    linkValue = MENU_ITEM_URL
  }

  if (!linkValue) {
    linkValue = `${node.target_type} -=- ${node.target_id}`
  }

  let linkValueHash
  linkOptions.forEach((opt) => {
    if (opt.value === linkValue) {
      linkValueHash = opt
    }
  })
  const onChangeFn = makeOnChange(path, node, onChange)

  return (
    <div className='f-c-menus-form__form'>
      <div className='f-c-menus-form__form-item'>
        <FolioUiIcon name='format_align_left' />

        <Input
          value={node.title || ''}
          onChange={(e) => onChange(path, { ...node, title: e.target.value })}
          autoFocus={node.id === null}
        />
      </div>

      <div className='f-c-menus-form__form-item'>
        <FolioUiIcon name='link' />

        <Select
          value={linkValueHash}
          onChange={onChangeFn}
          rawOptions={linkOptions}
          createable={false}
          isClearable={false}
          selectize
        />
      </div>

      {node.url !== null && (
        <div className='f-c-menus-form__form-item'>
          <FolioUiIcon name='open_in_new' />

          <Input
            type='string'
            value={node.url}
            onChange={onChangeFn}
            name='url'
          />
        </div>
      )}

      {styleOptions.length > 0 && (
        <div className={`f-c-menus-form__form-item f-c-menus-form__form-item--style-${node.style || ''}`}>
          <FolioUiIcon name='cog' />

          <Input
            type='select'
            value={node.style || ''}
            onChange={onChangeFn}
            name='style'
            className='select'
          >
            {styleOptions}
          </Input>
        </div>
      )}

      <div className='f-c-menus-form__form-item px-h'>
        <FormGroup check>
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
      </div>

      <div className='f-c-menus-form__form-item f-c-menus-form__form-item--destroy'>
        <FolioConsoleUiButton
          icon='close'
          variant='danger'
          onClick={makeConfirmed(() => remove(path, node))}
        />
      </div>
    </div>
  )
}

export default MenuItem
