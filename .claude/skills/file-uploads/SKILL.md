---
name: file-uploads
description: >
  File uploads with Uploadthing — file router API, presigned URLs for S3/R2, image optimization, file validation
allowed-tools: Read, Grep, Glob
---

# File Uploads

## Purpose
File upload patterns for Next.js 15 with Uploadthing. Covers file router API, presigned URL
patterns for S3/R2, image optimization pipeline, and file validation. The ONE skill for upload decisions.

## When to Use
- Adding file or image upload to a Next.js 15 app
- Setting up Uploadthing file router
- Implementing presigned URL uploads for S3/R2
- Adding file type and size validation
- Building image optimization pipelines

## When NOT to Use
- Form handling without uploads → `react-forms`
- API route design → `api-routes`
- Database storage for file metadata → `prisma`

## Pattern

### Uploadthing file router
```tsx
// src/app/api/uploadthing/core.ts
import { createUploadthing, type FileRouter } from "uploadthing/next";
import { auth } from "@/lib/auth";

const f = createUploadthing();

export const ourFileRouter = {
  imageUploader: f({ image: { maxFileSize: "4MB", maxFileCount: 4 } })
    .middleware(async () => {
      const session = await auth();
      if (!session) throw new Error("Unauthorized");
      return { userId: session.user.id };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      await db.file.create({
        data: { url: file.url, userId: metadata.userId },
      });
      return { url: file.url };
    }),

  documentUploader: f({
    pdf: { maxFileSize: "16MB" },
    "application/msword": { maxFileSize: "16MB" },
  })
    .middleware(async () => {
      const session = await auth();
      if (!session) throw new Error("Unauthorized");
      return { userId: session.user.id };
    })
    .onUploadComplete(async ({ metadata, file }) => {
      return { url: file.url };
    }),
} satisfies FileRouter;

export type OurFileRouter = typeof ourFileRouter;
```

### Uploadthing route handler
```tsx
// src/app/api/uploadthing/route.ts
import { createRouteHandler } from "uploadthing/next";
import { ourFileRouter } from "./core";

export const { GET, POST } = createRouteHandler({ router: ourFileRouter });
```

### Client upload component
```tsx
"use client";
import { UploadButton, UploadDropzone } from "@uploadthing/react";
import type { OurFileRouter } from "@/app/api/uploadthing/core";

export function ImageUpload({ onUploadComplete }: {
  onUploadComplete: (url: string) => void;
}) {
  return (
    <UploadDropzone<OurFileRouter, "imageUploader">
      endpoint="imageUploader"
      onClientUploadComplete={(res) => {
        if (res?.[0]) onUploadComplete(res[0].url);
      }}
      onUploadError={(error) => {
        console.error("Upload error:", error.message);
      }}
    />
  );
}
```

### Presigned URL pattern (S3/R2)
```tsx
// src/actions/getUploadUrl.ts
"use server";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { auth } from "@/lib/auth";

const s3 = new S3Client({ region: process.env.AWS_REGION });

export async function getUploadUrl(filename: string, contentType: string) {
  const session = await auth();
  if (!session) return { error: "Unauthorized" };

  const key = `uploads/${session.user.id}/${crypto.randomUUID()}-${filename}`;
  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: key,
    ContentType: contentType,
  });

  const url = await getSignedUrl(s3, command, { expiresIn: 600 });
  return { url, key };
}
```

## Anti-pattern

```tsx
// WRONG: storing files in public/ (fills disk, no CDN, no auth)
import fs from "fs";
export async function POST(req: Request) {
  const file = await req.blob();
  fs.writeFileSync(`public/uploads/${filename}`, Buffer.from(await file.arrayBuffer()));
}

// WRONG: storing base64 in database (bloats DB, slow queries)
await db.user.update({
  data: { avatar: base64EncodedImage }, // 1MB+ per row!
});

// CORRECT: store URL reference, files in object storage
await db.user.update({
  data: { avatarUrl: uploadedFile.url },
});
```

## Common Mistakes
- Storing files in `public/` directory — use object storage (S3, R2, Uploadthing)
- Storing base64 in database — store URL references only
- Missing file type validation — always validate on server, not just client
- No file size limits — set explicit `maxFileSize` per upload type
- Missing auth in upload middleware — always verify user before accepting files
- Not cleaning up orphaned files — delete from storage when DB record is removed
- No malware/virus scanning — consider ClamAV or cloud-based scanning for production uploads

## Checklist
- [ ] File router validates auth in middleware
- [ ] File type and size limits set per endpoint
- [ ] Files stored in object storage, not filesystem or DB
- [ ] Client component handles upload errors gracefully
- [ ] Orphaned file cleanup strategy documented
- [ ] File content scanning considered for production
- [ ] `UPLOADTHING_TOKEN` in `.env.local` (never committed)

### Premium Upload UI Patterns

#### Animated dropzone with drag feedback
```tsx
"use client";
import { motion, AnimatePresence } from "motion/react";
import { Upload, File, CheckCircle, AlertCircle } from "lucide-react";
import { useState, useCallback } from "react";

type UploadState = "idle" | "dragover" | "uploading" | "success" | "error";

export function AnimatedDropzone({ onUpload }: { onUpload: (files: File[]) => Promise<void> }) {
  const [state, setState] = useState<UploadState>("idle");
  const [progress, setProgress] = useState(0);

  const handleDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault();
    setState("uploading");
    const files = Array.from(e.dataTransfer.files);
    try {
      // Simulate progress — replace with real upload tracking
      const interval = setInterval(() => setProgress((p) => Math.min(p + 12, 95)), 200);
      await onUpload(files);
      clearInterval(interval);
      setProgress(100);
      setState("success");
      setTimeout(() => { setState("idle"); setProgress(0); }, 2000);
    } catch {
      setState("error");
      setTimeout(() => { setState("idle"); setProgress(0); }, 3000);
    }
  }, [onUpload]);

  return (
    <motion.div
      onDragOver={(e) => { e.preventDefault(); setState("dragover"); }}
      onDragLeave={() => setState("idle")}
      onDrop={handleDrop}
      animate={{
        borderColor: state === "dragover" ? "var(--color-primary)" : "var(--color-border)",
        backgroundColor: state === "dragover" ? "var(--color-primary-5)" : "transparent",
        scale: state === "dragover" ? 1.01 : 1,
      }}
      transition={{ type: "spring", stiffness: 300, damping: 25 }}
      className="relative flex flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed p-12"
    >
      <AnimatePresence mode="wait">
        {state === "idle" && (
          <motion.div key="idle" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex flex-col items-center gap-2">
            <motion.div animate={{ y: [0, -4, 0] }} transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }}>
              <Upload className="h-8 w-8 text-muted-foreground" />
            </motion.div>
            <p className="text-sm text-muted-foreground">Drag files here or click to browse</p>
          </motion.div>
        )}
        {state === "dragover" && (
          <motion.div key="dragover" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }} className="flex flex-col items-center gap-2">
            <File className="h-8 w-8 text-primary" />
            <p className="text-sm font-medium text-primary">Drop to upload</p>
          </motion.div>
        )}
        {state === "uploading" && (
          <motion.div key="uploading" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex w-full max-w-xs flex-col items-center gap-3">
            <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
              <motion.div className="h-full rounded-full bg-primary" animate={{ width: `${progress}%` }} transition={{ ease: "easeOut" }} />
            </div>
            <p className="text-sm text-muted-foreground">{progress}% uploaded</p>
          </motion.div>
        )}
        {state === "success" && (
          <motion.div key="success" initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }} className="flex flex-col items-center gap-2">
            <motion.div initial={{ scale: 0 }} animate={{ scale: [0, 1.2, 1] }} transition={{ duration: 0.4, ease: "easeOut" }}>
              <CheckCircle className="h-8 w-8 text-green-500" />
            </motion.div>
            <p className="text-sm font-medium text-green-600">Upload complete!</p>
          </motion.div>
        )}
        {state === "error" && (
          <motion.div key="error" initial={{ opacity: 0 }} animate={{ opacity: 1, x: [0, -4, 4, -4, 0] }} exit={{ opacity: 0 }} className="flex flex-col items-center gap-2">
            <AlertCircle className="h-8 w-8 text-destructive" />
            <p className="text-sm font-medium text-destructive">Upload failed — try again</p>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
```

#### File preview card with entrance animation
```tsx
"use client";
import { motion } from "motion/react";
import { X, FileText, Image as ImageIcon } from "lucide-react";

export function FilePreview({ file, index, onRemove }: {
  file: { name: string; size: number; type: string; url?: string };
  index: number;
  onRemove: () => void;
}) {
  const isImage = file.type.startsWith("image/");

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9, y: 8 }}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.9, x: -20 }}
      transition={{ type: "spring", stiffness: 300, damping: 25, delay: index * 0.05 }}
      className="group relative flex items-center gap-3 rounded-xl border bg-card p-3"
    >
      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-muted">
        {isImage && file.url ? (
          <img src={file.url} alt="" className="h-10 w-10 rounded-lg object-cover" />
        ) : (
          <FileText className="h-5 w-5 text-muted-foreground" />
        )}
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">{file.name}</p>
        <p className="text-xs text-muted-foreground">{(file.size / 1024).toFixed(0)} KB</p>
      </div>
      <motion.button
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        onClick={onRemove}
        className="rounded-full p-1 opacity-0 transition-opacity group-hover:opacity-100"
      >
        <X className="h-4 w-4 text-muted-foreground" />
      </motion.button>
    </motion.div>
  );
}
```

#### Circular upload progress ring
```tsx
"use client";
import { motion } from "motion/react";

export function UploadRing({ progress, size = 48 }: { progress: number; size?: number }) {
  const strokeWidth = 3;
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="var(--color-muted)" strokeWidth={strokeWidth} />
        <motion.circle
          cx={size / 2} cy={size / 2} r={radius}
          fill="none" stroke="var(--color-primary)" strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={circumference}
          animate={{ strokeDashoffset: circumference * (1 - progress / 100) }}
          transition={{ ease: "easeOut", duration: 0.3 }}
        />
      </svg>
      <span className="absolute inset-0 flex items-center justify-center text-xs font-medium">
        {progress}%
      </span>
    </div>
  );
}
```

## Composes With
- `api-routes` — upload route handlers
- `prisma` — file metadata storage
- `security` — auth checks in upload middleware
- `animation` — dropzone feedback, progress, file preview transitions
- `visual-design` — upload zone styling, color feedback states
