import styled from 'styled-components'

export default styled.div`
  ${(props) => props.standalone ? 'position: static; height: 50vh;' : ''}
`
