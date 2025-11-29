import * as React from "react";
import { type Editor } from "@tiptap/react";

import { Button } from "@/components/tiptap-ui-primitive/button";
import translate from "@/lib/i18n";

import {
  Video,
  Image,
  Newspaper,
  Plus,
  // Content icons
  FileText,
  Heading,
  AlignLeft,
  Quote,
  Minus,
  FileDown,
  // Image icons
  Images,
  LayoutGrid,
  Grid3x3,
  GalleryVertical,
  ImagePlus,
  // Card icons
  User,
  RectangleHorizontal,
  CreditCard,
  Square,
  SquareStack,
  Layers,
  ImageOff,
  // Listing icons
  List,
  FolderOpen,
  LayoutList,
  ArrowRight,
  // Special icons
  Home,
  Tag,
  Mail,
  Link,
  Play,
  Monitor,
  // Form icons
  FormInput,
  Send,
} from "lucide-react";

export interface FolioEditorToolbarSlotButton {
  editor: Editor;
  node: FolioTiptapNodeFromInput;
}

const TRANSLATIONS = {
  cs: "Vložit",
  en: "Insert",
};

// Mapping icon strings to lucide-react components
const ICON_MAP: Record<string, React.ComponentType<{ size?: number }>> = {
  // Standard icons
  image: Image,
  video: Video,
  newspaper: Newspaper,
  plus: Plus,

  // Content icons
  content_text: FileText,
  content_title: Heading,
  content_lead: AlignLeft,
  quote: Quote,
  content_divider: Minus,
  content_documents: FileDown,
  file_text: FileText,

  // Image icons
  image_gallery: Images,
  image_grid: LayoutGrid,
  image_masonry: Grid3x3,
  image_one_two: GalleryVertical,
  image_with_text: ImagePlus,
  image_wrapping: ImagePlus,

  // Card icons
  user: User,
  rectangle_horizontal: RectangleHorizontal,
  card_visual: CreditCard,
  card_size: Square,
  card_full: SquareStack,
  card_padded: Layers,

  // Listing icons
  list: List,
  listing_news: Newspaper,
  listing_projects: FolderOpen,
  listing_project_card: LayoutList,
  arrow_right: ArrowRight,

  // Special icons
  hero_banner: Monitor,
  home: Home,
  tag: Tag,
  contact_form: Mail,
  link: Link,
  play: Play,

  // Form icons
  form: FormInput,
  send: Send,
};

// Get custom icons from window.Folio.Tiptap.customIcons (defined by project)
const getCustomIcons = (): Record<
  string,
  React.ComponentType<{ size?: number }>
> => {
  const w = window as unknown as {
    Folio?: { Tiptap?: { customIcons?: Record<string, React.ComponentType> } };
  };
  return w.Folio?.Tiptap?.customIcons || {};
};

export const FolioEditorToolbarSlotButton = ({
  editor,
  node,
}: FolioEditorToolbarSlotButton) => {
  const handleClick = React.useCallback(() => {
    window.parent!.postMessage(
      {
        type: "f-tiptap-slash-command:selected",
        attrs: { type: node?.type },
      },
      "*",
    );
  }, [node]);

  const icon = (iconString: string | undefined) => {
    // First check project-defined custom icons
    const customIcons = getCustomIcons();
    if (iconString && customIcons[iconString]) {
      return customIcons[iconString];
    }
    // Then check built-in icons
    if (iconString && ICON_MAP[iconString]) {
      return ICON_MAP[iconString];
    }
    if (iconString) {
      console.warn(
        `Unknown icon string: ${iconString}, using Plus as fallback. ` +
          `Define custom icons in window.Folio.Tiptap.customIcons`,
      );
    }
    return Plus;
  };

  if (!node) return;
  if (!editor || !editor.isEditable) return null;

  const translations = {
    cs: {
      insert: node.title.cs || TRANSLATIONS.cs,
    },
    en: {
      insert: node.title.en || TRANSLATIONS.en,
    },
  };

  const label = translate(translations, "insert");
  const IconComponent = icon(node.config.toolbar?.icon);

  return (
    <Button
      type="button"
      data-style="ghost"
      role="button"
      tabIndex={-1}
      aria-label={label}
      tooltip={label}
      onClick={handleClick}
    >
      <IconComponent size={16} />
    </Button>
  );
};

FolioEditorToolbarSlotButton.displayName = "FolioEditorToolbarSlotButton";

export default FolioEditorToolbarSlotButton;
