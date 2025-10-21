import Paragraph from "@tiptap/extension-paragraph";

export interface StyledParagraphOptions {
  variants: StyledParagraphVariantFromInput[];
  variantCommands: FolioEditorCommand[];
}

export const FolioTiptapStyledParagraph =
  Paragraph.extend<StyledParagraphOptions>({
    name: "folioTiptapStyledParagraph",

    parseHTML() {
      const variants = this.options.variants || [];

      const getAttrs = (element: HTMLElement | string) => {
        if (typeof element === "string") return false;
        return {
          variant:
            element.getAttribute("data-f-tiptap-styled-paragraph-variant") ||
            null,
        };
      };

      const parsers = [
        {
          tag: "p.f-tiptap-styled-paragraph",
          getAttrs,
        },
      ];

      // Add parsers for custom tags
      variants.forEach((variant) => {
        if (variant.tag && variant.tag !== "p") {
          parsers.push({
            tag: `${variant.tag}.f-tiptap-styled-paragraph`,
            getAttrs,
          });
        }
      });

      return parsers;
    },

    renderHTML({
      HTMLAttributes,
    }: {
      HTMLAttributes: Record<string, unknown>;
    }) {
      const variants = this.options.variants || [];
      const variant = HTMLAttributes[
        "data-f-tiptap-styled-paragraph-variant"
      ] as string;

      // Find the variant configuration
      const variantConfig = variants.find((v) => v.variant === variant);

      // Determine tag and class
      const tag = variantConfig?.tag || "p";
      const baseClass = "f-tiptap-styled-paragraph";
      const customClass = variantConfig?.class_name;
      const finalClass = customClass
        ? `${baseClass} ${customClass}`
        : baseClass;

      return [tag, { ...HTMLAttributes, class: finalClass }, 0];
    },

    addOptions() {
      return {
        variants: [],
        variantCommands: [],
      };
    },

    addAttributes() {
      return {
        variant: {
          default: null,
          parseHTML: (element: HTMLElement) =>
            element.getAttribute("data-f-tiptap-styled-paragraph-variant"),
          renderHTML: (attributes: { variant: string }) => ({
            "data-f-tiptap-styled-paragraph-variant": attributes.variant,
          }),
        },
      };
    },
  });
