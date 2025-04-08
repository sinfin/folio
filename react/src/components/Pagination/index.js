import React from 'react'
import { unescape } from 'lodash'

import DisplayButtons from 'containers/DisplayButtons'
import FolioUiIcon from 'components/FolioUiIcon'

import PaginationWrap from './styled/PaginationWrap'
import DisplayButtonsWrap from './styled/DisplayButtonsWrap'

const makeOnClick = (number, changePage) => (e) => {
  e.preventDefault()
  e.stopPropagation()
  changePage(number)
}

function paginationInfo (pagination) {
  if (pagination.count === 0) {
    return window.FolioConsole.translations.paginationEmpty
  } else {
    return unescape(window.FolioConsole.translations.paginationInfo).replace('%{from}', pagination.from).replace('%{to}', pagination.to).replace('%{count}', pagination.count)
  }
}

function PaginationComponent ({ changePage, pagination, setCardsDisplay, setThumbsDisplay, display, fileTypeIsImage }) {
  const active = pagination.page
  const min = 1
  const max = pagination.pages

  const next = Math.min(max, active + 1)
  const prev = Math.max(min, active - 1)
  const numbers = [min]

  for (let i = active - 3; i < active + 3; i++) {
    if (i > min && i < max && numbers.indexOf(i) === -1) {
      if ((i === active - 3) && i > min + 1) {
        numbers.push('a')
      }

      numbers.push(i)

      if ((i === active + 2) && i + 1 < max) {
        numbers.push('b')
      }
    }
  }

  if (numbers.indexOf(max) === -1) {
    numbers.push(max)
  }

  const prevActive = prev !== active
  const nextActive = next !== active

  return (
    <PaginationWrap single={max === 1} className='my-g'>
      <div className='f-c-ui-pagy small'>
        <div
          className='f-c-ui-pagy__info'
          dangerouslySetInnerHTML={{ __html: paginationInfo(pagination) }}
        />

        {max !== 1 && (
          <div className='f-c-ui-pagy__nav'>
            <div className={`f-c-ui-pagy__page f-c-ui-pagy__page--with-ico ${prevActive ? 'f-c-ui-pagy__page--disabled' : ''}`}>
              {prevActive ? (
                <a href={`#${prev}`} onClick={makeOnClick(prev, changePage)}>
                  <FolioUiIcon class='f-c-ui-pagy__ico' name='chevron_left' />
                </a>
              ) : (
                <FolioUiIcon class='f-c-ui-pagy__ico' name='chevron_left' />
              )}
            </div>

            {numbers.map((number) => (
              <div className={`f-c-ui-pagy__page f-c-ui-pagy__page--page ${number === active ? 'f-c-ui-pagy__page--current' : ''} ${(number === 'a' || number === 'b') ? 'f-c-ui-pagy__page--gap' : ''}`} key={number}>
                {number === 'a' || number === 'b' ? (
                  <span>&hellip;</span>
                ) : (
                  number === active ? number : (
                    <a href={`#${number}`} onClick={makeOnClick(number, changePage)}>
                      {number}
                    </a>
                  )
                )}
              </div>
            ))}

            <div className={`f-c-ui-pagy__page f-c-ui-pagy__page--with-ico ${nextActive ? 'f-c-ui-pagy__page--disabled' : ''}`}>
              {nextActive ? (
                <a href={`#${next}`} onClick={makeOnClick(next, changePage)}>
                  <FolioUiIcon class='f-c-ui-pagy__ico' name='chevron_right' />
                </a>
              ) : (
                <FolioUiIcon class='f-c-ui-pagy__ico' name='chevron_right' />
              )}
            </div>
          </div>
        )}
      </div>

      {fileTypeIsImage && (
        <DisplayButtonsWrap>
          <DisplayButtons
            display={display}
            setCardsDisplay={setCardsDisplay}
            setThumbsDisplay={setThumbsDisplay}
          />
        </DisplayButtonsWrap>
      )}
    </PaginationWrap>
  )
}

export default PaginationComponent
