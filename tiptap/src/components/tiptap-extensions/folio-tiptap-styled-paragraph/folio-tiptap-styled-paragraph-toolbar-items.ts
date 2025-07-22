import { DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_ICON } from "./make-folio-tiptap-styled-paragraph-commands"
import { Pilcrow } from "lucide-react";
import { HeadingTwoIcon } from "@/components/tiptap-icons/heading-two-icon"
import { HeadingThreeIcon } from "@/components/tiptap-icons/heading-three-icon"
import { HeadingFourIcon } from "@/components/tiptap-icons/heading-four-icon"

import translate from "@/lib/i18n";

export const HEADING_LEVELS = [2, 3, 4]

export const HEADING_TRANSLATIONS = {
  cs: {
    heading: "Nadpis",
  },
  en: {
    heading: "Heading",
  },
}

export const HEADING_ICONS = {
  2: HeadingTwoIcon,
  3: HeadingThreeIcon,
  4: HeadingFourIcon,
}

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
      icon: HEADING_ICONS[level],
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
