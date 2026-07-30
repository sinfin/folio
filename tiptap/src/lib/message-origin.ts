export function isSameOriginMessage(
  eventOrigin: string,
  currentOrigin = window.location.origin,
): boolean {
  return eventOrigin === currentOrigin;
}
