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

## Composes With
- `api-routes` — upload route handlers
- `prisma` — file metadata storage
- `security` — auth checks in upload middleware
