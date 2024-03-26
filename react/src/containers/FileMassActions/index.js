import React from 'react'
import { connect } from 'react-redux'

import {
  massDelete,
  massCancel,
  makeMassSelectedIdsSelector
} from 'ducks/files'

import urlWithAffix from 'utils/urlWithAffix'

import FolioConsoleUiButtons from 'components/FolioConsoleUiButtons'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import FolioUiIcon from 'components/FolioUiIcon'

import FileMassActionsWrap from './styled/FileMassActionsWrap'

function downloadHref (filesUrl, massSelectedIds) {
  return urlWithAffix(filesUrl, `/mass_download?ids=${massSelectedIds.join(',')}`)
}

function FileMassActions ({ massSelectedIds, massSelectedIndestructibleIds, fileType, dispatchMassCancel, dispatchMassDelete, filesUrl }) {
  if (massSelectedIds.length === 0) return null
  const indestructible = massSelectedIndestructibleIds.length > 0
  let notAllowedCursor = ''
  if (indestructible) {
    notAllowedCursor = 'cursor-not-allowed'
  }

  return (
    <FileMassActionsWrap className='my-g p-3 bg-medium-gray'>
      <div className='d-flex'>
        <strong className='d-block me-2'>{massSelectedIds.length}</strong>
        <FolioUiIcon name='content_copy' />
      </div>

      <FolioConsoleUiButtons className='flex-grow-1'>
        <FolioConsoleUiButton
          class={notAllowedCursor}
          title={indestructible ? window.FolioConsole.translations.indestructibleFiles : window.FolioConsole.translations.destroy}
          onClick={indestructible ? undefined : () => dispatchMassDelete(fileType)}
          disabled={indestructible}
          icon='delete'
          variant='danger'
          label={window.FolioConsole.translations.destroy}
        />

        <FolioConsoleUiButton
          href={downloadHref(filesUrl, massSelectedIds)}
          onClick={() => dispatchMassCancel(fileType)}
          target='_blank'
          rel='noopener noreferrer'
          variant='secondary'
          icon='download'
          label={window.FolioConsole.translations.download}
        />

        <FolioConsoleUiButton
          variant='transparent'
          icon='close'
          class='ms-auto'
          onClick={() => dispatchMassCancel(fileType)}
        />
      </FolioConsoleUiButtons>
    </FileMassActionsWrap>
  )
}

const mapStateToProps = (state, props) => makeMassSelectedIdsSelector(props.fileType)(state)

function mapDispatchToProps (dispatch) {
  return {
    dispatchMassCancel: (fileType) => dispatch(massCancel(fileType)),
    dispatchMassDelete: (fileType) => {
      if (window.confirm(window.FolioConsole.translations.removePrompt)) {
        dispatch(massDelete(fileType))
      }
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileMassActions)
