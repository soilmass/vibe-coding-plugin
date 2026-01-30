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

## Composes With
- `react-client-components` — editor requires "use client"
- `react-server-actions` — content persistence via Server Actions
- `file-uploads` — image upload within editor
- `shadcn` — Toggle, ToggleGroup for toolbar
- `security` — DOMPurify for XSS prevention
