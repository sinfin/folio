//= require mersenne-twister

window.Folio = window.Folio || {}

window.Folio.waveform = (opts) => {
  const r = new window.MersenneTwister(opts.id || 0)
  const strokeWidth = opts.strokeWidth || 2
  const gap = opts.gap || 3
  const width = opts.width || 515
  const height = opts.height || 25
  const target = Math.ceil(width / (gap + strokeWidth))

  const randomLength = () => Math.floor(85 * r.random()) + 15

  let x = -strokeWidth / 2 - gap
  let path = ''

  for (let i = 0; i < target; i += 1) {
    let length

    switch (i) {
      case 0:
      case target - 1:
        length = 25
        break
      case 1:
      case target - 2:
        length = 50
        break
      default:
        length = randomLength()
    }

    x += gap + strokeWidth
    path = `${path}M${x},${height}v${-height * length / 100.0}`
  }

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`)
  svg.setAttribute('width', width)
  svg.setAttribute('height', height)
  svg.setAttribute('preserveAspectRatio', 'xMinYMin')

  const svgPath = document.createElementNS('http://www.w3.org/2000/svg', 'path')
  svgPath.setAttribute('d', path)
  svgPath.setAttribute('fill', 'none')
  svgPath.setAttribute('stroke', 'currentColor')
  svgPath.setAttribute('stroke-width', String(strokeWidth))

  svg.appendChild(svgPath)

  if (opts.class) svg.classList.add(opts.class)

  return svg
}
