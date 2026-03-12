import React, { useState, useCallback } from 'react'
import { components } from 'react-select'
import FolioUiIcon from 'components/FolioUiIcon'
import InlineRenameInput from 'components/InlineRenameInput'

const ACTION_AREA_ATTR = 'data-owa-action'

function isActionAreaClick (e) {
  return e.target.closest && e.target.closest(`[${ACTION_AREA_ATTR}]`)
}

function OptionWithActions (props) {
  const { data, selectProps, innerProps } = props
  const [isEditing, setIsEditing] = useState(false)

  const isNew = data.__isNew__

  const currentLabel = data.label || ''

  const onRenameClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    if (selectProps.onEditingChange) selectProps.onEditingChange(true)
    setIsEditing(true)
  }, [selectProps])

  const onDeleteClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    selectProps.onDeleteOption && selectProps.onDeleteOption(data)
  }, [selectProps, data])

  const finishEditing = useCallback(() => {
    setIsEditing(false)
    if (selectProps.onEditingChange) selectProps.onEditingChange(false)
  }, [selectProps])

  const onRenameSubmit = useCallback((newLabel) => {
    selectProps.onRenameSubmit && selectProps.onRenameSubmit(data, newLabel)
  }, [selectProps, data])

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
              <InlineRenameInput
                currentLabel={currentLabel}
                onSubmit={onRenameSubmit}
                onCancel={finishEditing}
                existingLabels={selectProps.existingLabels}
                loadedOptions={selectProps.loadedOptions}
                className='f-c-r-select-option-with-actions__edit-input'
              />
            </div>
          </div>
        ) : (
          <>
            <span className='f-c-r-select-option-with-actions__label'>
              {props.children}
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
