---
name: charts
description: >
  Data visualization with shadcn Charts (Recharts), Tremor KPI cards, responsive charts, dark mode theming
allowed-tools: Read, Grep, Glob
---

# Charts

## Purpose
Data visualization patterns for Next.js 15 with shadcn Charts (built on Recharts) and Tremor
KPI components. Covers bar, line, area, pie charts, responsive sizing, dark mode theming,
and server-side data loading. The ONE skill for data visualization.

## When to Use
- Adding charts to dashboards
- Displaying KPI metrics with trend indicators
- Building responsive, dark-mode-aware visualizations
- Loading chart data from Server Components
- Adding real-time chart updates

## When NOT to Use
- Data table display → `data-tables`
- Data fetching logic → `nextjs-data`
- Dashboard layout structure → `layout-patterns`

## Pattern

### shadcn Charts setup
```bash
# Install shadcn chart component (built on Recharts)
npx shadcn@latest add chart
```

### Bar chart
```tsx
"use client";

import { Bar, BarChart, XAxis, YAxis, CartesianGrid } from "recharts";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";

const data = [
  { month: "Jan", revenue: 4000 },
  { month: "Feb", revenue: 3000 },
  { month: "Mar", revenue: 5000 },
];

const chartConfig = {
  revenue: { label: "Revenue", color: "var(--color-primary)" },
} satisfies ChartConfig;

export function RevenueChart() {
  return (
    <ChartContainer config={chartConfig} className="min-h-[300px] w-full">
      <BarChart data={data}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="month" />
        <YAxis />
        <ChartTooltip content={<ChartTooltipContent />} />
        <Bar dataKey="revenue" fill="var(--color-revenue)" radius={4} />
      </BarChart>
    </ChartContainer>
  );
}
```

### Line chart
```tsx
"use client";

import { Line, LineChart, XAxis, YAxis } from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";

const chartConfig = {
  users: { label: "Active Users", color: "var(--color-primary)" },
  sessions: { label: "Sessions", color: "var(--color-muted-foreground)" },
} satisfies ChartConfig;

export function UsersChart({ data }: { data: { date: string; users: number; sessions: number }[] }) {
  return (
    <ChartContainer config={chartConfig} className="min-h-[300px] w-full">
      <LineChart data={data}>
        <XAxis dataKey="date" />
        <YAxis />
        <ChartTooltip content={<ChartTooltipContent />} />
        <Line type="monotone" dataKey="users" stroke="var(--color-users)" strokeWidth={2} dot={false} />
        <Line type="monotone" dataKey="sessions" stroke="var(--color-sessions)" strokeWidth={2} dot={false} />
      </LineChart>
    </ChartContainer>
  );
}
```

### Server Component data loading → Client Component rendering
```tsx
// Server Component: fetch data
import { UsersChart } from "@/components/charts/users-chart";

export default async function DashboardPage() {
  const chartData = await db.analytics.findMany({
    select: { date: true, users: true, sessions: true },
    orderBy: { date: "asc" },
  });

  return <UsersChart data={chartData} />;
}
```

### Dynamic import for chart components
```tsx
import dynamic from "next/dynamic";

const RevenueChart = dynamic(() => import("@/components/charts/revenue-chart"), {
  ssr: false, // Recharts uses browser APIs
  loading: () => <div className="h-[300px] animate-pulse bg-muted rounded" />,
});

export default function Dashboard() {
  return <RevenueChart />;
}
```

### Dark mode theming via CSS custom properties
```css
/* Charts automatically adapt via CSS variables */
@theme {
  --color-chart-1: oklch(0.646 0.222 41.116);
  --color-chart-2: oklch(0.6 0.118 184.704);
  --color-chart-3: oklch(0.398 0.07 227.392);
  --color-chart-4: oklch(0.828 0.189 84.429);
  --color-chart-5: oklch(0.769 0.188 70.08);
}

.dark {
  --color-chart-1: oklch(0.488 0.243 264.376);
  --color-chart-2: oklch(0.696 0.17 162.48);
  --color-chart-3: oklch(0.769 0.188 70.08);
  --color-chart-4: oklch(0.627 0.265 303.9);
  --color-chart-5: oklch(0.645 0.246 16.439);
}
```

### KPI card with trend indicator
```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ArrowUp, ArrowDown } from "lucide-react";

export function KpiCard({
  title,
  value,
  change,
  trend,
}: {
  title: string;
  value: string;
  change: string;
  trend: "up" | "down";
}) {
  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        <div className={`flex items-center text-xs ${trend === "up" ? "text-green-500" : "text-red-500"}`}>
          {trend === "up" ? <ArrowUp className="h-3 w-3" /> : <ArrowDown className="h-3 w-3" />}
          {change}
        </div>
      </CardContent>
    </Card>
  );
}
```

## Anti-pattern

```tsx
// WRONG: importing Recharts in Server Component
import { BarChart } from "recharts"; // Error! Recharts needs "use client"

export default function Page() {
  return <BarChart />; // Can't render in Server Component
}

// WRONG: fixed-width charts
<BarChart width={800} height={300}> {/* Breaks on mobile */}

// CORRECT: use ChartContainer for responsive sizing
<ChartContainer config={config} className="min-h-[300px] w-full">
  <BarChart>...</BarChart>
</ChartContainer>
```

## Common Mistakes
- Importing Recharts in Server Components — needs `"use client"` or dynamic import
- Using fixed `width`/`height` on charts — use `ChartContainer` for responsive
- Not using `ssr: false` with dynamic import — Recharts accesses browser APIs
- Hardcoding chart colors instead of using CSS custom properties — breaks dark mode
- Missing loading skeleton while chart bundle loads

## Checklist
- [ ] Charts rendered in Client Components (or dynamically imported with `ssr: false`)
- [ ] `ChartContainer` wraps charts for responsive sizing
- [ ] Chart colors use CSS custom properties (dark mode compatible)
- [ ] Data loaded in Server Component, passed as props to chart
- [ ] Loading skeleton shown while chart component loads
- [ ] KPI cards show trend direction and percentage change

## Composes With
- `shadcn` — ChartContainer, Card, Tooltip components
- `react-client-components` — charts must be client components
- `dark-mode` — chart colors adapt via CSS custom properties
- `performance` — dynamic import charts to reduce bundle
- `nextjs-data` — server-side data loading for chart data
