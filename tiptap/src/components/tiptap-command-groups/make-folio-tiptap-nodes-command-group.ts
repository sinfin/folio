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

// Built-in node icons
const NODE_ICONS: Record<string, LucideIcon> = {
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

// Group icons
const GROUP_ICONS: Record<string, LucideIcon> = {
  content: FileText,
  images: Images,
  cards: RectangleHorizontal,
  listings: List,
  special: Star,
};

const getNodeIcon = (iconString: string | undefined): LucideIcon => {
  if (iconString && NODE_ICONS[iconString]) {
    return NODE_ICONS[iconString];
  }
  return Cuboid;
};

const getGroupIcon = (groupKey: string): LucideIcon => {
  return GROUP_ICONS[groupKey] || Cuboid;
};

export const makeFolioTiptapNodesCommandGroup = (
  folioTiptapNodes: FolioTiptapNodeFromInput[],
  toolbarGroups?: FolioTiptapToolbarGroup[],
): FolioEditorCommandGroup | FolioEditorCommandGroup[] => {
  // If we have toolbar groups config, create multiple groups
  if (toolbarGroups && toolbarGroups.length > 0) {
    const groupedNodes: Record<string, FolioTiptapNodeFromInput[]> = {};
    const ungroupedNodes: FolioTiptapNodeFromInput[] = [];

    // Group nodes by dropdown_group
    folioTiptapNodes.forEach((node) => {
      const group = node.config?.toolbar?.dropdown_group;
      if (group) {
        if (!groupedNodes[group]) {
          groupedNodes[group] = [];
        }
        groupedNodes[group].push(node);
      } else {
        ungroupedNodes.push(node);
      }
    });

    // Sort groups by order
    const sortedGroupKeys = Object.keys(groupedNodes).sort((a, b) => {
      const aConfig = toolbarGroups.find((g) => g.key === a);
      const bConfig = toolbarGroups.find((g) => g.key === b);
      return (aConfig?.order || 999) - (bConfig?.order || 999);
    });

    const groups: FolioEditorCommandGroup[] = [];

    // Create a group for each dropdown_group
    sortedGroupKeys.forEach((groupKey) => {
      const groupConfig = toolbarGroups.find((g) => g.key === groupKey);
      const lang = document.documentElement.lang as "cs" | "en";

      const commands = groupedNodes[groupKey].map((folioTiptapNode) => {
        const command: FolioEditorCommand = {
          title: folioTiptapNode.title,
          icon: getNodeIcon(folioTiptapNode.config?.toolbar?.icon),
          key: `folioTiptapNode-${folioTiptapNode.type}`,
          command: () => {
            if (document.activeElement instanceof HTMLElement) {
              document.activeElement.blur();
            }
            window.parent!.postMessage(
              {
                type: "f-tiptap-slash-command:selected",
                attrs: { type: folioTiptapNode.type },
              },
              "*",
            );
          },
        };
        return command;
      });

      // Sort commands by title
      commands.sort((a, b) => {
        const aTitle = a.title[lang] || a.title["en"];
        const bTitle = b.title[lang] || b.title["en"];
        return aTitle.localeCompare(bTitle);
      });

      groups.push({
        title: groupConfig?.title || { cs: groupKey, en: groupKey },
        key: `folioTiptapNodes-${groupKey}`,
        icon: getGroupIcon(groupKey),
        commands,
      });
    });

    // Add ungrouped nodes as "Ostatní" / "Other"
    if (ungroupedNodes.length > 0) {
      const lang = document.documentElement.lang as "cs" | "en";
      const commands = ungroupedNodes.map((folioTiptapNode) => {
        const command: FolioEditorCommand = {
          title: folioTiptapNode.title,
          icon: getNodeIcon(folioTiptapNode.config?.toolbar?.icon),
          key: `folioTiptapNode-${folioTiptapNode.type}`,
          command: () => {
            if (document.activeElement instanceof HTMLElement) {
              document.activeElement.blur();
            }
            window.parent!.postMessage(
              {
                type: "f-tiptap-slash-command:selected",
                attrs: { type: folioTiptapNode.type },
              },
              "*",
            );
          },
        };
        return command;
      });

      commands.sort((a, b) => {
        const aTitle = a.title[lang] || a.title["en"];
        const bTitle = b.title[lang] || b.title["en"];
        return aTitle.localeCompare(bTitle);
      });

      groups.push({
        title: { cs: "Ostatní", en: "Other" },
        key: "folioTiptapNodes-other",
        icon: Cuboid,
        commands,
      });
    }

    return groups;
  }

  // Fallback: single group with all nodes (original behavior but with icons)
  const commands = folioTiptapNodes.map((folioTiptapNode) => {
    const command: FolioEditorCommand = {
      title: folioTiptapNode.title,
      icon: getNodeIcon(folioTiptapNode.config?.toolbar?.icon),
      key: `folioTiptapNode-${folioTiptapNode.type}`,
      command: () => {
        if (document.activeElement instanceof HTMLElement) {
          document.activeElement.blur();
        }

        window.parent!.postMessage(
          {
            type: "f-tiptap-slash-command:selected",
            attrs: { type: folioTiptapNode.type },
          },
          "*",
        );
      },
    };

    return command;
  });

  // sort commands by title
  commands.sort((a, b) => {
    const aTitle =
      a.title[document.documentElement.lang as "cs" | "en"] || a.title["en"];
    const bTitle =
      b.title[document.documentElement.lang as "cs" | "en"] || b.title["en"];

    return aTitle.localeCompare(bTitle);
  });

  return {
    title: { cs: "Bloky", en: "Blocks" },
    key: "folioTiptapNodes",
    icon: Cuboid,
    commands,
  };
};

export default makeFolioTiptapNodesCommandGroup;
