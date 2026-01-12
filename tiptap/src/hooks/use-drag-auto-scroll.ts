import * as React from "react";

interface UseDragAutoScrollOptions {
  scrollContainerRef: React.RefObject<HTMLElement | null>;
}

/**
 * Hook that enables auto-scrolling when dragging elements near the edges of a scroll container.
 * Adapted from the nested fields component auto-scroll implementation.
 */
export function useDragAutoScroll({
  scrollContainerRef,
}: UseDragAutoScrollOptions): void {
  const autoScrollCleanupRef = React.useRef<(() => void) | null>(null);

  React.useEffect(() => {
    const scrollContainer = scrollContainerRef.current;
    if (!scrollContainer) return;

    const baseScrollSpeed = 3;
    const maxScrollSpeed = 15;
    const scrollSensitivity = 50;
    const accelerationRate = 0.015;
    const maxAcceleration = 1.3;
    const RECT_CACHE_FRAMES = 3; // Recalculate rect every 3 frames (~50ms)

    let rafId: number | null = null;
    let lastMouseY: number | null = null;
    let edgeTime = 0;

    // Cache container rect - invalidate on window resize
    let cachedRect: DOMRect | null = null;
    let rectCacheFrame = 0;
    let cachedRectWindowWidth = window.innerWidth;
    let cachedRectWindowHeight = window.innerHeight;

    const updateMousePosition = (e: MouseEvent | DragEvent) => {
      if (e && e.clientY !== undefined) {
        lastMouseY = e.clientY;
      }
    };

    const calculateScrollSpeed = (distanceFromEdge: number): number => {
      const distanceFactor = 1 - distanceFromEdge / scrollSensitivity;
      const distanceSpeed =
        baseScrollSpeed +
        (maxScrollSpeed - baseScrollSpeed) * (distanceFactor * distanceFactor);
      const timeMultiplier =
        1 + Math.min(edgeTime * accelerationRate, maxAcceleration - 1);
      return distanceSpeed * timeMultiplier;
    };

    const performAutoScroll = () => {
      if (lastMouseY === null) {
        edgeTime = 0;
        rafId = window.requestAnimationFrame(performAutoScroll);
        return;
      }

      const mouseY = lastMouseY;
      let scrollDelta = 0;
      let distanceFromEdge = 0;

      // Cache getBoundingClientRect() - expensive operation
      // Invalidate cache if window size changed
      const currentWidth = window.innerWidth;
      const currentHeight = window.innerHeight;
      const needsRectRecalc =
        !cachedRect ||
        rectCacheFrame === 0 ||
        cachedRectWindowWidth !== currentWidth ||
        cachedRectWindowHeight !== currentHeight;

      if (needsRectRecalc) {
        cachedRect = scrollContainer.getBoundingClientRect();
        cachedRectWindowWidth = currentWidth;
        cachedRectWindowHeight = currentHeight;
        rectCacheFrame = RECT_CACHE_FRAMES;
      } else {
        rectCacheFrame--;
      }

      // Ensure cachedRect is available
      if (!cachedRect) {
        rafId = window.requestAnimationFrame(performAutoScroll);
        return;
      }

      const containerTop = cachedRect.top;
      const containerHeight = cachedRect.bottom - containerTop;
      const relativeY = mouseY - containerTop;

      // Early exit if not near edges
      if (
        relativeY >= scrollSensitivity &&
        relativeY <= containerHeight - scrollSensitivity
      ) {
        edgeTime = 0;
        cachedRect = null; // Clear cache when not scrolling
        rafId = window.requestAnimationFrame(performAutoScroll);
        return;
      }

      if (relativeY < scrollSensitivity) {
        distanceFromEdge = relativeY;
        scrollDelta = -calculateScrollSpeed(distanceFromEdge);
        edgeTime += 1;
      } else {
        distanceFromEdge = containerHeight - relativeY;
        scrollDelta = calculateScrollSpeed(distanceFromEdge);
        edgeTime += 1;
      }

      if (scrollDelta !== 0) {
        const currentScroll = scrollContainer.scrollTop;
        const maxScroll =
          scrollContainer.scrollHeight - scrollContainer.clientHeight;

        if (
          (scrollDelta < 0 && currentScroll > 0) ||
          (scrollDelta > 0 && currentScroll < maxScroll)
        ) {
          scrollContainer.scrollTop += scrollDelta;
        }
      }

      rafId = window.requestAnimationFrame(performAutoScroll);
    };

    const startAutoScroll = () => {
      // Stop any existing auto-scroll
      if (autoScrollCleanupRef.current) {
        autoScrollCleanupRef.current();
      }

      rafId = window.requestAnimationFrame(performAutoScroll);

      const onMouseMove = (e: MouseEvent) => updateMousePosition(e);
      const onDragOver = (e: DragEvent) => updateMousePosition(e);
      const onDrag = (e: DragEvent) => updateMousePosition(e);

      document.addEventListener("mousemove", onMouseMove, {
        passive: true,
        capture: true,
      });
      document.addEventListener("dragover", onDragOver, {
        passive: true,
        capture: true,
      });
      document.addEventListener("drag", onDrag, {
        passive: true,
        capture: true,
      });
      scrollContainer.addEventListener("dragover", onDragOver, {
        passive: true,
        capture: true,
      });
      scrollContainer.addEventListener("drag", onDrag, {
        passive: true,
        capture: true,
      });

      autoScrollCleanupRef.current = () => {
        document.removeEventListener("mousemove", onMouseMove, {
          capture: true,
        });
        document.removeEventListener("dragover", onDragOver, {
          capture: true,
        });
        document.removeEventListener("drag", onDrag, { capture: true });
        scrollContainer.removeEventListener("dragover", onDragOver, {
          capture: true,
        });
        scrollContainer.removeEventListener("drag", onDrag, {
          capture: true,
        });
        if (rafId !== null) {
          window.cancelAnimationFrame(rafId);
          rafId = null;
        }
        lastMouseY = null;
        cachedRect = null;
        edgeTime = 0;
      };
    };

    const stopAutoScroll = () => {
      if (autoScrollCleanupRef.current) {
        autoScrollCleanupRef.current();
        autoScrollCleanupRef.current = null;
      }
    };

    // Start auto-scroll on dragstart (listen on document to catch all drags)
    const onDragStart = (e: DragEvent) => {
      // Only start if the drag is within our scroll container or its children
      const target = e.target as HTMLElement;
      if (scrollContainer.contains(target)) {
        startAutoScroll();
      }
    };

    // Stop auto-scroll on dragend or drop
    const onDragEnd = () => {
      stopAutoScroll();
    };

    const onDrop = () => {
      stopAutoScroll();
    };

    // Listen for dragstart on document to catch drags starting anywhere
    document.addEventListener("dragstart", onDragStart, { capture: true });
    document.addEventListener("dragend", onDragEnd, { capture: true });
    scrollContainer.addEventListener("drop", onDrop, { capture: true });

    // Cleanup on unmount
    return () => {
      stopAutoScroll();
      document.removeEventListener("dragstart", onDragStart, {
        capture: true,
      });
      document.removeEventListener("dragend", onDragEnd, { capture: true });
      scrollContainer.removeEventListener("drop", onDrop, { capture: true });
    };
  }, [scrollContainerRef]);
}
