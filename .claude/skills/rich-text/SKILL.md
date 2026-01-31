---
name: rich-text
description: >
  Tiptap editor integration with React 19 — toolbar, extensions, content rendering, Server Action persistence
allowed-tools: Read, Grep, Glob
---

# Rich Text

## Purpose
Rich text editor patterns with Tiptap for React 19. Covers editor setup, toolbar composition,
extensions, content rendering in Server Components, and Server Action persistence. The ONE skill
for WYSIWYG editing.

## When to Use
- Adding a rich text / WYSIWYG editor to forms
- Building content editors with formatting toolbar
- Rendering stored rich text content (HTML/JSON)
- Implementing markdown import/export
- Adding collaborative editing features

## When NOT to Use
- Static MDX content from CMS → `cms`
- Basic text input fields → `react-forms`
- File uploads within editor → `file-uploads` (compose with this skill)

## Pattern

### Tiptap editor setup
```bash
npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-link @tiptap/extension-image @tiptap/extension-placeholder
```

```tsx
"use client";

import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Link from "@tiptap/extension-link";
import Placeholder from "@tiptap/extension-placeholder";

export function RichTextEditor({
  content,
  onChange,
}: {
  content: string;
  onChange: (html: string) => void;
}) {
  const editor = useEditor({
    extensions: [
      StarterKit,
      Link.configure({ openOnClick: false }),
      Placeholder.configure({ placeholder: "Start writing..." }),
    ],
    content,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  if (!editor) return null;

  return (
    <div className="rounded-lg border">
      <EditorToolbar editor={editor} />
      <EditorContent
        editor={editor}
        className="prose dark:prose-invert max-w-none p-4 focus:outline-none"
      />
    </div>
  );
}
```

### Toolbar with shadcn Toggle
```tsx
"use client";

import { type Editor } from "@tiptap/react";
import { Toggle } from "@/components/ui/toggle";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import {
  Bold, Italic, Strikethrough, Code, List, ListOrdered,
  Heading1, Heading2, Quote, Undo, Redo,
} from "lucide-react";

export function EditorToolbar({ editor }: { editor: Editor }) {
  return (
    <div className="flex flex-wrap gap-1 border-b p-1">
      <Toggle
        size="sm"
        pressed={editor.isActive("bold")}
        onPressedChange={() => editor.chain().focus().toggleBold().run()}
        aria-label="Bold"
      >
        <Bold className="h-4 w-4" />
      </Toggle>
      <Toggle
        size="sm"
        pressed={editor.isActive("italic")}
        onPressedChange={() => editor.chain().focus().toggleItalic().run()}
        aria-label="Italic"
      >
        <Italic className="h-4 w-4" />
      </Toggle>
      <Toggle
        size="sm"
        pressed={editor.isActive("strike")}
        onPressedChange={() => editor.chain().focus().toggleStrike().run()}
        aria-label="Strikethrough"
      >
        <Strikethrough className="h-4 w-4" />
      </Toggle>
      <Toggle
        size="sm"
        pressed={editor.isActive("code")}
        onPressedChange={() => editor.chain().focus().toggleCode().run()}
        aria-label="Code"
      >
        <Code className="h-4 w-4" />
      </Toggle>

      <div className="mx-1 w-px bg-border" />

      <ToggleGroup type="single" size="sm">
        <ToggleGroupItem
          value="h1"
          aria-label="Heading 1"
          data-state={editor.isActive("heading", { level: 1 }) ? "on" : "off"}
          onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}
        >
          <Heading1 className="h-4 w-4" />
        </ToggleGroupItem>
        <ToggleGroupItem
          value="h2"
          aria-label="Heading 2"
          data-state={editor.isActive("heading", { level: 2 }) ? "on" : "off"}
          onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
        >
          <Heading2 className="h-4 w-4" />
        </ToggleGroupItem>
      </ToggleGroup>

      <div className="mx-1 w-px bg-border" />

      <Toggle
        size="sm"
        pressed={editor.isActive("bulletList")}
        onPressedChange={() => editor.chain().focus().toggleBulletList().run()}
        aria-label="Bullet list"
      >
        <List className="h-4 w-4" />
      </Toggle>
      <Toggle
        size="sm"
        pressed={editor.isActive("orderedList")}
        onPressedChange={() => editor.chain().focus().toggleOrderedList().run()}
        aria-label="Numbered list"
      >
        <ListOrdered className="h-4 w-4" />
      </Toggle>
      <Toggle
        size="sm"
        pressed={editor.isActive("blockquote")}
        onPressedChange={() => editor.chain().focus().toggleBlockquote().run()}
        aria-label="Blockquote"
      >
        <Quote className="h-4 w-4" />
      </Toggle>

      <div className="mx-1 w-px bg-border" />

      <Toggle size="sm" onPressedChange={() => editor.chain().focus().undo().run()} aria-label="Undo">
        <Undo className="h-4 w-4" />
      </Toggle>
      <Toggle size="sm" onPressedChange={() => editor.chain().focus().redo().run()} aria-label="Redo">
        <Redo className="h-4 w-4" />
      </Toggle>
    </div>
  );
}
```

### Rendering stored content (Server Component)
```tsx
// Server Component — render stored HTML safely
import DOMPurify from "isomorphic-dompurify";

export function RichTextContent({ html }: { html: string }) {
  const clean = DOMPurify.sanitize(html);

  return (
    <article
      className="prose dark:prose-invert max-w-none"
      dangerouslySetInnerHTML={{ __html: clean }}
    />
  );
}
```

### Saving content via debounced Server Action
```tsx
"use client";

import { useTransition, useRef, useCallback } from "react";
import { saveContent } from "@/actions/saveContent";
import { RichTextEditor } from "@/components/rich-text-editor";

export function ContentEditor({ postId, initialContent }: { postId: string; initialContent: string }) {
  const [isPending, startTransition] = useTransition();
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  const handleChange = useCallback(
    (html: string) => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      timeoutRef.current = setTimeout(() => {
        startTransition(async () => {
          await saveContent(postId, html);
        });
      }, 1500);
    },
    [postId, startTransition]
  );

  return (
    <div>
      <RichTextEditor content={initialContent} onChange={handleChange} />
      <p className="text-xs text-muted-foreground mt-2">
        {isPending ? "Saving..." : "All changes saved"}
      </p>
    </div>
  );
}
```

### Markdown export
```tsx
import { generateHTML, generateJSON } from "@tiptap/html";
import StarterKit from "@tiptap/starter-kit";

// HTML → Tiptap JSON
function htmlToJson(html: string) {
  return generateJSON(html, [StarterKit]);
}

// Tiptap JSON → HTML
function jsonToHtml(json: Record<string, unknown>) {
  return generateHTML(json, [StarterKit]);
}
```

## Anti-pattern

```tsx
// WRONG: rendering stored HTML without sanitization (XSS vulnerability)
<div dangerouslySetInnerHTML={{ __html: userContent }} />
// Always sanitize with DOMPurify before rendering

// WRONG: importing editor in Server Component
import { useEditor } from "@tiptap/react"; // Error! Needs "use client"
export default function Page() { ... }

// WRONG: no accessible labels on toolbar buttons
<button onClick={() => editor.chain().focus().toggleBold().run()}>
  <Bold /> {/* No aria-label — screen readers say "button" */}
</button>
```

## Common Mistakes
- Rendering stored HTML without `DOMPurify.sanitize()` — XSS vulnerability
- Importing `@tiptap/react` in Server Components — needs `"use client"`
- Missing `aria-label` on toolbar icon buttons
- Auto-saving without debounce — sends request on every keystroke
- Not using `prose dark:prose-invert` for rendered content — broken dark mode styling

## Checklist
- [ ] Editor component has `"use client"` directive
- [ ] Stored HTML sanitized with `DOMPurify` before rendering
- [ ] Toolbar buttons have `aria-label` attributes
- [ ] Auto-save uses debounced Server Action (1-2s delay)
- [ ] Rendered content uses `prose dark:prose-invert` for styling
- [ ] Editor has placeholder text for empty state

### Premium Editor Polish

#### Floating toolbar with glassmorphism
```tsx
"use client";
import { BubbleMenu, type Editor } from "@tiptap/react";

export function FloatingToolbar({ editor }: { editor: Editor }) {
  return (
    <BubbleMenu
      editor={editor}
      tippyOptions={{ duration: 150 }}
      className={cn(
        "flex items-center gap-0.5 rounded-xl border px-1 py-0.5",
        "bg-background/80 backdrop-blur-xl shadow-lg",
        "dark:bg-card/80 dark:border-white/10",
        "dark:[box-shadow:0_8px_32px_rgba(0,0,0,0.4),inset_0_1px_0_rgba(255,255,255,0.05)]",
        "animate-in fade-in-0 zoom-in-95 duration-150"
      )}
    >
      <Toggle
        size="sm"
        pressed={editor.isActive("bold")}
        onPressedChange={() => editor.chain().focus().toggleBold().run()}
        className="h-8 w-8 rounded-lg"
        aria-label="Bold"
      >
        <Bold className="h-3.5 w-3.5" />
      </Toggle>
      {/* ... more toolbar buttons */}
    </BubbleMenu>
  );
}
```

#### Animated placeholder with fade
```css
/* Tiptap placeholder animation */
.tiptap p.is-editor-empty:first-child::before {
  content: attr(data-placeholder);
  float: left;
  color: var(--color-muted-foreground);
  pointer-events: none;
  height: 0;
  opacity: 0.5;
  animation: placeholder-fade-in 300ms ease forwards;
}

@keyframes placeholder-fade-in {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 0.5; transform: translateY(0); }
}
```

#### Editor focus ring animation
```tsx
// Editor container with animated focus state
<div
  className={cn(
    "rounded-xl border transition-all duration-200",
    "focus-within:ring-2 focus-within:ring-primary/20 focus-within:border-primary/50",
    "focus-within:shadow-[0_0_0_4px_oklch(0.55_0.2_270/0.08)]"
  )}
>
  <EditorToolbar editor={editor} />
  <EditorContent
    editor={editor}
    className="prose dark:prose-invert max-w-none p-4 focus:outline-none"
  />
</div>
```

#### Save status with animated indicator
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { Check, Loader2, Cloud } from "lucide-react";

type SaveStatus = "idle" | "saving" | "saved";

export function SaveIndicator({ status }: { status: SaveStatus }) {
  return (
    <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
      <AnimatePresence mode="wait">
        {status === "saving" && (
          <motion.div key="saving" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <Loader2 className="h-3 w-3 animate-spin" />
          </motion.div>
        )}
        {status === "saved" && (
          <motion.div
            key="saved"
            initial={{ opacity: 0, scale: 0.5 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ type: "spring", stiffness: 500, damping: 25 }}
          >
            <Check className="h-3 w-3 text-green-500" />
          </motion.div>
        )}
        {status === "idle" && (
          <motion.div key="idle" initial={{ opacity: 0 }} animate={{ opacity: 0.5 }}>
            <Cloud className="h-3 w-3" />
          </motion.div>
        )}
      </AnimatePresence>
      <span>{status === "saving" ? "Saving..." : status === "saved" ? "Saved" : "Draft"}</span>
    </div>
  );
}
```

#### Empty state with illustration
```tsx
// When editor has no content and is not focused
export function EditorEmptyState() {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="mb-3 rounded-xl bg-muted/50 p-4"
      >
        <FileText className="h-8 w-8 text-muted-foreground/50" />
      </motion.div>
      <p className="text-sm text-muted-foreground">Start writing something amazing...</p>
      <p className="mt-1 text-xs text-muted-foreground/60">Use / for commands, ** for bold</p>
    </div>
  );
}
```

## Composes With
- `react-client-components` — editor requires "use client"
- `react-server-actions` — content persistence via Server Actions
- `file-uploads` — image upload within editor
- `shadcn` — Toggle, ToggleGroup for toolbar
- `security` — DOMPurify for XSS prevention
- `cms` — rich text content from headless CMS rendering
- `accessibility` — editor keyboard navigation and ARIA labels
- `animation` — toolbar transitions, save status animations
- `visual-design` — glassmorphism toolbar, focus ring styling
- `dark-mode` — editor chrome adapts to theme
