export default function isDuplicateLabel (value, currentLabel, existingLabels, loadedOptions) {
  if (!value.trim()) return false
  const normalized = value.trim().toLowerCase()
  if (normalized === (currentLabel || '').toLowerCase()) return false
  if (existingLabels && existingLabels.some((l) => l.toLowerCase().trim() === normalized)) return true
  if (loadedOptions && loadedOptions.some((o) => o.label && o.label.toLowerCase().trim() === normalized)) return true
  return false
}
