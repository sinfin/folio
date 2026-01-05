import { Typography } from "@tiptap/extension-typography";

/**
 * Configures Typography extension with proper quotation marks based on document locale
 */
export function createTypographyExtension() {
  const documentLang = document.documentElement.lang || "en";
  const isCzech =
    documentLang.startsWith("cs") || documentLang.startsWith("cz");

  if (isCzech) {
    return Typography.configure({
      openDoubleQuote: "\u201E", // „
      closeDoubleQuote: "\u201C", // "
      openSingleQuote: "\u201A", // ‚
      closeSingleQuote: "\u2018", // '
    });
  }

  // Default configuration for other languages
  return Typography;
}
