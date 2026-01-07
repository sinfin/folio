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
import { getIcon } from "@/lib/node-icons";

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

interface NodeDropdownProps {
  groupKey: string;
  groupConfig: FolioTiptapToolbarGroup;
  nodes: FolioTiptapNodeFromInput[];
}

function NodeDropdown({ groupKey, groupConfig, nodes }: NodeDropdownProps) {
  const [isOpen, setIsOpen] = React.useState(false);

  const handleOnOpenChange = React.useCallback((open: boolean) => {
    setIsOpen(open);
  }, []);

  // Intentional use of "*" origin for parent iframe communication
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
              groupKey={groupKey}
              groupConfig={groupConfig}
              nodes={groupedNodes[groupKey]}
            />
          </ToolbarGroup>
        );
      })}
    </>
  );
}

export default FolioEditorToolbarNodeGroups;
