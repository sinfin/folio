export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait?: number,
  immediate?: boolean
): ((...args: Parameters<T>) => void) => {
  let timeout: ReturnType<typeof setTimeout> | null = null

  if (wait === undefined) {
    wait = 150
  }

  if (immediate === undefined) {
    immediate = false
  }

  return function (this: any, ...args: Parameters<T>) {
    const context = this
    
    const later = () => {
      timeout = null
      if (!immediate) func.apply(context, args)
    }

    const callNow = immediate && !timeout

    if (timeout) clearTimeout(timeout)
    timeout = setTimeout(later, wait)

    if (callNow) func.apply(context, args)
  }
}