---
name: sound-design
description: >
  Howler.js audio setup, interaction sounds on hover/click, ambient background audio, audio sprites, Web Audio API spatial sound, mute toggle with persistence, reduced motion auto-mute
allowed-tools: Read, Grep, Glob
---

# Sound Design

## Purpose

Sound design patterns for Next.js 15 + React 19. Covers Howler.js setup (preload, volume), interaction sounds on hover/click, ambient background audio (loop, user gesture required), audio sprites (single file, multiple sounds), Web Audio API basics (spatial/3D), mute toggle with localStorage persistence, and prefers-reduced-motion auto-disable. The ONE skill for sonic experiences.

## When to Use

- Adding click/hover sound effects to UI elements
- Setting up ambient background audio or music
- Using audio sprites for efficient sound loading
- Creating spatial/3D audio tied to element positions
- Building a mute/unmute toggle with persistence
- Adding sound to scroll events or animations

## When NOT to Use

- Video playback — use native `<video>` element
- Podcast/music player UI — custom implementation beyond this skill
- Notification sounds (system level) — use `notifications` skill
- Voice/speech synthesis — use Web Speech API (not covered here)

## Pattern

### 1. Howler.js Setup

Install dependencies:

```bash
npm install howler
npm install -D @types/howler
```

Create a `SoundProvider` client component with React context. Preload common sounds in `useEffect`. Expose `playSound(name)` via a `useSound()` hook.

```tsx
// src/components/sound/sound-provider.tsx
"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";

type SoundName = "click" | "hover" | "success" | "error" | "whoosh" | "tick";

type SoundContextValue = {
  playSound: (name: SoundName) => void;
  setVolume: (volume: number) => void;
  mute: () => void;
  unmute: () => void;
  isMuted: boolean;
  volume: number;
};

const SoundContext = createContext<SoundContextValue | null>(null);

const SOUND_CONFIG: Record<SoundName, { src: string; volume: number }> = {
  click: { src: "/sounds/click.mp3", volume: 0.4 },
  hover: { src: "/sounds/hover.mp3", volume: 0.3 },
  success: { src: "/sounds/success.mp3", volume: 0.5 },
  error: { src: "/sounds/error.mp3", volume: 0.4 },
  whoosh: { src: "/sounds/whoosh.mp3", volume: 0.3 },
  tick: { src: "/sounds/tick.mp3", volume: 0.3 },
};

function SoundProvider({ children }: { children: ReactNode }) {
  const [isMuted, setIsMuted] = useState(false);
  const [volume, setVolumeState] = useState(1);
  const howlsRef = useRef<Map<SoundName, import("howler").Howl>>(new Map());
  const loadedRef = useRef(false);

  useEffect(() => {
    if (loadedRef.current) return;
    loadedRef.current = true;

    // Dynamic import — Howler must not load on the server
    import("howler").then(({ Howl, Howler }) => {
      // Restore mute state from localStorage
      const savedMute = localStorage.getItem("sound-muted");
      if (savedMute === "true") {
        setIsMuted(true);
        Howler.mute(true);
      }

      // Preload all sounds
      for (const [name, config] of Object.entries(SOUND_CONFIG)) {
        const howl = new Howl({
          src: [config.src],
          volume: config.volume,
          preload: true,
        });
        howlsRef.current.set(name as SoundName, howl);
      }
    });

    return () => {
      howlsRef.current.forEach((howl) => howl.unload());
      howlsRef.current.clear();
    };
  }, []);

  const playSound = useCallback(
    (name: SoundName) => {
      if (isMuted) return;
      const howl = howlsRef.current.get(name);
      howl?.play();
    },
    [isMuted],
  );

  const setVolume = useCallback((vol: number) => {
    const clamped = Math.max(0, Math.min(1, vol));
    setVolumeState(clamped);
    import("howler").then(({ Howler }) => {
      Howler.volume(clamped);
    });
  }, []);

  const mute = useCallback(() => {
    setIsMuted(true);
    localStorage.setItem("sound-muted", "true");
    import("howler").then(({ Howler }) => Howler.mute(true));
  }, []);

  const unmute = useCallback(() => {
    setIsMuted(false);
    localStorage.setItem("sound-muted", "false");
    import("howler").then(({ Howler }) => Howler.mute(false));
  }, []);

  return (
    <SoundContext value={{ playSound, setVolume, mute, unmute, isMuted, volume }}>
      {children}
    </SoundContext>
  );
}

function useSound() {
  const ctx = useContext(SoundContext);
  if (!ctx) throw new Error("useSound must be used within SoundProvider");
  return ctx;
}

export { SoundProvider, useSound };
export type { SoundName };
```

Mount the provider in a layout (keep the layout itself a Server Component):

```tsx
// src/app/layout.tsx
import { SoundProvider } from "@/components/sound/sound-provider";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <SoundProvider>{children}</SoundProvider>
      </body>
    </html>
  );
}
```

### 2. Interaction Sounds

`SoundButton` and `SoundLink` components that play sounds on click and hover. Interaction sounds should stay at 0.3-0.5 volume — never full blast.

```tsx
// src/components/sound/sound-button.tsx
"use client";

import { useSound, type SoundName } from "@/components/sound/sound-provider";
import { cn } from "@/lib/utils";
import type { ComponentProps } from "react";

type SoundButtonProps = ComponentProps<"button"> & {
  clickSound?: SoundName;
  hoverSound?: SoundName;
};

function SoundButton({
  clickSound = "click",
  hoverSound = "hover",
  className,
  onClick,
  onMouseEnter,
  children,
  ...props
}: SoundButtonProps) {
  const { playSound } = useSound();

  return (
    <button
      className={cn("cursor-pointer", className)}
      onClick={(e) => {
        playSound(clickSound);
        onClick?.(e);
      }}
      onMouseEnter={(e) => {
        playSound(hoverSound);
        onMouseEnter?.(e);
      }}
      {...props}
    >
      {children}
    </button>
  );
}

export { SoundButton };
```

```tsx
// src/components/sound/sound-link.tsx
"use client";

import Link from "next/link";
import { useSound, type SoundName } from "@/components/sound/sound-provider";
import type { ComponentProps } from "react";

type SoundLinkProps = ComponentProps<typeof Link> & {
  clickSound?: SoundName;
  hoverSound?: SoundName;
};

function SoundLink({
  clickSound = "click",
  hoverSound = "hover",
  onClick,
  onMouseEnter,
  children,
  ...props
}: SoundLinkProps) {
  const { playSound } = useSound();

  return (
    <Link
      onClick={(e) => {
        playSound(clickSound);
        onClick?.(e);
      }}
      onMouseEnter={(e) => {
        playSound(hoverSound);
        onMouseEnter?.(e);
      }}
      {...props}
    >
      {children}
    </Link>
  );
}

export { SoundLink };
```

Recommended sound durations and volumes:

| Sound   | Duration | Volume |
|---------|----------|--------|
| click   | ~50ms    | 0.4    |
| hover   | ~30ms    | 0.3    |
| success | ~200ms   | 0.5    |
| error   | ~150ms   | 0.4    |

### 3. Ambient Background Audio

Background audio must loop, fade in on start, fade out on mute, and requires a user gesture to begin (browser autoplay policy).

```tsx
// src/components/sound/ambient-audio.tsx
"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useSound } from "@/components/sound/sound-provider";

function AmbientAudio({ src = "/sounds/ambient.mp3" }: { src?: string }) {
  const [started, setStarted] = useState(false);
  const howlRef = useRef<import("howler").Howl | null>(null);
  const { isMuted } = useSound();

  useEffect(() => {
    if (!started) return;

    import("howler").then(({ Howl }) => {
      const howl = new Howl({
        src: [src],
        loop: true,
        volume: 0,
        preload: true,
      });

      howlRef.current = howl;
      howl.play();
      howl.fade(0, 0.1, 2000); // Fade in over 2 seconds
    });

    return () => {
      howlRef.current?.unload();
    };
  }, [started, src]);

  // React to mute state changes
  useEffect(() => {
    const howl = howlRef.current;
    if (!howl) return;

    if (isMuted) {
      howl.fade(howl.volume(), 0, 500);
    } else {
      howl.fade(howl.volume(), 0.1, 500);
    }
  }, [isMuted]);

  if (started) return null;

  // User gesture required — show an "Enter" button
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80">
      <button
        onClick={() => setStarted(true)}
        className="rounded-full bg-white px-8 py-4 text-lg font-semibold text-black transition-transform hover:scale-105"
      >
        Enter Site
      </button>
    </div>
  );
}

export { AmbientAudio };
```

### 4. Audio Sprites

A single audio file with multiple sounds at different offsets. One HTTP request instead of many small files — critical for performance.

```tsx
// src/components/sound/sprite-provider.tsx
"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
} from "react";

type SpriteName = "click" | "hover" | "success" | "error" | "whoosh";

// [offset_ms, duration_ms]
const SPRITE_MAP: Record<SpriteName, [number, number]> = {
  click: [0, 100],
  hover: [100, 80],
  success: [200, 300],
  error: [520, 250],
  whoosh: [800, 400],
};

type SpriteContextValue = {
  playSprite: (name: SpriteName) => void;
};

const SpriteContext = createContext<SpriteContextValue | null>(null);

function SpriteProvider({ children }: { children: React.ReactNode }) {
  const howlRef = useRef<import("howler").Howl | null>(null);

  useEffect(() => {
    import("howler").then(({ Howl }) => {
      howlRef.current = new Howl({
        src: ["/sounds/sprites.mp3"],
        sprite: SPRITE_MAP,
        volume: 0.4,
        preload: true,
      });
    });

    return () => {
      howlRef.current?.unload();
    };
  }, []);

  const playSprite = useCallback((name: SpriteName) => {
    howlRef.current?.play(name);
  }, []);

  return (
    <SpriteContext value={{ playSprite }}>
      {children}
    </SpriteContext>
  );
}

function useSprite() {
  const ctx = useContext(SpriteContext);
  if (!ctx) throw new Error("useSprite must be used within SpriteProvider");
  return ctx;
}

export { SpriteProvider, useSprite };
export type { SpriteName };
```

### 5. Web Audio API Spatial Sound

Use the native `AudioContext` and `PannerNode` for 3D positioned audio. Audio pans based on element position relative to viewport center.

```tsx
// src/hooks/use-spatial-sound.ts
"use client";

import { useCallback, useEffect, useRef } from "react";

type SpatialSoundOptions = {
  src: string;
  maxDistance?: number;
};

function useSpatialSound({ src, maxDistance = 1000 }: SpatialSoundOptions) {
  const ctxRef = useRef<AudioContext | null>(null);
  const bufferRef = useRef<AudioBuffer | null>(null);
  const pannerRef = useRef<PannerNode | null>(null);
  const gainRef = useRef<GainNode | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const ctx = new AudioContext();
    ctxRef.current = ctx;

    const panner = ctx.createPanner();
    panner.panningModel = "HRTF";
    panner.distanceModel = "linear";
    panner.maxDistance = maxDistance;
    panner.refDistance = 1;
    pannerRef.current = panner;

    const gain = ctx.createGain();
    gain.gain.value = 0.5;
    gainRef.current = gain;

    panner.connect(gain).connect(ctx.destination);

    // Preload audio buffer
    fetch(src)
      .then((res) => res.arrayBuffer())
      .then((data) => ctx.decodeAudioData(data))
      .then((buffer) => {
        bufferRef.current = buffer;
      });

    return () => {
      ctx.close();
    };
  }, [src, maxDistance]);

  const playAt = useCallback((elementX: number, elementY: number) => {
    const ctx = ctxRef.current;
    const buffer = bufferRef.current;
    const panner = pannerRef.current;
    if (!ctx || !buffer || !panner) return;

    // Resume AudioContext if suspended (user gesture required)
    if (ctx.state === "suspended") {
      ctx.resume();
    }

    // Map element position to spatial coordinates
    const centerX = window.innerWidth / 2;
    const centerY = window.innerHeight / 2;
    const x = (elementX - centerX) / centerX; // -1 to 1
    const y = (centerY - elementY) / centerY; // -1 to 1

    panner.positionX.setValueAtTime(x * 10, ctx.currentTime);
    panner.positionY.setValueAtTime(y * 10, ctx.currentTime);
    panner.positionZ.setValueAtTime(-1, ctx.currentTime);

    const source = ctx.createBufferSource();
    source.buffer = buffer;
    source.connect(panner);
    source.start();
  }, []);

  return { playAt };
}

export { useSpatialSound };
```

Usage in a component:

```tsx
"use client";

import { useSpatialSound } from "@/hooks/use-spatial-sound";

function SpatialButton() {
  const { playAt } = useSpatialSound({ src: "/sounds/ping.mp3" });

  return (
    <button
      onClick={(e) => {
        const rect = e.currentTarget.getBoundingClientRect();
        playAt(rect.left + rect.width / 2, rect.top + rect.height / 2);
      }}
      className="rounded-lg bg-indigo-600 px-4 py-2 text-white"
    >
      Spatial Click
    </button>
  );
}

export { SpatialButton };
```

### 6. Mute Toggle with Persistence

Global mute toggle with `localStorage` persistence. Includes keyboard shortcut (M key).

```tsx
// src/components/sound/mute-toggle.tsx
"use client";

import { useEffect } from "react";
import { useSound } from "@/components/sound/sound-provider";
import { Volume2, VolumeX } from "lucide-react";

function MuteToggle() {
  const { isMuted, mute, unmute } = useSound();

  useEffect(() => {
    function handleKeydown(e: KeyboardEvent) {
      if (e.key === "m" || e.key === "M") {
        // Ignore if user is typing in an input
        const tag = (e.target as HTMLElement).tagName;
        if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;

        if (isMuted) {
          unmute();
        } else {
          mute();
        }
      }
    }

    window.addEventListener("keydown", handleKeydown);
    return () => window.removeEventListener("keydown", handleKeydown);
  }, [isMuted, mute, unmute]);

  return (
    <button
      onClick={() => (isMuted ? unmute() : mute())}
      className="fixed bottom-4 right-4 z-50 flex h-10 w-10 items-center justify-center rounded-full bg-black/50 text-white backdrop-blur-sm transition-colors hover:bg-black/70"
      aria-label={isMuted ? "Unmute sounds" : "Mute sounds"}
    >
      {isMuted ? <VolumeX className="h-5 w-5" /> : <Volume2 className="h-5 w-5" />}
    </button>
  );
}

export { MuteToggle };
```

### 7. Reduced Motion Auto-Disable

Check `prefers-reduced-motion` and auto-mute all sounds. Users who prefer reduced motion get silence by default but can opt back in via the mute toggle.

```tsx
// src/hooks/use-reduced-motion.ts
"use client";

import { useEffect, useState } from "react";

function useReducedMotion() {
  const [prefersReduced, setPrefersReduced] = useState(false);

  useEffect(() => {
    const mql = window.matchMedia("(prefers-reduced-motion: reduce)");
    setPrefersReduced(mql.matches);

    function onChange(e: MediaQueryListEvent) {
      setPrefersReduced(e.matches);
    }

    mql.addEventListener("change", onChange);
    return () => mql.removeEventListener("change", onChange);
  }, []);

  return prefersReduced;
}

export { useReducedMotion };
```

Integrate with `SoundProvider` — add this inside the provider component's `useEffect`:

```tsx
// Inside SoundProvider, after loading howls:
const mql = window.matchMedia("(prefers-reduced-motion: reduce)");
if (mql.matches) {
  const userOverride = localStorage.getItem("sound-muted");
  // Only auto-mute if user has not explicitly unmuted
  if (userOverride !== "false") {
    setIsMuted(true);
    Howler.mute(true);
  }
}
```

### 8. Sound on Scroll

Play sounds tied to scroll events. Throttled to prevent sound spam. Uses Intersection Observer to trigger sounds at section boundaries.

```tsx
// src/hooks/use-scroll-sound.ts
"use client";

import { useEffect, useRef } from "react";
import { useSound, type SoundName } from "@/components/sound/sound-provider";

type ScrollSoundOptions = {
  /** Sound to play when section enters viewport */
  enterSound?: SoundName;
  /** Minimum ms between sound plays */
  throttleMs?: number;
  /** IntersectionObserver threshold (0-1) */
  threshold?: number;
};

function useScrollSound(
  ref: React.RefObject<HTMLElement | null>,
  options: ScrollSoundOptions = {},
) {
  const {
    enterSound = "tick",
    throttleMs = 200,
    threshold = 0.5,
  } = options;
  const { playSound } = useSound();
  const lastPlayRef = useRef(0);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;

          const now = Date.now();
          if (now - lastPlayRef.current < throttleMs) continue;

          lastPlayRef.current = now;
          playSound(enterSound);
        }
      },
      { threshold },
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [ref, enterSound, throttleMs, threshold, playSound]);
}

export { useScrollSound };
```

Usage with scroll sections:

```tsx
"use client";

import { useRef } from "react";
import { useScrollSound } from "@/hooks/use-scroll-sound";

function ScrollSection({ title }: { title: string }) {
  const sectionRef = useRef<HTMLElement>(null);
  useScrollSound(sectionRef, { enterSound: "tick", throttleMs: 300 });

  return (
    <section ref={sectionRef} className="flex min-h-screen items-center justify-center">
      <h2 className="text-4xl font-bold">{title}</h2>
    </section>
  );
}

export { ScrollSection };
```

## Anti-pattern

```tsx
// WRONG: Autoplay audio without user gesture — browsers block this
function BadAmbient() {
  useEffect(() => {
    const audio = new Audio("/sounds/ambient.mp3");
    audio.play(); // Blocked by browser autoplay policy
  }, []);
  return null;
}

// WRONG: Full volume interaction sounds — startling to users
const howl = new Howl({ src: ["/sounds/click.mp3"], volume: 1.0 }); // Too loud

// WRONG: Loading many separate audio files instead of sprites
const click = new Howl({ src: ["/sounds/click.mp3"] });
const hover = new Howl({ src: ["/sounds/hover.mp3"] });
const success = new Howl({ src: ["/sounds/success.mp3"] });
const error = new Howl({ src: ["/sounds/error.mp3"] });
// 4 HTTP requests — use a single sprite file instead

// WRONG: Sound without any mute option
function NoMuteButton() {
  const { playSound } = useSound();
  return <button onClick={() => playSound("click")}>Click me</button>;
  // Where is the mute toggle? Users need control.
}

// WRONG: Sound on every scroll pixel — machine gun effect
useEffect(() => {
  function onScroll() {
    playSound("tick"); // Fires hundreds of times per scroll
  }
  window.addEventListener("scroll", onScroll);
  return () => window.removeEventListener("scroll", onScroll);
}, [playSound]);
```

## Common Mistakes

1. **Autoplay without user interaction** — Browsers block `audio.play()` and `AudioContext` until a user gesture (click, tap). Always gate audio behind a button or interaction event.

2. **No mute toggle** — Users must always be able to silence audio. Provide a visible, persistent mute button. Never force sound.

3. **Interaction sounds too loud** — Keep interaction sounds at 0.3-0.5 volume. Full volume clicks are jarring and drive users away.

4. **Loading Howler in SSR** — Howler accesses `window` and `Audio`. Always use dynamic `import("howler")` or guard with `typeof window !== "undefined"`.

5. **Not preloading sounds** — The first play has a noticeable delay if the file is not preloaded. Set `preload: true` in Howl config.

6. **Scroll sounds without throttle** — A scroll event fires hundreds of times per gesture. Without throttling (minimum 200ms gap), you get a machine gun burst of sound.

7. **Missing prefers-reduced-motion check** — Some users are sensitive to audio stimuli. Check the media query and auto-mute by default for those users.

8. **Forgetting AudioContext user gesture requirement** — The Web Audio API requires a user gesture to create or resume an `AudioContext`. Wrap `ctx.resume()` in a click handler.

## Checklist

- [ ] Audio only starts after user gesture (click/tap)
- [ ] Mute toggle visible and persistent (localStorage)
- [ ] `prefers-reduced-motion` auto-mutes by default
- [ ] Interaction sounds at 0.3-0.5 volume (not full blast)
- [ ] Audio sprites used for multiple short sounds
- [ ] Howler loaded via dynamic import (no SSR)
- [ ] Ambient audio fades in/out (no abrupt start/stop)
- [ ] Scroll-triggered sounds throttled (max 1 per 200ms)
- [ ] Sound preloaded before first use

## Advanced Patterns

### Generative audio with Tone.js

Procedural sound that responds to user actions instead of pre-recorded MP3s. Unique per interaction.

```tsx
// src/hooks/use-tone-sound.ts
"use client";

import { useCallback, useEffect, useRef } from "react";

type ToneEngine = {
  synth: InstanceType<typeof import("tone").Synth>;
  context: typeof import("tone");
};

export function useToneSound() {
  const engineRef = useRef<ToneEngine | null>(null);

  useEffect(() => {
    let mounted = true;
    import("tone").then((Tone) => {
      if (!mounted) return;
      const synth = new Tone.Synth({
        oscillator: { type: "sine" },
        envelope: { attack: 0.005, decay: 0.1, sustain: 0, release: 0.1 },
        volume: -20,
      }).toDestination();
      engineRef.current = { synth, context: Tone };
    });
    return () => {
      mounted = false;
      engineRef.current?.synth.dispose();
    };
  }, []);

  const playNote = useCallback((note: string, duration = "32n") => {
    const engine = engineRef.current;
    if (!engine) return;
    if (engine.context.getContext().state !== "running") {
      engine.context.start();
    }
    engine.synth.triggerAttackRelease(note, duration);
  }, []);

  // Play a random note from a scale for organic hover sounds
  const playHover = useCallback(() => {
    const notes = ["C5", "E5", "G5", "B5", "D6"];
    const note = notes[Math.floor(Math.random() * notes.length)];
    playNote(note, "64n");
  }, [playNote]);

  const playSuccess = useCallback(() => {
    const engine = engineRef.current;
    if (!engine) return;
    const now = engine.context.now();
    engine.synth.triggerAttackRelease("C5", "16n", now);
    engine.synth.triggerAttackRelease("E5", "16n", now + 0.08);
    engine.synth.triggerAttackRelease("G5", "8n", now + 0.16);
  }, []);

  const playError = useCallback(() => {
    const engine = engineRef.current;
    if (!engine) return;
    const now = engine.context.now();
    engine.synth.triggerAttackRelease("E4", "16n", now);
    engine.synth.triggerAttackRelease("Eb4", "8n", now + 0.1);
  }, []);

  return { playNote, playHover, playSuccess, playError };
}
```

### Audio visualization (frequency → visuals)

```tsx
"use client";

import { useRef, useEffect, useCallback } from "react";

export function useAudioAnalyzer(audioElement: HTMLAudioElement | null) {
  const analyzerRef = useRef<AnalyserNode | null>(null);
  const dataRef = useRef<Uint8Array>(new Uint8Array(0));

  useEffect(() => {
    if (!audioElement) return;
    const ctx = new AudioContext();
    const source = ctx.createMediaElementSource(audioElement);
    const analyzer = ctx.createAnalyser();
    analyzer.fftSize = 256;
    source.connect(analyzer).connect(ctx.destination);
    analyzerRef.current = analyzer;
    dataRef.current = new Uint8Array(analyzer.frequencyBinCount);

    return () => { ctx.close(); };
  }, [audioElement]);

  const getFrequencyData = useCallback(() => {
    const analyzer = analyzerRef.current;
    if (!analyzer) return dataRef.current;
    analyzer.getByteFrequencyData(dataRef.current);
    return dataRef.current;
  }, []);

  // Get average amplitude (0-255) for simple reactive effects
  const getAmplitude = useCallback(() => {
    const data = getFrequencyData();
    if (data.length === 0) return 0;
    return data.reduce((sum, v) => sum + v, 0) / data.length;
  }, [getFrequencyData]);

  return { getFrequencyData, getAmplitude };
}

// Usage: drive visual elements from audio
// In a RAF loop:
// const amp = getAmplitude();
// element.style.transform = `scale(${1 + amp / 500})`;
```

### Scroll-position pitched sound

Sound that changes pitch based on how far the user has scrolled — creates a theremin-like effect.

```tsx
"use client";

import { useEffect, useRef } from "react";
import { useSound } from "@/components/sound/sound-provider";

export function useScrollPitch() {
  const ctxRef = useRef<AudioContext | null>(null);
  const oscRef = useRef<OscillatorNode | null>(null);
  const gainRef = useRef<GainNode | null>(null);
  const activeRef = useRef(false);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const ctx = new AudioContext();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = "sine";
    gain.gain.value = 0;
    osc.connect(gain).connect(ctx.destination);
    osc.start();
    ctxRef.current = ctx;
    oscRef.current = osc;
    gainRef.current = gain;

    let scrollTimeout: ReturnType<typeof setTimeout>;

    function onScroll() {
      if (ctx.state === "suspended") ctx.resume();

      const progress = window.scrollY / (document.body.scrollHeight - window.innerHeight);
      const freq = 200 + progress * 600; // 200Hz → 800Hz
      osc.frequency.setTargetAtTime(freq, ctx.currentTime, 0.02);

      // Fade in while scrolling
      gain.gain.setTargetAtTime(0.03, ctx.currentTime, 0.01);
      activeRef.current = true;

      // Fade out when scrolling stops
      clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(() => {
        gain.gain.setTargetAtTime(0, ctx.currentTime, 0.1);
        activeRef.current = false;
      }, 150);
    }

    window.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      window.removeEventListener("scroll", onScroll);
      osc.stop();
      ctx.close();
    };
  }, []);
}
```

### Sound palette guidelines

Awwwards sites don't just slap on random MP3s — they design cohesive sound palettes.

| Element | Character | Notes |
|---------|-----------|-------|
| Hover | Soft, high, short | Sine wave ~C5-G5, <50ms, vol 0.1-0.2 |
| Click | Percussive, crisp | Short attack, no sustain, vol 0.3 |
| Success | Ascending, bright | Rising arpeggio C-E-G, vol 0.3-0.4 |
| Error | Descending, muted | Minor interval E-Eb, vol 0.3 |
| Navigation | Whoosh, airy | White noise envelope, 100-200ms |
| Ambient | Minimal, generative | Drone + filtered noise, vol 0.05-0.1 |
| Scroll | Tonal, continuous | Pitch mapped to position, vol 0.02-0.05 |

Design principles:
- Same timbral family across all sounds (all sine, or all FM synthesis)
- Consistent volume envelope shapes (all with fast attack)
- Pitch relationships that form a musical scale
- Never louder than the content it accompanies

## Composes With

- `animation` — coordinate sound with visual animations
- `accessibility` — reduced motion auto-mute, mute controls
- `cursor-effects` — sound on cursor interactions
- `creative-scrolling` — sound tied to scroll position
- `loading-transitions` — sound during page transitions
- `webgl-3d` — spatial audio tied to 3D scene positions
