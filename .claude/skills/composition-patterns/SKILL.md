---
name: composition-patterns
description: >
  React 19 composition patterns — compound components, context-based state sharing, explicit variants over boolean props, children over render props
allowed-tools: Read, Grep, Glob
---

# Composition Patterns

## Purpose
React 19 component composition patterns for scalable UI architecture. Covers compound components,
context-based state decoupling, explicit variants, and children-first composition. The ONE skill
for structuring component APIs.

## When to Use
- Component has 3+ boolean props controlling appearance/behavior
- Multiple siblings need shared state without prop drilling
- Building reusable component libraries (forms, editors, toolbars)
- Refactoring a component that has grown too many props

## When NOT to Use
- Simple one-off components with 1-2 props → just use props
- Server Components with no interactivity → `react-server-components`
- Form-specific patterns → `react-forms`

## Pattern

### Avoid boolean prop proliferation
```tsx
// WRONG: boolean props multiply combinatorially
<Composer isThread isEditing showAttachments hasToolbar />

// CORRECT: explicit variant components
<ThreadComposer />
<EditComposer />
```

When you find yourself adding `isX` booleans to toggle behavior, create separate
variant components instead. Each variant is explicit about what it does.

### Compound components with shared context
```tsx
"use client";

import { createContext, use, useState } from "react";

type ComposerState = {
  value: string;
  setValue: (v: string) => void;
  isPending: boolean;
};

const ComposerContext = createContext<ComposerState | null>(null);

function useComposer() {
  const ctx = use(ComposerContext);
  if (!ctx) throw new Error("useComposer must be used within Composer.Root");
  return ctx;
}

function Root({ children, onSubmit }: {
  children: React.ReactNode;
  onSubmit: (value: string) => Promise<void>;
}) {
  const [value, setValue] = useState("");
  const [isPending, setIsPending] = useState(false);

  async function handleSubmit() {
    setIsPending(true);
    await onSubmit(value);
    setValue("");
    setIsPending(false);
  }

  return (
    <ComposerContext value={{ value, setValue, isPending }}>
      <form action={handleSubmit}>{children}</form>
    </ComposerContext>
  );
}

function Input({ placeholder }: { placeholder?: string }) {
  const { value, setValue } = useComposer();
  return (
    <textarea
      value={value}
      onChange={(e) => setValue(e.target.value)}
      placeholder={placeholder}
    />
  );
}

function Submit({ children }: { children: React.ReactNode }) {
  const { isPending, value } = useComposer();
  return (
    <button type="submit" disabled={isPending || !value.trim()}>
      {isPending ? "Sending..." : children}
    </button>
  );
}

// Named exports as compound component
export const Composer = { Root, Input, Submit };
```

```tsx
// Usage: compose freely, swap parts, extend
<Composer.Root onSubmit={sendMessage}>
  <Composer.Input placeholder="Type a message..." />
  <EmojiPicker /> {/* Custom child — no prop needed */}
  <Composer.Submit>Send</Composer.Submit>
</Composer.Root>
```

### Decouple state from UI
```tsx
// Provider is the ONLY place that knows state implementation
// UI subcomponents read from context — they don't care if state
// is useState, useReducer, Zustand, or server-synced

function ComposerProvider({ children, adapter }: {
  children: React.ReactNode;
  adapter: ComposerAdapter; // Dependency injection
}) {
  return (
    <ComposerContext value={adapter}>
      {children}
    </ComposerContext>
  );
}

// Swap state implementation without changing UI
<ComposerProvider adapter={useLocalComposer()}>
  <Composer.Input />
  <Composer.Submit>Send</Composer.Submit>
</ComposerProvider>
```

### Generic context interface pattern
```tsx
// Standardized shape for all feature contexts
type FeatureContext<TState, TActions> = {
  state: TState;
  actions: TActions;
  meta: { isPending: boolean; error: string | null };
};

// Every feature context follows the same shape
type ThreadContext = FeatureContext<
  { messages: Message[]; threadId: string },
  { sendMessage: (text: string) => Promise<void>; deleteMessage: (id: string) => void }
>;
```

### Lift state into providers — siblings share without prop drilling
```tsx
// WRONG: prop drilling through parent
function ChatPage() {
  const [messages, setMessages] = useState<Message[]>([]);
  return (
    <>
      <MessageList messages={messages} />
      <Composer onSend={(msg) => setMessages((m) => [...m, msg])} />
    </>
  );
}

// CORRECT: shared context provider, siblings access directly
function ChatPage() {
  return (
    <ChatProvider>
      <MessageList />  {/* reads messages from context */}
      <Composer />     {/* writes to context */}
    </ChatProvider>
  );
}
```

### Children over render props
```tsx
// PREFERRED: children for composition
<Card>
  <CardHeader>Title</CardHeader>
  <CardContent>Body</CardContent>
</Card>

// ACCEPTABLE: render props ONLY when passing data back to parent
<DataLoader url="/api/users">
  {(data) => <UserList users={data} />}
</DataLoader>

// WRONG: render props when children would work
<Card renderHeader={() => <h2>Title</h2>} renderBody={() => <p>Body</p>} />
```

### React 19 APIs for composition
```tsx
"use client";

import { use } from "react";

// use() replaces useContext() — works in conditionals
function ComposerInput() {
  const { value, setValue } = use(ComposerContext);
  return <input value={value} onChange={(e) => setValue(e.target.value)} />;
}

// ref as regular prop — no forwardRef needed
function ComposerTextarea({ ref, ...props }: {
  ref?: React.Ref<HTMLTextAreaElement>;
}) {
  const { value, setValue } = use(ComposerContext);
  return (
    <textarea
      ref={ref}
      value={value}
      onChange={(e) => setValue(e.target.value)}
      {...props}
    />
  );
}
```

## Anti-pattern

```tsx
// WRONG: boolean prop proliferation
<Composer
  isThread={true}
  isEditing={false}
  showAttachments={true}
  showToolbar={false}
  isMinimized={false}
/>
// 5 booleans = 32 possible states, most are invalid

// WRONG: render prop overuse
<Form
  renderField={(field) => <Input {...field} />}
  renderSubmit={(submit) => <Button onClick={submit}>Go</Button>}
  renderError={(error) => <Alert>{error}</Alert>}
/>
// Use children and compound components instead

// WRONG: state trapped inside component
function Composer() {
  const [value, setValue] = useState(""); // Only Composer can read this
  return <textarea value={value} onChange={(e) => setValue(e.target.value)} />;
}
// Siblings can't access the composer value — lift to context

// WRONG: useEffect to sync state up to parent
function Composer({ onChange }: { onChange: (v: string) => void }) {
  const [value, setValue] = useState("");
  useEffect(() => onChange(value), [value, onChange]); // Sync loop risk
}
// Lift state to parent/context instead

// WRONG: reading state from ref on submit
function Composer() {
  const inputRef = useRef<HTMLInputElement>(null);
  function handleSubmit() {
    const value = inputRef.current?.value ?? ""; // Bypasses React state
  }
}
// Use controlled state via context
```

## Common Mistakes
- Adding boolean props instead of creating variant components
- Trapping state inside a component that siblings need
- Using render props when children composition works
- Using `useContext` instead of `use()` (React 19)
- Using `forwardRef` instead of ref-as-prop (React 19)
- Syncing state up to parent with `useEffect` instead of lifting state

## Checklist
- [ ] No component has 3+ boolean mode props — use explicit variants
- [ ] Shared state lives in context providers, not prop-drilled
- [ ] Compound components use `createContext` + named subcomponents
- [ ] `children` used for composition; render props only when passing data back
- [ ] `use()` instead of `useContext()` (React 19)
- [ ] `ref` as regular prop, not `forwardRef`
- [ ] State decoupled from UI — provider is the only place that knows implementation

## Composes With
- `react-client-components` — compound components are client components
- `state-management` — context patterns align with state-management decisions
- `shadcn` — shadcn components use compound patterns (Dialog, DropdownMenu)
- `react-forms` — form composition with compound field components
