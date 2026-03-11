import React, { useState, useRef, useEffect, useCallback } from 'react'
import { components } from 'react-select'
import FolioUiIcon from 'components/FolioUiIcon'

const ACTION_AREA_ATTR = 'data-owa-action'

function isActionAreaClick (e) {
  return e.target.closest && e.target.closest(`[${ACTION_AREA_ATTR}]`)
}

function OptionWithActions (props) {
  const { data, selectProps, innerProps } = props
  const [menuOpen, setMenuOpen] = useState(false)
  const menuRef = useRef(null)
  const dotsRef = useRef(null)

  const isNew = data.__isNew__

  useEffect(() => {
    if (!menuOpen) return

    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target) &&
          dotsRef.current && !dotsRef.current.contains(e.target)) {
        setMenuOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [menuOpen])

  const onDotsClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    setMenuOpen((prev) => !prev)
  }, [])

  const onRenameClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    setMenuOpen(false)
    // Delegate rename to parent — dropdown will close, rename input renders outside
    selectProps.onStartRename && selectProps.onStartRename(data)
  }, [data, selectProps])

  const onDeleteClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    setMenuOpen(false)
    selectProps.onDeleteOption && selectProps.onDeleteOption(data)
  }, [selectProps, data])

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
  // when clicking on the action area (dots button, sub-menu)
  const wrappedInnerProps = {
    ...innerProps,
    onClick: (e) => {
      if (isActionAreaClick(e)) return
      innerProps.onClick && innerProps.onClick(e)
    },
    onMouseDown: (e) => {
      if (isActionAreaClick(e)) return
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
        <span className='f-c-r-select-option-with-actions__label'>
          {props.children}
        </span>
        <span
          className='f-c-r-select-option-with-actions__dots'
          ref={dotsRef}
          onClick={onDotsClick}
          data-owa-action='true'
        >
          <FolioUiIcon name='dots_vertical' height={16} />
        </span>

        {menuOpen && (
          <div
            className='f-c-r-select-option-with-actions__menu'
            ref={menuRef}
            data-owa-action='true'
          >
            <div
              className='f-c-r-select-option-with-actions__menu-item'
              onClick={onRenameClick}
            >
              <FolioUiIcon name='edit_box' height={14} />
              <span>{window.FolioConsole.translations.rename || 'Rename'}</span>
            </div>
            <div
              className='f-c-r-select-option-with-actions__menu-item f-c-r-select-option-with-actions__menu-item--danger'
              onClick={onDeleteClick}
            >
              <FolioUiIcon name='delete' height={14} />
              <span>{window.FolioConsole.translations.deleteFromDb || 'Delete'}</span>
            </div>
          </div>
        )}
      </div>
    </components.Option>
  )
}

export default OptionWithActions
