import React from 'react'
import { forceCheck } from 'react-lazyload'

function ModalScroll ({ children, header, footer }) {
  return (
    <div className='folio-console-modal__scroll-wrap'>
      {header && (
        <div className='folio-console-modal__scroll-fixed'>
          {header}
        </div>
      )}

      <div className='folio-console-modal__scroll-inner' onScroll={forceCheck}>
        {children}
      </div>

      {footer && (
        <div className='folio-console-modal__scroll-fixed modal-footer'>
          {footer}
        </div>
      )}
    </div>
  )
}

export default ModalScroll
