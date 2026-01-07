import {
  Cuboid,
  Plus,
  FileText,
  Images,
  RectangleHorizontal,
  List,
  Star,
  Video,
  Image,
  Newspaper,
  Heading,
  AlignLeft,
  Quote,
  Minus,
  FileDown,
  LayoutGrid,
  Grid3x3,
  GalleryVertical,
  ImagePlus,
  User,
  CreditCard,
  Square,
  SquareStack,
  Layers,
  FolderOpen,
  LayoutList,
  ArrowRight,
  Home,
  Tag,
  Mail,
  Link,
  Play,
  Monitor,
  FormInput,
  Send,
  type LucideIcon,
} from "lucide-react";
import type React from "react";

// Built-in node icons mapping
export const NODE_ICONS: Record<string, LucideIcon> = {
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

// Built-in group icons (fallback)
export const GROUP_ICONS: Record<string, LucideIcon> = {
  content: FileText,
  images: Images,
  cards: RectangleHorizontal,
  listings: List,
  special: Star,
};

// Get custom icons from window.Folio.Tiptap.customIcons (defined by project)
// Memoized to avoid repeated window lookups
let customIconsCache: Record<string, React.ComponentType> | null = null;

export const getCustomIcons = (): Record<string, React.ComponentType> => {
  if (customIconsCache !== null) {
    return customIconsCache;
  }

  const w = window as unknown as {
    Folio?: { Tiptap?: { customIcons?: Record<string, React.ComponentType> } };
  };
  customIconsCache = w.Folio?.Tiptap?.customIcons || {};
  return customIconsCache;
};

// Get node icon with consistent Cuboid fallback
export const getNodeIcon = (iconString: string | undefined): LucideIcon => {
  if (!iconString) return Cuboid;

  // Check custom icons first
  const customIcons = getCustomIcons();
  if (customIcons[iconString]) {
    return customIcons[iconString] as LucideIcon;
  }

  // Check built-in node icons
  if (NODE_ICONS[iconString]) {
    return NODE_ICONS[iconString];
  }

  // Unknown icon - use Cuboid as fallback
  if (iconString) {
    console.warn(
      `Unknown icon string: ${iconString}, using Cuboid as fallback. ` +
        `Define custom icons in window.Folio.Tiptap.customIcons`,
    );
  }
  return Cuboid;
};

// Get group icon with consistent Cuboid fallback
export const getGroupIcon = (groupKey: string): LucideIcon => {
  return GROUP_ICONS[groupKey] || Cuboid;
};

// Get icon for toolbar (supports both node and group icons, with className support)
export const getIcon = (
  iconString: string | undefined,
): React.ComponentType<{ size?: number; className?: string }> => {
  if (!iconString) return Cuboid;

  // Check custom icons first
  const customIcons = getCustomIcons();
  if (customIcons[iconString]) {
    return customIcons[iconString] as React.ComponentType<{
      size?: number;
      className?: string;
    }>;
  }

  // Check built-in node icons
  if (NODE_ICONS[iconString]) {
    return NODE_ICONS[iconString];
  }

  // Check built-in group icons
  if (GROUP_ICONS[iconString]) {
    return GROUP_ICONS[iconString];
  }

  // Unknown icon - use Cuboid as fallback
  return Cuboid;
};
