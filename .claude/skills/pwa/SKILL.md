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

### Premium PWA UI Patterns

#### Animated connectivity indicator
```tsx
"use client";
import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { WifiOff, Wifi } from "lucide-react";

export function ConnectivityBanner() {
  const [online, setOnline] = useState(true);
  const [showReconnected, setShowReconnected] = useState(false);

  useEffect(() => {
    const goOffline = () => setOnline(false);
    const goOnline = () => {
      setOnline(true);
      setShowReconnected(true);
      setTimeout(() => setShowReconnected(false), 3000);
    };
    window.addEventListener("offline", goOffline);
    window.addEventListener("online", goOnline);
    return () => {
      window.removeEventListener("offline", goOffline);
      window.removeEventListener("online", goOnline);
    };
  }, []);

  return (
    <AnimatePresence>
      {!online && (
        <motion.div
          initial={{ y: -40, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: -40, opacity: 0 }}
          transition={{ type: "spring", stiffness: 300, damping: 25 }}
          className="fixed inset-x-0 top-0 z-50 flex items-center justify-center gap-2 bg-amber-500 py-2 text-sm font-medium text-white"
        >
          <WifiOff className="h-4 w-4" />
          You're offline — changes will sync when reconnected
        </motion.div>
      )}
      {showReconnected && (
        <motion.div
          initial={{ y: -40, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: -40, opacity: 0 }}
          className="fixed inset-x-0 top-0 z-50 flex items-center justify-center gap-2 bg-green-500 py-2 text-sm font-medium text-white"
        >
          <Wifi className="h-4 w-4" />
          Back online — syncing...
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

#### Animated install prompt banner
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { Download, X } from "lucide-react";
import { Button } from "@/components/ui/button";

export function InstallBanner({ deferredPrompt, onDismiss }: {
  deferredPrompt: BeforeInstallPromptEvent | null;
  onDismiss: () => void;
}) {
  if (!deferredPrompt) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ y: 100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        exit={{ y: 100, opacity: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 25 }}
        className="fixed inset-x-4 bottom-4 z-50 flex items-center gap-4 rounded-2xl border bg-card p-4 shadow-xl sm:inset-x-auto sm:right-4 sm:max-w-sm"
      >
        <div className="rounded-xl bg-primary/10 p-3">
          <Download className="h-6 w-6 text-primary" />
        </div>
        <div className="flex-1">
          <p className="text-sm font-semibold">Install App</p>
          <p className="text-xs text-muted-foreground">Get the full experience with offline access</p>
        </div>
        <Button
          size="sm"
          onClick={async () => { await deferredPrompt.prompt(); onDismiss(); }}
        >
          Install
        </Button>
        <button onClick={onDismiss} className="p-1 text-muted-foreground hover:text-foreground">
          <X className="h-4 w-4" />
        </button>
      </motion.div>
    </AnimatePresence>
  );
}
```

#### SW update toast with refresh
```tsx
"use client";
import { toast } from "sonner";

// Call when service worker detects update
export function promptSwUpdate(registration: ServiceWorkerRegistration) {
  toast("Update available", {
    description: "A new version is ready.",
    action: {
      label: "Refresh",
      onClick: () => {
        registration.waiting?.postMessage({ type: "SKIP_WAITING" });
        window.location.reload();
      },
    },
    duration: Infinity, // Don't auto-dismiss
  });
}
```

## Composes With
- `notifications` — push notification support via service worker
- `caching` — cache strategy alignment (HTTP cache + SW cache)
- `deploy` — service worker versioning in CI/CD
- `nextjs-metadata` — manifest and viewport metadata
- `animation` — connectivity banner, install prompt transitions
