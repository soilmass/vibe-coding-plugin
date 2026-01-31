---
name: webgl-3d
description: >
  React Three Fiber Canvas, GLTF model loading, custom shaders, particle systems, 3D text, post-processing effects, useFrame animation, performance optimization
allowed-tools: Read, Grep, Glob
---

# WebGL & 3D

## Purpose
3D and WebGL patterns for Next.js 15 + React 19 using React Three Fiber. Covers Canvas setup,
GLTF model loading, custom shader materials (vertex + fragment), particle systems, 3D text,
post-processing (Bloom, ChromaticAberration), useFrame animation loop, and performance
optimization (LOD, instancing, Suspense fallback). The ONE skill for 3D on the web.

## When to Use
- Adding 3D scenes to a Next.js app
- Loading and displaying 3D models (GLTF/GLB)
- Creating custom shader effects (gradients, noise, waves)
- Building particle systems (stars, snow, dust, sparks)
- Adding 3D text or logos to hero sections
- Post-processing effects (bloom, vignette, chromatic aberration)
- Interactive 3D product viewers or configurators
- Awwwards-level immersive landing pages

## When NOT to Use
- 2D SVG animation or canvas drawing -> `svg-canvas`
- CSS 3D transforms (card flips, rotate) -> `animation`
- 2D canvas-only particles -> `svg-canvas`
- Image galleries or lightboxes -> `image-optimization`
- Simple hover/scroll animations -> `animation`

## Pattern

### React Three Fiber Canvas setup

Install dependencies (R3F v9+ required for React 19 compatibility):
```bash
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
```

> **Important:** R3F v8 is NOT compatible with React 19 / Next.js 15. Use `@react-three/fiber@rc` if v9 stable is not yet released. Also note: `next/dynamic` with `ssr: false` must be called from a Client Component in Next.js 15 App Router — it cannot be used directly in Server Components.

Create the base Scene client component:
```tsx
// src/components/three/Scene.tsx
"use client";

import { Canvas } from "@react-three/fiber";
import { OrbitControls, PerspectiveCamera } from "@react-three/drei";
import { Suspense } from "react";
import type { ReactNode } from "react";

export function Scene({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={className ?? "h-[600px] w-full"}>
      <Suspense fallback={<div className="flex h-full w-full items-center justify-center bg-black/5">Loading 3D...</div>}>
        <Canvas shadows dpr={[1, 2]} gl={{ antialias: true, alpha: true }}>
          <PerspectiveCamera makeDefault position={[0, 0, 5]} fov={45} />
          <ambientLight intensity={0.4} />
          <directionalLight position={[5, 5, 5]} intensity={1} castShadow />
          <OrbitControls enableDamping dampingFactor={0.05} minDistance={2} maxDistance={20} />
          {children}
        </Canvas>
      </Suspense>
    </div>
  );
}
```

Dynamic import for Next.js (critical -- three.js requires `window`):
```tsx
// src/components/three/DynamicScene.tsx
import dynamic from "next/dynamic";

export const DynamicScene = dynamic(
  () => import("./Scene").then((mod) => mod.Scene),
  {
    ssr: false,
    loading: () => (
      <div className="flex h-[600px] w-full items-center justify-center bg-black/5">Loading 3D...</div>
    ),
  }
);
```

Use from a Server Component page:
```tsx
// src/app/page.tsx
import { DynamicScene } from "@/components/three/DynamicScene";

export default function HomePage() {
  return (
    <main>
      <DynamicScene className="h-screen w-full">{/* 3D children */}</DynamicScene>
    </main>
  );
}
```

### GLTF model loading

```tsx
// src/components/three/Model.tsx
"use client";

import { useGLTF, Environment, ContactShadows, Float } from "@react-three/drei";
import { useFrame } from "@react-three/fiber";
import { useRef } from "react";
import type { Group } from "three";
import type { GLTF } from "three-stdlib";

type ModelGLTF = GLTF & {
  nodes: Record<string, THREE.Object3D>;
  materials: Record<string, THREE.Material>;
};

function ProductModel({ url, scale = 1 }: { url: string; scale?: number }) {
  const groupRef = useRef<Group>(null);
  const { nodes, materials } = useGLTF(url) as ModelGLTF;

  return (
    <group ref={groupRef} scale={scale} dispose={null}>
      {Object.entries(nodes).map(([name, node]) => {
        if (!("geometry" in node)) return null;
        return (
          <mesh key={name} geometry={node.geometry}
            material={materials[node.material?.name ?? ""] ?? node.material}
            castShadow receiveShadow />
        );
      })}
    </group>
  );
}

// Preload at module level for faster initial display
useGLTF.preload("/models/product.glb");

export function ModelScene() {
  return (
    <>
      <Environment preset="studio" />
      <ProductModel url="/models/product.glb" scale={1.5} />
    </>
  );
}

// Interactive rotating product viewer
function RotatingModel({ url }: { url: string }) {
  const groupRef = useRef<Group>(null);
  const { scene } = useGLTF(url);

  useFrame((_, delta) => {
    if (groupRef.current) groupRef.current.rotation.y += delta * 0.3;
  });

  return (
    <Float speed={1.5} rotationIntensity={0.2} floatIntensity={0.5}>
      <group ref={groupRef}>
        <primitive object={scene} scale={2} />
      </group>
    </Float>
  );
}

export function ProductViewer() {
  return (
    <>
      <Environment preset="city" />
      <RotatingModel url="/models/shoe.glb" />
      <ContactShadows position={[0, -1.5, 0]} opacity={0.4} scale={10} blur={2} />
    </>
  );
}
```

### Custom shader material

```tsx
// src/components/three/ShaderPlane.tsx
"use client";

import { shaderMaterial } from "@react-three/drei";
import { extend, useFrame } from "@react-three/fiber";
import { useRef } from "react";
import * as THREE from "three";

const WaveShaderMaterial = shaderMaterial(
  {
    uTime: 0,
    uColor1: new THREE.Color("#4338ca"),
    uColor2: new THREE.Color("#7c3aed"),
    uFrequency: 2.0,
    uAmplitude: 0.3,
  },
  // Vertex shader — wave displacement
  /* glsl */ `
    uniform float uTime;
    uniform float uFrequency;
    uniform float uAmplitude;
    varying vec2 vUv;
    varying float vElevation;
    void main() {
      vUv = uv;
      vec3 pos = position;
      float elevation = sin(pos.x * uFrequency + uTime) * uAmplitude
                      + sin(pos.y * uFrequency * 0.8 + uTime * 0.6) * uAmplitude * 0.5;
      pos.z += elevation;
      vElevation = elevation;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
  `,
  // Fragment shader — gradient + noise
  /* glsl */ `
    uniform vec3 uColor1;
    uniform vec3 uColor2;
    uniform float uTime;
    varying vec2 vUv;
    varying float vElevation;
    float random(vec2 st) {
      return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
    }
    void main() {
      float mixStrength = (vElevation + 0.3) / 0.6;
      vec3 color = mix(uColor1, uColor2, mixStrength);
      color += random(vUv + uTime * 0.01) * 0.05;
      gl_FragColor = vec4(color, 1.0);
    }
  `
);

// Register for JSX usage
extend({ WaveShaderMaterial });

// Type augmentation
declare module "@react-three/fiber" {
  interface ThreeElements {
    waveShaderMaterial: THREE.ShaderMaterial & {
      uTime: number;
      uColor1: THREE.Color;
      uColor2: THREE.Color;
      uFrequency: number;
      uAmplitude: number;
    };
  }
}

export function ShaderPlane() {
  const materialRef = useRef<THREE.ShaderMaterial & { uTime: number }>(null);

  useFrame((_, delta) => {
    if (materialRef.current) materialRef.current.uTime += delta;
  });

  return (
    <mesh rotation={[-Math.PI / 4, 0, 0]}>
      <planeGeometry args={[5, 5, 128, 128]} />
      {/* @ts-expect-error -- custom JSX element registered via extend */}
      <waveShaderMaterial ref={materialRef} side={THREE.DoubleSide} />
    </mesh>
  );
}
```

### Particle system

```tsx
// src/components/three/ParticleField.tsx
"use client";

import { Points, PointMaterial } from "@react-three/drei";
import { useFrame } from "@react-three/fiber";
import { useRef, useMemo } from "react";
import * as THREE from "three";

const PARTICLE_COUNT = 5000;

function generatePositions(count: number, spread: number): Float32Array {
  const positions = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    const i3 = i * 3;
    positions[i3] = (Math.random() - 0.5) * spread;
    positions[i3 + 1] = (Math.random() - 0.5) * spread;
    positions[i3 + 2] = (Math.random() - 0.5) * spread;
  }
  return positions;
}

export function ParticleField() {
  const pointsRef = useRef<THREE.Points>(null);
  const positions = useMemo(() => generatePositions(PARTICLE_COUNT, 10), []);

  useFrame((_, delta) => {
    if (pointsRef.current) {
      pointsRef.current.rotation.x += delta * 0.02;
      pointsRef.current.rotation.y += delta * 0.05;
    }
  });

  return (
    <Points ref={pointsRef} positions={positions} stride={3} frustumCulled={false}>
      <PointMaterial transparent color="#8b5cf6" size={0.02}
        sizeAttenuation depthWrite={false} blending={THREE.AdditiveBlending} />
    </Points>
  );
}
```

Instanced particles for better GPU performance:
```tsx
// src/components/three/InstancedParticles.tsx
"use client";

import { useFrame } from "@react-three/fiber";
import { useRef, useMemo } from "react";
import * as THREE from "three";

const INSTANCE_COUNT = 2000;
const tempObject = new THREE.Object3D(); // Pre-allocate outside component
const tempColor = new THREE.Color();

export function InstancedParticles() {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const particles = useMemo(() =>
    Array.from({ length: INSTANCE_COUNT }, () => ({
      position: new THREE.Vector3(
        (Math.random() - 0.5) * 10, (Math.random() - 0.5) * 10, (Math.random() - 0.5) * 10
      ),
      speed: 0.2 + Math.random() * 0.8,
      factor: Math.random(),
    })), []);

  useFrame((state) => {
    if (!meshRef.current) return;
    const time = state.clock.getElapsedTime();
    particles.forEach((p, i) => {
      tempObject.position.set(
        p.position.x + Math.sin(time * p.speed + p.factor) * 0.5,
        p.position.y + Math.cos(time * p.speed * 0.8 + p.factor) * 0.5,
        p.position.z + Math.sin(time * p.speed * 0.6 + p.factor) * 0.3
      );
      tempObject.scale.setScalar(0.02 + Math.sin(time + p.factor) * 0.01);
      tempObject.updateMatrix();
      meshRef.current!.setMatrixAt(i, tempObject.matrix);
      tempColor.setHSL(0.7 + p.factor * 0.1, 0.8, 0.5 + Math.sin(time + p.factor) * 0.2);
      meshRef.current!.setColorAt(i, tempColor);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
    if (meshRef.current.instanceColor) meshRef.current.instanceColor.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, INSTANCE_COUNT]}>
      <sphereGeometry args={[1, 8, 8]} />
      <meshStandardMaterial toneMapped={false} />
    </instancedMesh>
  );
}
```

### 3D text

Geometry-based (Text3D -- heavier, true 3D extrusion):
```tsx
// src/components/three/Text3DTitle.tsx
"use client";

import { Text3D, Center, useMatcapTexture } from "@react-three/drei";
import type { Mesh } from "three";
import { useRef } from "react";

export function Text3DTitle({ text = "HELLO" }: { text?: string }) {
  const meshRef = useRef<Mesh>(null);
  const [matcapTexture] = useMatcapTexture("C7C7D7_4C4E5A_818393_6C6C74", 256);

  return (
    <Center>
      <Text3D ref={meshRef} font="/fonts/Inter_Bold.json"
        size={1} height={0.3} curveSegments={12}
        bevelEnabled bevelThickness={0.02} bevelSize={0.02} bevelSegments={5}>
        {text}
        <meshMatcapMaterial matcap={matcapTexture} />
      </Text3D>
    </Center>
  );
}
```

Troika-based (Text -- lighter, SDF rendering, better for body text):
```tsx
// src/components/three/TextSDF.tsx
"use client";

import { Text } from "@react-three/drei";
import * as THREE from "three";

export function TextSDF({ children = "Awwwards", color = "#ffffff" }: { children?: string; color?: string }) {
  return (
    <Text fontSize={1.5} maxWidth={10} lineHeight={1} letterSpacing={0.02}
      textAlign="center" font="/fonts/Inter-Bold.woff" anchorX="center" anchorY="middle">
      {children}
      <meshStandardMaterial color={color} metalness={0.8} roughness={0.2}
        emissive={new THREE.Color(color)} emissiveIntensity={0.1} />
    </Text>
  );
}
```

### Post-processing effects

```bash
npm install @react-three/postprocessing postprocessing
```

```tsx
// src/components/three/Effects.tsx
"use client";

import { EffectComposer, Bloom, ChromaticAberration, Vignette, Noise } from "@react-three/postprocessing";
import { BlendFunction, KernelSize } from "postprocessing";
import { Vector2 } from "three";

export function PostEffects({
  enableBloom = true,
  enableChroma = false,
  enableVignette = true,
}: { enableBloom?: boolean; enableChroma?: boolean; enableVignette?: boolean }) {
  return (
    <EffectComposer multisampling={0}>
      {enableBloom && (
        <Bloom intensity={1.5} luminanceThreshold={0.6}
          luminanceSmoothing={0.9} kernelSize={KernelSize.LARGE} />
      )}
      {enableChroma && (
        <ChromaticAberration blendFunction={BlendFunction.NORMAL}
          offset={new Vector2(0.002, 0.002)} radialModulation={false} modulationOffset={0} />
      )}
      {enableVignette && (
        <Vignette offset={0.3} darkness={0.7} blendFunction={BlendFunction.NORMAL} />
      )}
      <Noise premultiply blendFunction={BlendFunction.ADD} opacity={0.02} />
    </EffectComposer>
  );
}
```

Performance-aware effect toggling:
```tsx
// src/components/three/AdaptiveEffects.tsx
"use client";

import { useEffect, useState } from "react";
import { PostEffects } from "./Effects";

function useGPUTier(): "low" | "mid" | "high" {
  const [tier, setTier] = useState<"low" | "mid" | "high">("mid");
  useEffect(() => {
    const canvas = document.createElement("canvas");
    const gl = canvas.getContext("webgl");
    if (!gl) { setTier("low"); return; }
    const ext = gl.getExtension("WEBGL_debug_renderer_info");
    const renderer = ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : "";
    setTier(/intel|mesa|swiftshader/i.test(renderer) ? "low" : "high");
  }, []);
  return tier;
}

export function AdaptiveEffects() {
  const [reducedMotion, setReducedMotion] = useState(false);
  const gpuTier = useGPUTier();

  useEffect(() => {
    const mql = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReducedMotion(mql.matches);
    const handler = (e: MediaQueryListEvent) => setReducedMotion(e.matches);
    mql.addEventListener("change", handler);
    return () => mql.removeEventListener("change", handler);
  }, []);

  if (reducedMotion || gpuTier === "low") return null;
  return <PostEffects enableBloom={gpuTier === "high"} enableChroma={gpuTier === "high"} enableVignette />;
}
```

### useFrame animation loop

```tsx
// src/components/three/AnimatedMesh.tsx
"use client";

import { useFrame } from "@react-three/fiber";
import { useRef } from "react";
import * as THREE from "three";

// Pre-allocate outside component to avoid GC pressure in useFrame
const targetPosition = new THREE.Vector3();

// Pattern 1: Rotation (frame-rate independent via delta)
export function RotatingCube() {
  const meshRef = useRef<THREE.Mesh>(null);
  useFrame((_, delta) => {
    if (meshRef.current) {
      meshRef.current.rotation.x += delta * 0.5;
      meshRef.current.rotation.y += delta * 0.8;
    }
  });
  return <mesh ref={meshRef}><boxGeometry /><meshStandardMaterial color="#4338ca" /></mesh>;
}

// Pattern 2: Orbiting with elapsed time
export function OrbitingSphere() {
  const meshRef = useRef<THREE.Mesh>(null);
  useFrame((state) => {
    if (!meshRef.current) return;
    const t = state.clock.elapsedTime;
    meshRef.current.position.set(Math.cos(t) * 3, Math.sin(t * 2) * 0.5, Math.sin(t) * 3);
  });
  return <mesh ref={meshRef}><sphereGeometry args={[0.3, 32, 32]} /><meshStandardMaterial color="#ec4899" emissive="#ec4899" emissiveIntensity={0.5} /></mesh>;
}

// Pattern 3: Lerp-based mouse follow (smooth tracking)
export function MouseFollower() {
  const meshRef = useRef<THREE.Mesh>(null);
  useFrame((state, delta) => {
    if (!meshRef.current) return;
    targetPosition.set(state.pointer.x * 3, state.pointer.y * 3, 0);
    meshRef.current.position.lerp(targetPosition, 1 - Math.exp(-5 * delta));
  });
  return <mesh ref={meshRef}><sphereGeometry args={[0.5, 32, 32]} /><meshStandardMaterial color="#06b6d4" metalness={0.5} roughness={0.2} /></mesh>;
}

// Pattern 4: Priority ordering (-1 runs before default 0)
export function HighPriorityAnimation() {
  const meshRef = useRef<THREE.Mesh>(null);
  useFrame((_, delta) => {
    if (meshRef.current) meshRef.current.rotation.z += delta;
  }, -1);
  return <mesh ref={meshRef}><torusGeometry args={[1, 0.3, 16, 48]} /><meshStandardMaterial color="#f59e0b" /></mesh>;
}
```

### Performance optimization

```tsx
// src/components/three/PerformantScene.tsx
"use client";

import { AdaptiveDpr, AdaptiveEvents, BakeShadows, Instances, Instance,
  PerformanceMonitor, Detailed } from "@react-three/drei";
import { Canvas } from "@react-three/fiber";
import { Suspense, useState, useCallback } from "react";
import type { ReactNode } from "react";

export function PerformantCanvas({ children }: { children: ReactNode }) {
  const [dpr, setDpr] = useState(1.5);
  const handleDecline = useCallback(() => setDpr(1), []);
  const handleIncline = useCallback(() => setDpr(2), []);

  return (
    <Canvas shadows dpr={dpr} gl={{ antialias: true, powerPreference: "high-performance", alpha: false }}>
      <PerformanceMonitor onDecline={handleDecline} onIncline={handleIncline}
        flipflops={3} onFallback={() => setDpr(1)} />
      <AdaptiveDpr pixelated />
      <AdaptiveEvents />
      <BakeShadows />
      <Suspense fallback={null}>{children}</Suspense>
    </Canvas>
  );
}

// Level of Detail: swap geometry by camera distance
export function LodModel() {
  return (
    <Detailed distances={[0, 10, 25]}>
      <mesh><sphereGeometry args={[1, 64, 64]} /><meshStandardMaterial color="#4338ca" /></mesh>
      <mesh><sphereGeometry args={[1, 16, 16]} /><meshStandardMaterial color="#4338ca" /></mesh>
      <mesh><sphereGeometry args={[1, 8, 8]} /><meshStandardMaterial color="#4338ca" /></mesh>
    </Detailed>
  );
}

// Instanced rendering: 1 draw call for many identical meshes
export function InstancedTrees() {
  const positions = [[0, 0, 0], [2, 0, -1], [-1, 0, 2], [3, 0, 3], [-2, 0, -2]] as const;
  return (
    <Instances limit={100} range={positions.length}>
      <boxGeometry args={[0.2, 2, 0.2]} />
      <meshStandardMaterial color="#22c55e" />
      {positions.map(([x, y, z], i) => <Instance key={i} position={[x, y + 1, z]} />)}
    </Instances>
  );
}
```

Performance budget reference:
```
Target: 60 fps (16.67ms per frame)
Triangles: ~100K mobile, ~500K desktop
Draw calls: <100 (use instancing)
Textures: <50MB total VRAM
GLTF: Draco compression (70-90% smaller)
DPR: 1.0 mobile, up to 2.0 desktop
Post-processing: max 2 effects on mobile
```

## Anti-pattern

### WRONG: Canvas without dynamic import (SSR crash)
```tsx
import { Canvas } from "@react-three/fiber"; // CRASHES on server
export default function Page() {
  return <Canvas><mesh /></Canvas>;
}
```
FIX: Always use `next/dynamic` with `ssr: false` for any component importing from `@react-three/fiber`.

### WRONG: useFrame without delta (framerate-dependent)
```tsx
useFrame(() => { mesh.current.rotation.y += 0.01; }); // 120Hz = 2x faster than 60Hz
```
FIX: `useFrame((_, delta) => { mesh.current.rotation.y += delta * 0.5; });`

### WRONG: Loading GLTF without Suspense fallback
```tsx
<Canvas><Model /></Canvas> // Blank screen while model loads
```
FIX: `<Canvas><Suspense fallback={<Loader />}><Model /></Suspense></Canvas>`

### WRONG: Creating objects inside useFrame (GC pressure)
```tsx
useFrame(() => {
  const target = new THREE.Vector3(1, 0, 0); // New object EVERY frame
  mesh.current.position.lerp(target, 0.1);
});
```
FIX: Pre-allocate `const target = new THREE.Vector3(1, 0, 0)` outside the callback.

### WRONG: Missing dispose() for imperative objects
```tsx
const geo = new THREE.BoxGeometry(); // Never freed from GPU memory
```
FIX: Dispose in cleanup: `useEffect(() => () => { geo.dispose(); }, []);`
R3F auto-disposes JSX-declared objects on unmount.

## Common Mistakes

1. **Not using `next/dynamic` with `ssr: false`** -- three.js accesses `window` at import time. Any component importing from `@react-three/fiber`, `@react-three/drei`, or `three` must be dynamically imported with SSR disabled.

2. **Creating objects inside useFrame** -- `new Vector3()`, `new Color()`, `new Matrix4()` inside the loop creates garbage every frame. Pre-allocate outside the component or in refs.

3. **Missing Suspense boundary around GLTF models** -- `useGLTF` suspends while loading. Without Suspense, the entire scene goes blank. Always wrap model components.

4. **Not disposing WebGL resources** -- Geometries, materials, and textures are not garbage collected. R3F handles JSX objects, but imperative objects need manual cleanup.

5. **Using useFrame without delta** -- `rotation += 0.01` runs 2x faster on 120Hz than 60Hz. Always multiply by `delta` for frame-rate independence.

6. **Post-processing without performance check** -- Bloom and ChromaticAberration are GPU-intensive. Use `<PerformanceMonitor>` or GPU tier detection to disable on low-end devices.

7. **Canvas without explicit container size** -- Canvas fills its parent div. No height = 0x0 render. Always set dimensions on the container.

8. **Forgetting `useGLTF.preload()`** -- Models only start loading on mount. Call preload at module level to fetch immediately.

9. **Not respecting `prefers-reduced-motion`** -- Disable particle movement, auto-rotation, and post-processing when this media query matches.

## Checklist

- [ ] Canvas loaded via `next/dynamic` with `ssr: false`
- [ ] Suspense boundary wraps Canvas with a visible loading fallback
- [ ] All useFrame animations use `delta` for frame-rate independence
- [ ] No object creation inside useFrame (pre-allocated in refs or module scope)
- [ ] GLTF models preloaded with `useGLTF.preload()`
- [ ] Geometries/materials/textures disposed on unmount (or JSX-managed)
- [ ] `<PerformanceMonitor>` enabled for adaptive quality
- [ ] Mobile: reduced DPR, fewer particles, simpler geometry
- [ ] `prefers-reduced-motion`: disable or simplify animations
- [ ] Container div has explicit width/height for Canvas sizing
- [ ] Draco compression used for GLTF models (< 1MB target)
- [ ] Post-processing effects gated by GPU tier detection
- [ ] WebGL context loss handled gracefully (fallback UI)

## Advanced Patterns

### Scroll-driven camera path

Camera follows a defined path as the user scrolls — the foundation of immersive scroll-driven 3D experiences.

```tsx
"use client";

import { useThree, useFrame } from "@react-three/fiber";
import { useRef, useEffect } from "react";
import * as THREE from "three";

const cameraPath = new THREE.CatmullRomCurve3([
  new THREE.Vector3(0, 2, 10),
  new THREE.Vector3(5, 3, 5),
  new THREE.Vector3(3, 1, 0),
  new THREE.Vector3(0, 0.5, -3),
]);

export function ScrollCameraPath({
  scrollProgress,
}: {
  scrollProgress: React.MutableRefObject<number>;
}) {
  const { camera } = useThree();
  const lookTarget = new THREE.Vector3(0, 0, 0);

  useFrame(() => {
    const t = scrollProgress.current;
    const pos = cameraPath.getPointAt(Math.min(t, 1));
    camera.position.lerp(pos, 0.1);
    camera.lookAt(lookTarget);
  });

  return null;
}
```

### Refraction/glass material

Transparent glass-like material with refraction — a premium product visualization technique.

```tsx
"use client";

import { MeshTransmissionMaterial } from "@react-three/drei";

export function GlassSphere() {
  return (
    <mesh>
      <sphereGeometry args={[1, 64, 64]} />
      <MeshTransmissionMaterial
        backside
        samples={16}
        thickness={0.2}
        chromaticAberration={0.06}
        anisotropy={0.1}
        distortion={0.3}
        distortionScale={0.3}
        temporalDistortion={0.5}
        ior={1.5}
        color="#ffffff"
      />
    </mesh>
  );
}
```

### Mouse-reactive 3D scene

Scene elements respond to cursor position — creates interactivity without full controls.

```tsx
"use client";

import { useFrame, useThree } from "@react-three/fiber";
import { useRef } from "react";
import * as THREE from "three";

export function MouseReactiveMesh() {
  const meshRef = useRef<THREE.Mesh>(null);
  const { pointer } = useThree();

  useFrame((_, delta) => {
    if (!meshRef.current) return;
    // Rotate toward cursor position
    meshRef.current.rotation.x = THREE.MathUtils.lerp(
      meshRef.current.rotation.x,
      pointer.y * 0.5,
      delta * 3
    );
    meshRef.current.rotation.y = THREE.MathUtils.lerp(
      meshRef.current.rotation.y,
      pointer.x * 0.5,
      delta * 3
    );
  });

  return (
    <mesh ref={meshRef}>
      <torusKnotGeometry args={[1, 0.3, 128, 32]} />
      <meshStandardMaterial color="#6366f1" roughness={0.1} metalness={0.8} />
    </mesh>
  );
}
```

### Noise-based vertex displacement shader

A shader that deforms geometry with simplex noise — creates organic, living surfaces.

```tsx
const vertexShader = `
  uniform float uTime;
  uniform float uAmplitude;
  varying vec2 vUv;
  varying float vDisplacement;

  // Simplex noise function (include your noise glsl here)
  float snoise(vec3 v) {
    // ... simplex noise implementation
    return sin(v.x * 2.0 + uTime) * sin(v.y * 2.0 + uTime * 0.7) * sin(v.z * 2.0 + uTime * 1.3);
  }

  void main() {
    vUv = uv;
    float displacement = snoise(position * 1.5 + uTime * 0.3) * uAmplitude;
    vDisplacement = displacement;
    vec3 newPosition = position + normal * displacement;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
  }
`;

const fragmentShader = `
  uniform vec3 uColorA;
  uniform vec3 uColorB;
  varying float vDisplacement;

  void main() {
    float t = (vDisplacement + 0.5) * 0.5;
    vec3 color = mix(uColorA, uColorB, t);
    gl_FragColor = vec4(color, 1.0);
  }
`;
```

### Performance: adaptive quality

Detect device capability and reduce quality accordingly — critical for mobile.

```tsx
"use client";

import { useThree, useFrame } from "@react-three/fiber";
import { useRef, useEffect, useState } from "react";
import { AdaptiveDpr, PerformanceMonitor } from "@react-three/drei";

export function AdaptiveScene({ children }: { children: React.ReactNode }) {
  const [dpr, setDpr] = useState(1.5);

  return (
    <Canvas dpr={dpr}>
      <PerformanceMonitor
        onIncline={() => setDpr(Math.min(2, dpr + 0.25))}
        onDecline={() => setDpr(Math.max(0.5, dpr - 0.25))}
      />
      <AdaptiveDpr pixelated />
      {children}
    </Canvas>
  );
}
```

## Composes With

- `performance` -- WebGL performance budgets, device capability detection, bundle size monitoring
- `animation` -- coordinating 3D scene transitions with 2D Motion (Framer Motion) animations
- `landing-patterns` -- 3D hero scenes for Awwwards-level marketing pages
- `responsive-design` -- adjusting 3D complexity, DPR, and effects by viewport/device
- `visual-design` -- color systems and design tokens shared between 3D materials and UI
- `creative-scrolling` -- scroll-driven camera paths and 3D scene scrubbing
- `cursor-effects` -- mouse-reactive 3D elements and cursor-following lights
- `sound-design` -- spatial audio tied to 3D object positions
