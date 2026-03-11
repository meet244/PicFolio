"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { API_ENDPOINTS } from "@/config/api";

const STORAGE_KEYS = {
  favorites: "favorites",
  albums: "albums",
};

const GalleryContext = createContext(null);

export function GalleryProvider({ children }) {
  const [favorites, setFavorites] = useState([]);
  const [albums, setAlbums] = useState([]);
  const [currentUser, setCurrentUser] = useState(null);

  // Initial load from localStorage
  useEffect(() => {
    try {
      const fav = JSON.parse(
        localStorage.getItem(STORAGE_KEYS.favorites) || "[]"
      );
      const alb = JSON.parse(localStorage.getItem(STORAGE_KEYS.albums) || "[]");
      setFavorites(Array.isArray(fav) ? fav : []);
      setAlbums(Array.isArray(alb) ? alb : []);
    } catch {
      setFavorites([]);
      setAlbums([]);
    }
  }, []);

  // Persist whenever these change
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.favorites, JSON.stringify(favorites));
    } catch {}
  }, [favorites]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.albums, JSON.stringify(albums));
    } catch {}
  }, [albums]);

  // Set current user
  const setUser = useCallback((username) => {
    setCurrentUser(username);
  }, []);

  // Toggle favorite with backend sync
  const toggleFavorite = useCallback(
    async (photoId) => {
      if (!currentUser) {
        console.error("No user logged in");
        return;
      }

      // Optimistic update
      setFavorites((prev) =>
        prev.includes(photoId)
          ? prev.filter((id) => id !== photoId)
          : [...prev, photoId]
      );

      try {
        const response = await fetch(
          API_ENDPOINTS.toggleLike(currentUser, photoId),
          {
            method: "POST",
          }
        );

        if (!response.ok) {
          throw new Error("Failed to toggle favorite");
        }
      } catch (error) {
        console.error("Error toggling favorite:", error);
        // Revert optimistic update on error
        setFavorites((prev) =>
          prev.includes(photoId)
            ? prev.filter((id) => id !== photoId)
            : [...prev, photoId]
        );
      }
    },
    [currentUser]
  );

  // Check if photo is liked on backend
  const checkLiked = useCallback(
    async (photoId) => {
      if (!currentUser) return false;

      try {
        const response = await fetch(
          API_ENDPOINTS.checkLiked(currentUser, photoId)
        );
        if (!response.ok) return false;
        const isLiked = await response.json();
        return isLiked === true;
      } catch (error) {
        console.error("Error checking liked status:", error);
        return false;
      }
    },
    [currentUser]
  );

  // Sync favorites from backend
  const syncFavorites = useCallback(async () => {
    if (!currentUser) return;

    try {
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("query", "favourite");
      formData.append("type", "buttons");

      const response = await fetch(API_ENDPOINTS.searchAssets(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error("Failed to fetch favorites");
      }

      const data = await response.json();

      // Extract all photo IDs from the response
      const favoriteIds = data.flatMap(([date, photos]) =>
        photos.map(([id]) => id.toString())
      );

      setFavorites(favoriteIds);
    } catch (error) {
      console.error("Error syncing favorites:", error);
    }
  }, [currentUser]);

  const addFavorites = useCallback((photoIds) => {
    setFavorites((prev) => Array.from(new Set([...prev, ...photoIds])));
  }, []);

  const clearFavorites = useCallback(() => setFavorites([]), []);

  const addAlbum = useCallback((album) => {
    setAlbums((prev) => [...prev, album]);
  }, []);

  const deleteAlbum = useCallback((albumId) => {
    setAlbums((prev) => prev.filter((a) => a.id !== albumId));
  }, []);

  const updateAlbum = useCallback((albumId, updater) => {
    setAlbums((prev) =>
      prev.map((a) => (a.id === albumId ? { ...a, ...updater(a) } : a))
    );
  }, []);

  const getAlbumById = useCallback(
    (albumId) => albums.find((a) => a.id === albumId) || null,
    [albums]
  );

  const value = useMemo(
    () => ({
      // state
      favorites,
      albums,
      currentUser,
      // user management
      setUser,
      // favorites api
      toggleFavorite,
      checkLiked,
      syncFavorites,
      addFavorites,
      clearFavorites,
      // albums api
      addAlbum,
      deleteAlbum,
      updateAlbum,
      getAlbumById,
    }),
    [
      favorites,
      albums,
      currentUser,
      setUser,
      toggleFavorite,
      checkLiked,
      syncFavorites,
      addFavorites,
      clearFavorites,
      addAlbum,
      deleteAlbum,
      updateAlbum,
      getAlbumById,
    ]
  );

  return (
    <GalleryContext.Provider value={value}>{children}</GalleryContext.Provider>
  );
}

export function useGallery() {
  const ctx = useContext(GalleryContext);
  if (!ctx) {
    throw new Error("useGallery must be used within a GalleryProvider");
  }
  return ctx;
}
