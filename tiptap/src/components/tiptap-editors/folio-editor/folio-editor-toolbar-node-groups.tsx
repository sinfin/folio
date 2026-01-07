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

// Get node groups configuration - check config prop first, then window fallback
const getNodeGroups = (
  configGroups?: FolioTiptapNodeGroup[],
): FolioTiptapNodeGroup[] => {
  if (configGroups && configGroups.length > 0) {
    return configGroups;
  }
  // Fallback to window.Folio.Tiptap.nodeGroups for backwards compatibility
  const w = window as unknown as {
    Folio?: { Tiptap?: { nodeGroups?: FolioTiptapNodeGroup[] } };
  };
  return w.Folio?.Tiptap?.nodeGroups || [];
};

interface NodeDropdownProps {
  groupKey: string;
  groupConfig: FolioTiptapNodeGroup;
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
            const NodeIcon = getIcon(node.config?.icon);
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
  nodeGroupsConfig?: FolioTiptapNodeGroup[];
}

export function FolioEditorToolbarNodeGroups({
  editor,
  nodes,
  nodeGroupsConfig,
}: FolioEditorToolbarNodeGroupsProps) {
  if (!editor || !editor.isEditable || !nodes || nodes.length === 0) {
    return null;
  }

  // Get node groups configuration from config prop or window fallback
  const nodeGroups = getNodeGroups(nodeGroupsConfig);

  // Group nodes by group
  const groupedNodes: Record<string, FolioTiptapNodeFromInput[]> = {};

  nodes.forEach((node) => {
    const group = node.config?.group;
    if (group) {
      if (!groupedNodes[group]) {
        groupedNodes[group] = [];
      }
      groupedNodes[group].push(node);
    }
  });

  // Sort groups by toolbar_slot (groups with toolbar_slot come first, then by key)
  const sortedGroupKeys = Object.keys(groupedNodes).sort((a, b) => {
    const aConfig = nodeGroups.find((g) => g.key === a);
    const bConfig = nodeGroups.find((g) => g.key === b);
    const aHasSlot = !!aConfig?.toolbar_slot;
    const bHasSlot = !!bConfig?.toolbar_slot;

    // Groups with toolbar_slot come first
    if (aHasSlot && !bHasSlot) return -1;
    if (!aHasSlot && bHasSlot) return 1;

    // If both have or don't have toolbar_slot, sort by key
    return a.localeCompare(b);
  });

  // Build default group configs for groups not defined in nodeGroups
  const getGroupConfig = (groupKey: string): FolioTiptapNodeGroup => {
    const defined = nodeGroups.find((g) => g.key === groupKey);
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
