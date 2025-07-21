import { DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_ICON } from "./make-folio-tiptap-styled-paragraph-commands"
import { Pilcrow } from "lucide-react";

import {
  HEADING_TRANSLATIONS,
  headingIcons,
} from "@/components/tiptap-ui/heading-button/heading-button";

import translate from "@/lib/i18n";

const HEADING_LEVELS = [2, 3, 4]

export const folioTiptapStyledParagraphToolbarItems = (styledParagraphVariants: FolioTiptapStyledParagraphVariant[]) => {
  const commands = []

  commands.push({
    title: { cs: "Odstavec", en: "Paragraph" }[document.documentElement.lang] || "Paragraph",
    icon: Pilcrow,
    key: "paragraph",
    dontShowAsActiveInCollapsedToolbar: true,
    command: ({ editor, range, slash }: { editor: Editor; range?: Range, slash?: boolean }) => {
      const chain = editor.chain()

      chain.focus()

      if (slash && range) {
        chain.deleteRange(range)
      }

      chain.setNode("paragraph")
      chain.run();
    },
  })

  HEADING_LEVELS.forEach((level) => {
    const title = `${translate(HEADING_TRANSLATIONS, 'heading')} H${level}`

    commands.push({
      title,
      icon: headingIcons[level],
      key: `heading-${level}`,
      command: ({ editor, range, slash }: { editor: Editor; range?: Range, slash?: boolean }) => {
        const chain = editor.chain()

        chain.focus()

        if (slash && range) {
          chain.deleteRange(range)
        }

        chain.setNode("heading", { level })
        chain.run();
      },
    })
  })

  styledParagraphVariants.forEach((variant) => {
    let title

    if (typeof variant.title === "string") {
      title = variant.title
    } else {
      title = variant.title[document.documentElement.lang] || variant.title.en
    }

    commands.push({
      title,
      icon: variant.icon || DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_ICON,
      key: `styledParagraph-${variant.variant}`,
      command: ({ editor, range, slash }: { editor: Editor; range?: Range, slash?: boolean }) => {
        const chain = editor.chain()

        chain.focus()

        if (slash && range) {
          chain.deleteRange(range)
        }

        chain.setNode("styledParagraph", { variant: variant.variant })
        chain.run();
      },
    })
  })

  return commands
}
