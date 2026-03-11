import React, { useState, useRef, useEffect, useCallback } from 'react'
import { components } from 'react-select'
import FolioUiIcon from 'components/FolioUiIcon'

const ACTION_AREA_ATTR = 'data-owa-action'

function isActionAreaClick (e) {
  return e.target.closest && e.target.closest(`[${ACTION_AREA_ATTR}]`)
}

function OptionWithActions (props) {
  const { data, selectProps, innerProps } = props
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState('')
  const inputRef = useRef(null)

  const isNew = data.__isNew__

  useEffect(() => {
    if (isEditing && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [isEditing])

  const onRenameClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    setEditValue(data.label || '')
    setIsEditing(true)
  }, [data])

  const onDeleteClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    selectProps.onDeleteOption && selectProps.onDeleteOption(data)
  }, [selectProps, data])

  const onRenameSubmit = useCallback(() => {
    const trimmed = editValue.trim()
    if (trimmed && trimmed !== data.label) {
      selectProps.onRenameSubmit && selectProps.onRenameSubmit(data, trimmed)
    }
    setIsEditing(false)
  }, [editValue, data, selectProps])

  const onRenameCancel = useCallback(() => {
    setIsEditing(false)
  }, [])

  const onInputKeyDown = useCallback((e) => {
    e.stopPropagation()
    if (e.key === 'Enter') {
      e.preventDefault()
      onRenameSubmit()
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      onRenameCancel()
    }
  }, [onRenameSubmit, onRenameCancel])

  // Create option — green + icon style
  if (isNew) {
    return (
      <components.Option {...props}>
        <span className='f-c-r-select-create-option'>
          <span className='f-c-r-select-create-option__icon'>+</span>
          {props.children}
        </span>
      </components.Option>
    )
  }

  // Override innerProps to prevent react-select from selecting/closing
  // when clicking on the action area (icon buttons, rename input)
  const wrappedInnerProps = {
    ...innerProps,
    onClick: (e) => {
      if (isActionAreaClick(e)) return
      innerProps.onClick && innerProps.onClick(e)
    },
    onMouseDown: (e) => {
      if (isActionAreaClick(e)) {
        e.preventDefault()
        return
      }
      innerProps.onMouseDown && innerProps.onMouseDown(e)
    },
    onMouseUp: (e) => {
      if (isActionAreaClick(e)) return
      innerProps.onMouseUp && innerProps.onMouseUp(e)
    }
  }

  return (
    <components.Option {...props} innerProps={wrappedInnerProps}>
      <div className='f-c-r-select-option-with-actions'>
        {isEditing ? (
          <div className='f-c-r-select-option-with-actions__edit' data-owa-action='true'>
            <input
              ref={inputRef}
              className='f-c-r-select-option-with-actions__edit-input'
              value={editValue}
              onChange={(e) => setEditValue(e.target.value)}
              onKeyDown={onInputKeyDown}
              onBlur={onRenameSubmit}
              onMouseDown={(e) => e.stopPropagation()}
            />
          </div>
        ) : (
          <>
            <span className='f-c-r-select-option-with-actions__label'>
              {props.children}
            </span>
            <span
              className='f-c-r-select-option-with-actions__action'
              onClick={onRenameClick}
              data-owa-action='true'
              title={window.FolioConsole.translations.rename || 'Rename'}
            >
              <FolioUiIcon name='edit_box' height={16} />
            </span>
            <span
              className='f-c-r-select-option-with-actions__action f-c-r-select-option-with-actions__action--danger'
              onClick={onDeleteClick}
              data-owa-action='true'
              title={window.FolioConsole.translations.deleteFromDb || 'Delete'}
            >
              <FolioUiIcon name='delete' height={16} />
            </span>
          </>
        )}
      </div>
    </components.Option>
  )
}

export default OptionWithActions
