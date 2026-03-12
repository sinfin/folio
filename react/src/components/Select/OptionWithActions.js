import React, { useState, useRef, useEffect, useCallback, useMemo } from 'react'
import { components } from 'react-select'
import FolioUiIcon from 'components/FolioUiIcon'

const ACTION_AREA_ATTR = 'data-owa-action'

function isActionAreaClick (e) {
  return e.target.closest && e.target.closest(`[${ACTION_AREA_ATTR}]`)
}

export function checkDuplicate (value, currentLabel, existingLabels, loadedOptions) {
  if (!value.trim()) return false
  const normalized = value.trim().toLowerCase()
  if (normalized === (currentLabel || '').toLowerCase()) return false
  if (existingLabels && existingLabels.some((l) => l.toLowerCase().trim() === normalized)) return true
  if (loadedOptions && loadedOptions.some((o) => o.label && o.label.toLowerCase().trim() === normalized)) return true
  return false
}

function OptionWithActions (props) {
  const { data, selectProps, innerProps } = props
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState('')
  const [renamedLabel, setRenamedLabel] = useState(null)
  const inputRef = useRef(null)

  const isNew = data.__isNew__

  useEffect(() => {
    if (isEditing && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [isEditing])

  const currentLabel = renamedLabel || data.label || ''

  const isDuplicate = useMemo(() => {
    if (!isEditing) return false
    return checkDuplicate(editValue, currentLabel, selectProps.existingLabels, selectProps.loadedOptions)
  }, [isEditing, editValue, currentLabel, selectProps.existingLabels, selectProps.loadedOptions])

  const onRenameClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    if (selectProps.onEditingChange) selectProps.onEditingChange(true)
    setEditValue(currentLabel)
    setIsEditing(true)
  }, [currentLabel, selectProps])

  const onDeleteClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    selectProps.onDeleteOption && selectProps.onDeleteOption(data)
  }, [selectProps, data])

  const finishEditing = useCallback(() => {
    setIsEditing(false)
    if (selectProps.onEditingChange) selectProps.onEditingChange(false)
  }, [selectProps])

  const onRenameSubmit = useCallback(() => {
    const trimmed = editValue.trim()
    if (!trimmed) { finishEditing(); return }
    if (checkDuplicate(trimmed, currentLabel, selectProps.existingLabels, selectProps.loadedOptions)) return
    if (trimmed !== currentLabel) {
      setRenamedLabel(trimmed)
      selectProps.onRenameSubmit && selectProps.onRenameSubmit(data, trimmed)
    }
    finishEditing()
  }, [editValue, currentLabel, selectProps, data, finishEditing])

  const onInputKeyDown = useCallback((e) => {
    e.stopPropagation()
    if (e.key === 'Enter') { e.preventDefault(); onRenameSubmit() }
    if (e.key === 'Escape') { e.preventDefault(); finishEditing() }
  }, [onRenameSubmit, finishEditing])

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
            <div className='f-c-r-select-option-with-actions__edit-row'>
              <input
                ref={inputRef}
                className={`f-c-r-select-option-with-actions__edit-input${isDuplicate ? ' is-invalid' : ''}`}
                value={editValue}
                onChange={(e) => setEditValue(e.target.value)}
                onKeyDown={onInputKeyDown}
                onBlur={finishEditing}
                onMouseDown={(e) => e.stopPropagation()}
                title={isDuplicate ? (window.FolioConsole.translations.alreadyExists || 'Already exists') : undefined}
              />
              <button
                type='button'
                className='btn btn-none p-0 f-c-r-select-option-with-actions__edit-confirm'
                onMouseDown={(e) => { e.preventDefault(); onRenameSubmit() }}
                title={window.FolioConsole.translations.rename || 'Confirm'}
              >
                <FolioUiIcon name='check' height={16} />
              </button>
            </div>
          </div>
        ) : (
          <>
            <span className='f-c-r-select-option-with-actions__label'>
              {renamedLabel || props.children}
            </span>
            <button
              type='button'
              className='btn btn-none p-0 f-c-r-select-option-with-actions__action'
              onClick={onRenameClick}
              data-owa-action='true'
              title={window.FolioConsole.translations.rename || 'Rename'}
            >
              <FolioUiIcon name='edit_box' height={16} />
            </button>
            <button
              type='button'
              className='btn btn-none p-0 f-c-r-select-option-with-actions__action f-c-r-select-option-with-actions__action--danger'
              onClick={onDeleteClick}
              data-owa-action='true'
              title={window.FolioConsole.translations.deleteFromDb || 'Delete'}
            >
              <FolioUiIcon name='delete' height={16} />
            </button>
          </>
        )}
      </div>
    </components.Option>
  )
}

export default OptionWithActions
