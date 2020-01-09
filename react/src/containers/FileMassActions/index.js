import React from 'react'
import { connect } from 'react-redux'

import {
  massDelete,
  massCancel,
  makeMassSelectedIdsSelector
} from 'ducks/files'

function downloadHref (filesKey, massSelectedIds) {
  return `/console/${filesKey}/mass_download?ids=${massSelectedIds.join(',')}`
}

function FileMassActions ({ massSelectedIds, filesKey, dispatchMassCancel, dispatchMassDelete }) {
  if (massSelectedIds.length === 0) return null

  return (
    <div className='mb-3 px-h py-2 bg-info d-flex align-items-center'>
      <div className='mr-g d-flex'>
        <strong className='d-block mr-2'>{massSelectedIds.length}</strong>
        <span className='mi mi--20'>content_copy</span>
      </div>

      <button
        className='btn btn-danger d-flex mr-g font-weight-bold'
        type='button'
        onClick={() => dispatchMassDelete(filesKey)}
      >
        <span className='mi'>delete</span>
        {window.FolioConsole.translations.destroy}
      </button>

      <a
        className='btn btn-secondary d-flex mr-g font-weight-bold'
        href={downloadHref(filesKey, massSelectedIds)}
        onClick={() => dispatchMassCancel(filesKey)}
        target='_blank'
        rel='noopener noreferrer'
      >
        <span className='mi'>file_download</span>
        {window.FolioConsole.translations.download}
      </a>
    </div>
  )
}

const mapStateToProps = (state, props) => ({
  massSelectedIds: makeMassSelectedIdsSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return {
    dispatchMassCancel: (filesKey) => dispatch(massCancel(filesKey)),
    dispatchMassDelete: (filesKey) => {
      if (window.confirm(window.FolioConsole.translations.removePrompt)) {
        dispatch(massDelete(filesKey))
      }
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileMassActions)
