"use client";

import { GalleryProvider } from "@/store/GalleryStore";
import { SessionProvider } from "./SessionProvider";

export default function Providers({ children }) {
  return (
    <SessionProvider>
      <GalleryProvider>{children}</GalleryProvider>
    </SessionProvider>
  );
}
