---
name: advanced-form-ux
description: >
  Multi-step wizards, auto-save, conditional fields, date/time pickers, combobox, inline editing
allowed-tools: Read, Grep, Glob
---

# Advanced Form UX

## Purpose
Advanced form interaction patterns beyond basic form submission. Covers multi-step wizards,
auto-save with debounce, conditional fields, date pickers, combobox, inline editing, and dynamic
form arrays. The ONE skill for complex form UX.

## When to Use
- Building multi-step wizards or onboarding flows
- Adding auto-save to forms (draft mode)
- Implementing conditional field visibility
- Using date pickers, combobox, or file drop zones
- Building inline-editing interfaces (click-to-edit)
- Adding dynamic form rows (add/remove items)

## When NOT to Use
- Basic form submission → `react-forms`
- Server Action logic → `react-server-actions`
- Form component styling → `shadcn`

## Pattern

### Multi-step wizard with URL-state tracking
```tsx
"use client";

import { useQueryState, parseAsInteger } from "nuqs";
import { z } from "zod";
import { useState } from "react";

const stepSchemas = [
  z.object({ name: z.string().min(1), email: z.string().email() }),
  z.object({ company: z.string().min(1), role: z.string().min(1) }),
  z.object({ plan: z.enum(["free", "pro", "enterprise"]) }),
];

export function OnboardingWizard() {
  const [step, setStep] = useQueryState("step", parseAsInteger.withDefault(0));
  const [data, setData] = useState<Record<string, string>>({});

  function handleNext() {
    const result = stepSchemas[step].safeParse(data);
    if (!result.success) return; // Show validation errors
    setStep(step + 1);
  }

  return (
    <div>
      <div className="flex gap-2 mb-6">
        {stepSchemas.map((_, i) => (
          <div
            key={i}
            className={`h-2 flex-1 rounded ${i <= step ? "bg-primary" : "bg-muted"}`}
          />
        ))}
      </div>

      {step === 0 && <PersonalInfoStep data={data} onChange={setData} />}
      {step === 1 && <CompanyStep data={data} onChange={setData} />}
      {step === 2 && <PlanStep data={data} onChange={setData} />}

      <div className="flex justify-between mt-4">
        <button onClick={() => setStep(Math.max(0, step - 1))} disabled={step === 0}>
          Back
        </button>
        {step < stepSchemas.length - 1 ? (
          <button onClick={handleNext}>Next</button>
        ) : (
          <button onClick={() => submitWizard(data)}>Complete</button>
        )}
      </div>
    </div>
  );
}
```

### Auto-save with debounced Server Actions
```tsx
"use client";

import { useTransition, useRef, useCallback } from "react";
import { saveDraft } from "@/actions/saveDraft";

export function AutoSaveForm({ initialData }: { initialData: Record<string, string> }) {
  const [isPending, startTransition] = useTransition();
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  const debouncedSave = useCallback(
    (formData: Record<string, string>) => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      timeoutRef.current = setTimeout(() => {
        startTransition(async () => {
          await saveDraft(formData);
        });
      }, 1000);
    },
    [startTransition]
  );

  function handleChange(field: string, value: string) {
    const updated = { ...initialData, [field]: value };
    debouncedSave(updated);
  }

  return (
    <form>
      <input
        defaultValue={initialData.title}
        onChange={(e) => handleChange("title", e.target.value)}
      />
      <span className="text-xs text-muted-foreground">
        {isPending ? "Saving..." : "Saved"}
      </span>
    </form>
  );
}
```

### Conditional fields
```tsx
"use client";

import { useState } from "react";

export function ContactForm() {
  const [contactMethod, setContactMethod] = useState<"email" | "phone" | "">("");

  return (
    <form>
      <select
        name="contactMethod"
        value={contactMethod}
        onChange={(e) => setContactMethod(e.target.value as "email" | "phone")}
      >
        <option value="">Select contact method</option>
        <option value="email">Email</option>
        <option value="phone">Phone</option>
      </select>

      {contactMethod === "email" && (
        <input name="email" type="email" placeholder="your@email.com" />
      )}
      {contactMethod === "phone" && (
        <input name="phone" type="tel" placeholder="+1 (555) 000-0000" />
      )}
    </form>
  );
}
```

### shadcn DatePicker (Popover + Calendar)
```tsx
"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { CalendarIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export function DatePicker({ name }: { name: string }) {
  const [date, setDate] = useState<Date>();

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          className={cn("w-[240px] justify-start text-left", !date && "text-muted-foreground")}
        >
          <CalendarIcon className="mr-2 h-4 w-4" />
          {date ? format(date, "PPP") : "Pick a date"}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto p-0">
        <Calendar mode="single" selected={date} onSelect={setDate} />
      </PopoverContent>
      <input type="hidden" name={name} value={date?.toISOString() ?? ""} />
    </Popover>
  );
}
```

### shadcn Combobox (searchable select)
```tsx
"use client";

import { useState } from "react";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { Check, ChevronsUpDown } from "lucide-react";
import { cn } from "@/lib/utils";

export function Combobox({
  options,
  name,
}: {
  options: { value: string; label: string }[];
  name: string;
}) {
  const [open, setOpen] = useState(false);
  const [value, setValue] = useState("");

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button variant="outline" className="w-[240px] justify-between">
          {value ? options.find((o) => o.value === value)?.label : "Select..."}
          <ChevronsUpDown className="ml-2 h-4 w-4 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[240px] p-0">
        <Command>
          <CommandInput placeholder="Search..." />
          <CommandList>
            <CommandEmpty>No results.</CommandEmpty>
            <CommandGroup>
              {options.map((option) => (
                <CommandItem
                  key={option.value}
                  onSelect={() => {
                    setValue(option.value);
                    setOpen(false);
                  }}
                >
                  <Check className={cn("mr-2 h-4 w-4", value === option.value ? "opacity-100" : "opacity-0")} />
                  {option.label}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
      <input type="hidden" name={name} value={value} />
    </Popover>
  );
}
```

### Dynamic form arrays (add/remove rows)
```tsx
"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Plus, Trash2 } from "lucide-react";

type Item = { id: string; name: string; quantity: number };

export function DynamicItemList() {
  const [items, setItems] = useState<Item[]>([{ id: crypto.randomUUID(), name: "", quantity: 1 }]);

  function addItem() {
    setItems([...items, { id: crypto.randomUUID(), name: "", quantity: 1 }]);
  }

  function removeItem(id: string) {
    setItems(items.filter((item) => item.id !== id));
  }

  return (
    <div className="space-y-2">
      {items.map((item, i) => (
        <div key={item.id} className="flex gap-2 items-center">
          <input name={`items[${i}].name`} placeholder="Item name" className="flex-1" />
          <input name={`items[${i}].quantity`} type="number" min={1} className="w-20" />
          <Button variant="ghost" size="icon" onClick={() => removeItem(item.id)}>
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ))}
      <Button variant="outline" onClick={addItem} type="button">
        <Plus className="mr-2 h-4 w-4" /> Add item
      </Button>
    </div>
  );
}
```

### Inline editing (click-to-edit)
```tsx
"use client";

import { useState, useRef, useEffect } from "react";

export function InlineEdit({
  value,
  onSave,
}: {
  value: string;
  onSave: (value: string) => Promise<void>;
}) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(value);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (editing) inputRef.current?.focus();
  }, [editing]);

  async function handleSave() {
    await onSave(draft);
    setEditing(false);
  }

  if (!editing) {
    return (
      <span
        onClick={() => setEditing(true)}
        className="cursor-pointer rounded px-1 hover:bg-muted"
      >
        {value}
      </span>
    );
  }

  return (
    <input
      ref={inputRef}
      value={draft}
      onChange={(e) => setDraft(e.target.value)}
      onBlur={handleSave}
      onKeyDown={(e) => {
        if (e.key === "Enter") handleSave();
        if (e.key === "Escape") { setDraft(value); setEditing(false); }
      }}
    />
  );
}
```

## Anti-pattern

```tsx
// WRONG: wizard state in useState only (lost on refresh)
const [step, setStep] = useState(0);
// URL shows /onboarding regardless of step — refresh resets to step 0

// CORRECT: track step in URL
const [step, setStep] = useQueryState("step", parseAsInteger.withDefault(0));

// WRONG: auto-save without debounce (fires on every keystroke)
onChange={(e) => startTransition(() => saveDraft({ title: e.target.value }))}
// Sends a request per character!
```

## Common Mistakes
- Wizard state in `useState` only — lost on page refresh, use URL state
- Auto-save without debounce — floods server with requests
- Missing per-step validation — users skip past invalid steps
- Dynamic arrays without stable keys — causes input value loss on reorder
- Date picker without hidden input — date not included in FormData

## Checklist
- [ ] Multi-step wizard uses URL state for step tracking
- [ ] Per-step Zod validation before progression
- [ ] Auto-save uses debounced Server Action with `useTransition`
- [ ] Date picker includes hidden `<input>` for FormData
- [ ] Combobox includes hidden `<input>` for FormData
- [ ] Dynamic arrays use stable keys (not array index)
- [ ] Inline edit supports Enter to save, Escape to cancel

## Composes With
- `react-forms` — basic form patterns and useActionState
- `react-server-actions` — Server Actions for auto-save and wizard submission
- `shadcn` — Calendar, Command, Popover, Button components
- `state-management` — URL state with nuqs for wizard steps
