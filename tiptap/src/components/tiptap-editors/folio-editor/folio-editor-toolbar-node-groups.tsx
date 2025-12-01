import React from "react";
import type { Editor } from "@tiptap/react";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuGroup,
} from "@/components/tiptap-ui-primitive/dropdown-menu";
import { ChevronDownIcon } from "@/components/tiptap-icons/chevron-down-icon";
import { Button } from "@/components/tiptap-ui-primitive/button";
import { FolioEditorToolbarDropdownButton } from "./folio-editor-toolbar-dropdown";
import { ToolbarGroup } from "@/components/tiptap-ui-primitive/toolbar";
import {
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

// Built-in group icons (fallback)
const GROUP_ICONS: Record<string, LucideIcon> = {
  content: FileText,
  images: Images,
  cards: RectangleHorizontal,
  listings: List,
  special: Star,
};

// Built-in node icons (same as in folio-editor-toolbar-slot-button.tsx)
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

// Get custom icons from window.Folio.Tiptap.customIcons
const getCustomIcons = (): Record<string, React.ComponentType> => {
  const w = window as unknown as {
    Folio?: { Tiptap?: { customIcons?: Record<string, React.ComponentType> } };
  };
  return w.Folio?.Tiptap?.customIcons || {};
};

// Get toolbar groups configuration - check config prop first, then window fallback
const getToolbarGroups = (
  configGroups?: FolioTiptapToolbarGroup[],
): FolioTiptapToolbarGroup[] => {
  if (configGroups && configGroups.length > 0) {
    return configGroups;
  }
  // Fallback to window.Folio.Tiptap.toolbarGroups for backwards compatibility
  const w = window as unknown as {
    Folio?: { Tiptap?: { toolbarGroups?: FolioTiptapToolbarGroup[] } };
  };
  return w.Folio?.Tiptap?.toolbarGroups || [];
};

const getIcon = (
  iconString: string | undefined,
): React.ComponentType<{ size?: number; className?: string }> => {
  if (!iconString) return Plus;

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

  return Plus;
};

interface NodeDropdownProps {
  editor: Editor;
  groupKey: string;
  groupConfig: FolioTiptapToolbarGroup;
  nodes: FolioTiptapNodeFromInput[];
}

function NodeDropdown({
  editor,
  groupKey,
  groupConfig,
  nodes,
}: NodeDropdownProps) {
  const [isOpen, setIsOpen] = React.useState(false);

  const handleOnOpenChange = React.useCallback((open: boolean) => {
    setIsOpen(open);
  }, []);

  const handleNodeClick = React.useCallback(
    (node: FolioTiptapNodeFromInput) => () => {
      window.parent!.postMessage(
        {
          type: "f-tiptap-slash-command:selected",
          attrs: { type: node.type },
        },
        "*",
      );
      setIsOpen(false);
    },
    [],
  );

  const GroupIcon = getIcon(groupConfig.icon || groupKey);
  const lang = document.documentElement.lang as "cs" | "en";
  const tooltip = groupConfig.title[lang] || groupConfig.title.en;

  return (
    <DropdownMenu open={isOpen} onOpenChange={handleOnOpenChange}>
      <DropdownMenuTrigger asChild>
        <Button
          type="button"
          data-style="ghost"
          role="button"
          tabIndex={-1}
          aria-label={tooltip}
          tooltip={tooltip}
        >
          <GroupIcon className="tiptap-button-icon" />
          <ChevronDownIcon className="tiptap-button-dropdown-small" />
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent>
        <DropdownMenuGroup>
          {nodes.map((node) => {
            const NodeIcon = getIcon(node.config?.toolbar?.icon);
            const nodeTitle = node.title[lang] || node.title.en;

            return (
              <DropdownMenuItem key={node.type} asChild>
                <FolioEditorToolbarDropdownButton
                  active={false}
                  enabled={true}
                  onClick={handleNodeClick(node)}
                >
                  <NodeIcon className="tiptap-button-icon" />
                  {nodeTitle}
                </FolioEditorToolbarDropdownButton>
              </DropdownMenuItem>
            );
          })}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export interface FolioEditorToolbarNodeGroupsProps {
  editor: Editor | null;
  nodes: FolioTiptapNodeFromInput[] | undefined;
  toolbarGroupsConfig?: FolioTiptapToolbarGroup[];
}

export function FolioEditorToolbarNodeGroups({
  editor,
  nodes,
  toolbarGroupsConfig,
}: FolioEditorToolbarNodeGroupsProps) {
  if (!editor || !editor.isEditable || !nodes || nodes.length === 0) {
    return null;
  }

  // Get toolbar groups configuration from config prop or window fallback
  const toolbarGroups = getToolbarGroups(toolbarGroupsConfig);

  // Group nodes by dropdown_group
  const groupedNodes: Record<string, FolioTiptapNodeFromInput[]> = {};
  const ungroupedNodes: FolioTiptapNodeFromInput[] = [];

  nodes.forEach((node) => {
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

  // Build default group configs for groups not defined in toolbarGroups
  const getGroupConfig = (groupKey: string): FolioTiptapToolbarGroup => {
    const defined = toolbarGroups.find((g) => g.key === groupKey);
    if (defined) return defined;

    // Default config
    return {
      key: groupKey,
      title: { cs: groupKey, en: groupKey },
      icon: groupKey,
    };
  };

  return (
    <>
      {/* Render grouped nodes as dropdowns */}
      {sortedGroupKeys.map((groupKey) => {
        const groupConfig = getGroupConfig(groupKey);
        return (
          <ToolbarGroup key={groupKey}>
            <NodeDropdown
              editor={editor}
              groupKey={groupKey}
              groupConfig={groupConfig}
              nodes={groupedNodes[groupKey]}
            />
          </ToolbarGroup>
        );
      })}

      {/* Render ungrouped nodes as individual buttons (handled by FolioEditorToolbarSlot) */}
    </>
  );
}

export default FolioEditorToolbarNodeGroups;

