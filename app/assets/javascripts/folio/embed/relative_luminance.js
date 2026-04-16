// Shared by f-embed-box (Sprockets) + static embed (prepended before embed.js in build).
window.Folio = window.Folio || {}
window.Folio.Embed = window.Folio.Embed || {}

window.Folio.Embed.hexRelativeLuminance = (hex) => {
  try {
    // Convert hex to RGB
    const r = parseInt(hex.slice(1, 3), 16) / 255
    const g = parseInt(hex.slice(3, 5), 16) / 255
    const b = parseInt(hex.slice(5, 7), 16) / 255

    // Check for invalid values
    if (isNaN(r) || isNaN(g) || isNaN(b)) {
      return 1 // Default to light (no dark class)
    }

    // Apply gamma correction
    const rLinear = r <= 0.03928 ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4)
    const gLinear = g <= 0.03928 ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4)
    const bLinear = b <= 0.03928 ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4)

    // Calculate relative luminance
    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear
  } catch (error) {
    // Return default luminance for light background if parsing fails
    return 1
  }
}
