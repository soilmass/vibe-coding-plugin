---
name: drag-drop
description: >
  dnd-kit for sortable lists, kanban boards, drop zones, accessible drag handles
allowed-tools: Read, Grep, Glob
---

# Drag & Drop

## Purpose
Drag and drop patterns with dnd-kit for React 19. Covers sortable lists, kanban boards,
drag overlays, keyboard-accessible drag operations, and optimistic reorder persistence.
The ONE skill for drag-and-drop interactions.

## When to Use
- Building sortable/reorderable lists
- Creating kanban boards with cross-column drag
- Adding file drop zones
- Implementing drag-to-reorder with persistence

## When NOT to Use
- File uploads (drop zone only) → `file-uploads`
- List display without reorder → `data-tables`
- Form input ordering → `advanced-form-ux`

## Pattern

### Sortable list with dnd-kit
```tsx
"use client";

import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { useState } from "react";
import { GripVertical } from "lucide-react";

type Item = { id: string; title: string };

function SortableItem({ item }: { item: Item }) {
  const { attributes, listeners, setNodeRef, transform, transition } = useSortable({
    id: item.id,
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  return (
    <div ref={setNodeRef} style={style} className="flex items-center gap-2 rounded-lg border p-3">
      <button {...attributes} {...listeners} className="cursor-grab" aria-label="Drag handle">
        <GripVertical className="h-4 w-4 text-muted-foreground" />
      </button>
      <span>{item.title}</span>
    </div>
  );
}

export function SortableList({
  items: initialItems,
  onReorder,
}: {
  items: Item[];
  onReorder: (items: Item[]) => Promise<void>;
}) {
  const [items, setItems] = useState(initialItems);
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = items.findIndex((i) => i.id === active.id);
    const newIndex = items.findIndex((i) => i.id === over.id);
    const reordered = arrayMove(items, oldIndex, newIndex);

    setItems(reordered); // Optimistic update
    onReorder(reordered); // Persist to server
  }

  return (
    <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
      <SortableContext items={items} strategy={verticalListSortingStrategy}>
        <div className="space-y-2">
          {items.map((item) => (
            <SortableItem key={item.id} item={item} />
          ))}
        </div>
      </SortableContext>
    </DndContext>
  );
}
```

### Kanban board with cross-column drag
```tsx
"use client";

import { DndContext, DragOverlay, type DragEndEvent, type DragStartEvent } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import { useState } from "react";

type Task = { id: string; title: string; column: string };
type Column = { id: string; title: string };

export function KanbanBoard({
  columns,
  tasks: initialTasks,
}: {
  columns: Column[];
  tasks: Task[];
}) {
  const [tasks, setTasks] = useState(initialTasks);
  const [activeTask, setActiveTask] = useState<Task | null>(null);

  function handleDragStart(event: DragStartEvent) {
    setActiveTask(tasks.find((t) => t.id === event.active.id) ?? null);
  }

  function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event;
    if (!over) return;

    setTasks((prev) =>
      prev.map((task) =>
        task.id === active.id ? { ...task, column: over.id as string } : task
      )
    );
    setActiveTask(null);
  }

  return (
    <DndContext onDragStart={handleDragStart} onDragEnd={handleDragEnd}>
      <div className="flex gap-4">
        {columns.map((col) => (
          <div key={col.id} className="w-72 rounded-lg bg-muted/50 p-3">
            <h3 className="mb-3 font-semibold">{col.title}</h3>
            <SortableContext
              items={tasks.filter((t) => t.column === col.id)}
              strategy={verticalListSortingStrategy}
            >
              <div className="space-y-2">
                {tasks
                  .filter((t) => t.column === col.id)
                  .map((task) => (
                    <div key={task.id} className="rounded border bg-card p-3 shadow-sm">
                      {task.title}
                    </div>
                  ))}
              </div>
            </SortableContext>
          </div>
        ))}
      </div>

      <DragOverlay>
        {activeTask && (
          <div className="rounded border bg-card p-3 shadow-lg">{activeTask.title}</div>
        )}
      </DragOverlay>
    </DndContext>
  );
}
```

### Persist reorder with Server Action
```tsx
"use server";

import { db } from "@/lib/db";
import { auth } from "@/lib/auth";
import { revalidateTag } from "next/cache";

export async function reorderItems(orderedIds: string[]) {
  const session = await auth();
  if (!session?.user?.id) return;

  await db.$transaction(
    orderedIds.map((id, index) =>
      db.item.update({ where: { id }, data: { position: index } })
    )
  );

  revalidateTag("items");
}
```

### File drop zone with native drag events
```tsx
"use client";

import { useState, type DragEvent } from "react";

export function FileDropZone({ onFiles }: { onFiles: (files: File[]) => void }) {
  const [isDragging, setIsDragging] = useState(false);

  function handleDrop(e: DragEvent) {
    e.preventDefault();
    setIsDragging(false);
    const files = Array.from(e.dataTransfer.files);
    onFiles(files);
  }

  return (
    <div
      onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
      onDragLeave={() => setIsDragging(false)}
      onDrop={handleDrop}
      className={`flex h-32 items-center justify-center rounded-lg border-2 border-dashed ${
        isDragging ? "border-primary bg-primary/5" : "border-muted-foreground/25"
      }`}
    >
      <p className="text-sm text-muted-foreground">Drop files here</p>
    </div>
  );
}
```

## Anti-pattern

```tsx
// WRONG: mutating state during drag (causes jank)
function handleDragOver(event: DragOverEvent) {
  setTasks((prev) => /* heavy computation during every drag frame */);
}
// Only update state in handleDragEnd, not handleDragOver

// WRONG: no keyboard support
<div draggable onDrag={...}> {/* Not keyboard accessible */}
// CORRECT: use dnd-kit's KeyboardSensor for accessible drag
```

## Common Mistakes
- Mutating state in `onDragOver` instead of `onDragEnd` — causes performance issues
- Missing keyboard sensor — drag is mouse-only without it
- No `DragOverlay` — dragged item disappears from original position
- Using native HTML drag API instead of dnd-kit — poor accessibility
- Forgetting `aria-label` on drag handle buttons

## Checklist
- [ ] dnd-kit `DndContext` with `PointerSensor` and `KeyboardSensor`
- [ ] `SortableContext` with correct strategy (vertical/horizontal)
- [ ] `DragOverlay` for visual feedback during drag
- [ ] Drag handle with `aria-label` for accessibility
- [ ] State updates only in `onDragEnd` (not `onDragOver`)
- [ ] Server Action to persist new order
- [ ] Optimistic reorder before server confirmation

## Composes With
- `react-client-components` — drag interactions require "use client"
- `react-server-actions` — persist reorder via Server Actions
- `accessibility` — keyboard-accessible drag with dnd-kit sensors
- `state-management` — optimistic state management during drag
