import React from 'react'
import { connect } from 'react-redux'

import {
  massDelete,
  massCancel,
  makeMassSelectedIdsSelector
} from 'ducks/files'

import FileMassActionsWrap from './styled/FileMassActionsWrap'

function downloadHref (filesUrl, massSelectedIds) {
  return `${filesUrl}/mass_download?ids=${massSelectedIds.join(',')}`
}

function FileMassActions ({ massSelectedIds, massSelectedIndestructibleIds, filesKey, dispatchMassCancel, dispatchMassDelete, filesUrl }) {
  if (massSelectedIds.length === 0) return null
  const indestructible = massSelectedIndestructibleIds.length > 0
  let notAllowedCursor = ''
  if (indestructible) {
    notAllowedCursor = 'cursor-not-allowed'
  }

  return (
    <FileMassActionsWrap className='mb-3 px-h py-2 bg-info d-flex align-items-center'>
      <div className='mr-g d-flex'>
        <strong className='d-block mr-2'>{massSelectedIds.length}</strong>
        <span className='mi mi--20'>content_copy</span>
      </div>

      <div className='d-flex flex-wrap my-n2'>
        <button
          className={`btn btn-danger d-block mr-2 mr-sm-g my-2 font-weight-bold ${notAllowedCursor}`}
          type='button'
          title={indestructible ? window.FolioConsole.translations.indestructibleFiles : window.FolioConsole.translations.destroy}
          onClick={indestructible ? undefined : () => dispatchMassDelete(filesKey)}
          disabled={indestructible}
        >
          <span className='fa fa-trash' />
          {window.FolioConsole.translations.destroy}
        </button>

        <a
          className='btn btn-secondary d-block mr-2 mr-sm-g my-2 font-weight-bold'
          href={downloadHref(filesUrl, massSelectedIds)}
          onClick={() => dispatchMassCancel(filesKey)}
          target='_blank'
          rel='noopener noreferrer'
        >
          <span className='mi'>file_download</span>
          {window.FolioConsole.translations.download}
        </a>
      </div>

      <div className='ml-auto'>
        <button
          className='btn-unbutton px-2 py-1'
          type='button'
          onClick={() => dispatchMassCancel(filesKey)}
        >
          <span className='fa fa-times' />
        </button>
      </div>
    </FileMassActionsWrap>
  )
}

const mapStateToProps = (state, props) => makeMassSelectedIdsSelector(props.filesKey)(state)

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
