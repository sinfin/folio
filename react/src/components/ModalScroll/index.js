import React from 'react'
import { forceCheck } from 'react-lazyload'

function ModalScroll ({ children, header, footer }) {
  return (
    <div className='f-c-r-modal__scroll-wrap'>
      {header && (
        <div className='f-c-r-modal__scroll-fixed'>
          {header}
        </div>
      )}

      <div className='f-c-r-modal__scroll-inner' onScroll={forceCheck}>
        {children}
      </div>

      {footer && (
        <div className='f-c-r-modal__scroll-fixed modal-footer'>
          {footer}
        </div>
      )}
    </div>
  )
}

export default ModalScroll
