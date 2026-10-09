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

  // A node group must opt into toolbar rendering; group alone is for slash menu organization.
  const toolbarGroups = Object.entries(groupedNodes)
    .flatMap(([groupKey, groupNodes]) => {
      const groupConfig = nodeGroups.find((g) => g.key === groupKey);

      if (!groupConfig?.toolbar_slot) return [];

      return [{ groupKey, groupConfig, nodes: groupNodes }];
    })
    .sort((a, b) => a.groupKey.localeCompare(b.groupKey));

  if (toolbarGroups.length === 0) return null;

  return (
    <>
      {/* Render grouped nodes as dropdowns */}
      {toolbarGroups.map(({ groupKey, groupConfig, nodes }) => {
        return (
          <ToolbarGroup key={groupKey}>
            <NodeDropdown
              groupKey={groupKey}
              groupConfig={groupConfig}
              nodes={nodes}
            />
          </ToolbarGroup>
        );
      })}
    </>
  );
}

export default FolioEditorToolbarNodeGroups;
