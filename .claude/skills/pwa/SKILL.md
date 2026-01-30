---
name: pwa
description: >
  Progressive Web App — Web App Manifest, Workbox service worker, offline support, install prompt, background sync
allowed-tools: Read, Grep, Glob
---

# PWA

## Purpose
Progressive Web App capabilities for Next.js 15. Covers Web App Manifest, Workbox-powered
service worker with caching strategies, offline fallback pages, install prompt UI,
background sync for failed mutations, and push notification integration.

## When to Use
- Making app installable with Web App Manifest
- Adding offline support with service worker caching
- Implementing background sync for offline mutations
- Showing install prompt to users
- Precaching critical routes and assets

## When NOT to Use
- Native mobile app → React Native
- Simple caching → `caching` skill with HTTP headers
- Push notifications only → `notifications`
- Server-side caching → `caching`

## Pattern

### Web App Manifest
```json
// public/manifest.json
{
  "name": "My App",
  "short_name": "App",
  "description": "My Next.js PWA",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

### Manifest metadata in layout
```tsx
// src/app/layout.tsx
import type { Metadata, Viewport } from "next";

export const metadata: Metadata = {
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "My App",
  },
};

export const viewport: Viewport = {
  themeColor: "#000000",
};
```

### Workbox service worker
```tsx
// public/sw.js
import { precacheAndRoute } from "workbox-precaching";
import { registerRoute } from "workbox-routing";
import { NetworkFirst, CacheFirst, StaleWhileRevalidate } from "workbox-strategies";
import { ExpirationPlugin } from "workbox-expiration";
import { BackgroundSyncPlugin } from "workbox-background-sync";

// Precache static assets
precacheAndRoute(self.__WB_MANIFEST);

// Network-first for pages (always try fresh)
registerRoute(
  ({ request }) => request.mode === "navigate",
  new NetworkFirst({
    cacheName: "pages",
    plugins: [new ExpirationPlugin({ maxEntries: 50, maxAgeSeconds: 86400 })],
    networkTimeoutSeconds: 3,
  })
);

// Cache-first for static assets (images, fonts)
registerRoute(
  ({ request }) => ["image", "font", "style"].includes(request.destination),
  new CacheFirst({
    cacheName: "assets",
    plugins: [new ExpirationPlugin({ maxEntries: 100, maxAgeSeconds: 2592000 })],
  })
);

// Stale-while-revalidate for API calls
registerRoute(
  ({ url }) => url.pathname.startsWith("/api/"),
  new StaleWhileRevalidate({
    cacheName: "api",
    plugins: [new ExpirationPlugin({ maxEntries: 50, maxAgeSeconds: 300 })],
  })
);
```

### Service worker registration
```tsx
// src/components/sw-register.tsx
"use client";
import { useEffect } from "react";

export function ServiceWorkerRegister() {
  useEffect(() => {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/sw.js");
    }
  }, []);
  return null;
}
```

### Offline fallback page
```tsx
// src/app/offline/page.tsx
export default function OfflinePage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center">
        <h1 className="text-2xl font-bold">You are offline</h1>
        <p className="text-muted-foreground mt-2">
          Check your internet connection and try again.
        </p>
      </div>
    </div>
  );
}
```

### Install prompt
```tsx
// src/components/install-prompt.tsx
"use client";
import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";

export function InstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);

  useEffect(() => {
    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    };
    window.addEventListener("beforeinstallprompt", handler);
    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  if (!deferredPrompt) return null;

  return (
    <Button
      onClick={async () => {
        await deferredPrompt.prompt();
        setDeferredPrompt(null);
      }}
    >
      Install App
    </Button>
  );
}

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
}
```

### Background sync for offline mutations
```tsx
// In service worker
const bgSyncPlugin = new BackgroundSyncPlugin("mutations-queue", {
  maxRetentionTime: 24 * 60, // 24 hours
});

registerRoute(
  ({ url }) => url.pathname.startsWith("/api/") && url.pathname !== "/api/health",
  new NetworkFirst({
    plugins: [bgSyncPlugin],
  }),
  "POST"
);
```

## Anti-pattern

### Caching everything
Don't cache authenticated or personalized content in the service worker. Only cache
public, static assets and pages. User-specific data should use network-first strategy.

### Service worker in development
Disable service worker caching during development — it causes stale content confusion.
Only enable in production builds.

## Common Mistakes
- Missing maskable icon — Android requires it for adaptive icons
- No offline fallback — blank page when offline
- Service worker not updating — use `skipWaiting()` and `clientsClaim()`
- Caching POST requests without BackgroundSync — mutations silently fail
- Not testing offline mode — use Chrome DevTools Network tab

## Checklist
- [ ] `manifest.json` with required icons (192px, 512px, maskable)
- [ ] Manifest linked in layout metadata
- [ ] Service worker registered in client component
- [ ] Network-first for pages, cache-first for static assets
- [ ] Offline fallback page at `/offline`
- [ ] Install prompt component
- [ ] Background sync for POST requests
- [ ] Precaching for critical routes

## Composes With
- `notifications` — push notification support via service worker
- `caching` — cache strategy alignment (HTTP cache + SW cache)
- `deploy` — service worker versioning in CI/CD
- `nextjs-metadata` — manifest and viewport metadata
