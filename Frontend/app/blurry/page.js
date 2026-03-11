"use client";

import { useState, useEffect, useCallback } from "react";
import MainLayout from "@/components/layout/MainLayout";
import PhotoGrid from "@/components/photos/PhotoGrid";
import DateSection from "@/components/photos/DateSection";
import Lightbox from "@/components/photos/Lightbox";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { useGallery } from "@/store/GalleryStore";
import { API_ENDPOINTS, API_BASE_URL } from "@/config/api";
import { Trash2 } from "lucide-react";

export default function BlurryPage() {
  const { currentUser } = useSession();
  const { favorites, toggleFavorite, setUser, syncFavorites } = useGallery();
  
  const [photosByDate, setPhotosByDate] = useState([]);
  const [selectedPhotos, setSelectedPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxPhotos, setLightboxPhotos] = useState([]);
  const [lightboxStartIndex, setLightboxStartIndex] = useState(0);

  // Fetch blurry images from API
  const fetchBlurryImages = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      setError("");

      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("query", "blurry");
      formData.append("type", "buttons");

      const response = await fetch(API_ENDPOINTS.searchAssets(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      // Response format: [[date, [[id], [id], ...]], ...]
      // Transform to match our photo grid format
      const photosByDateArray = data.map(([date, idsArray]) => ({
        date,
        photos: idsArray.map(([id, duration]) => ({
          id: id.toString(),
          url: API_ENDPOINTS.getPreview(currentUser, id),
          title: `Photo ${id}`,
          isVideo: duration !== null && duration !== undefined,
          duration: duration || null,
        })),
      }));

      setPhotosByDate(photosByDateArray);
    } catch (error) {
      console.error("Error fetching blurry images:", error);
      setError("Failed to load blurry images. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  // Sync user and load blurry images
  useEffect(() => {
    if (currentUser) {
      setUser(currentUser);
      syncFavorites();
      fetchBlurryImages();
    }
  }, [currentUser, setUser, syncFavorites, fetchBlurryImages]);

  const handleSelectPhoto = (photoId) => {
    setSelectedPhotos((prev) =>
      prev.includes(photoId)
        ? prev.filter((id) => id !== photoId)
        : [...prev, photoId]
    );
  };

  const handleSelectAllInDate = (datePhotos) => {
    const datePhotoIds = datePhotos.map((photo) => photo.id);
    const allSelected = datePhotoIds.every((id) => selectedPhotos.includes(id));

    if (allSelected) {
      setSelectedPhotos((prev) =>
        prev.filter((id) => !datePhotoIds.includes(id))
      );
    } else {
      setSelectedPhotos((prev) => [...new Set([...prev, ...datePhotoIds])]);
    }
  };

  const handleToggleFavorite = (photoId) => {
    toggleFavorite(photoId);
  };

  const handleDeletePhotos = async () => {
    if (!currentUser || selectedPhotos.length === 0) return;

    if (
      !window.confirm(
        `Move ${selectedPhotos.length} item(s) to bin? They will be permanently deleted after 90 days.`
      )
    ) {
      return;
    }

    try {
      const response = await fetch(
        API_ENDPOINTS.deleteAssets(currentUser, selectedPhotos.join(",")),
        {
          method: "DELETE",
        }
      );

      if (!response.ok) {
        throw new Error("Failed to delete assets");
      }

      const result = await response.json();

      // Refresh the blurry images list
      await fetchBlurryImages();
      setSelectedPhotos([]);
    } catch (error) {
      console.error("Error deleting assets:", error);
      alert("Failed to delete assets. Please try again.");
    }
  };

  const openLightbox = (photo, photos) => {
    const hdPhotos = photos.map((p) => ({
      ...p,
      url: API_ENDPOINTS.getPreview(currentUser, p.id),
    }));
    setLightboxPhotos(hdPhotos);
    const idx = photos.findIndex((p) => p.id === photo.id);
    setLightboxStartIndex(Math.max(0, idx));
    setLightboxOpen(true);
  };

  return (
    <ProtectedRoute>
      <MainLayout>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
              Blurry Images
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Photos that may be out of focus or blurry
            </p>
          </div>

          {/* Action Buttons */}
          {selectedPhotos.length > 0 && (
            <div className="flex gap-2 items-center justify-end">
              <button
                onClick={() => setSelectedPhotos([])}
                className="px-4 py-2 rounded-lg bg-gray-500 text-white hover:bg-gray-600 
                  flex items-center gap-2"
              >
                Clear Selection ({selectedPhotos.length})
              </button>
              <button
                onClick={handleDeletePhotos}
                className="px-4 py-2 rounded-lg bg-red-500 text-white hover:bg-red-600 
                  flex items-center gap-2"
              >
                <Trash2 className="w-4 h-4" />
                <span>Delete</span>
              </button>
            </div>
          )}

          {/* Loading State */}
          {loading && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-gray-400">
                Loading blurry images...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={fetchBlurryImages}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          {/* Photos Grid */}
          {!loading && !error && (
            <div className="space-y-8">
              {photosByDate.map((group) => (
                <DateSection 
                  key={group.date} 
                  date={group.date}
                  photoCount={group.photos.length}
                  selectedCount={group.photos.filter(p => selectedPhotos.includes(p.id)).length}
                  onSelectAll={() => handleSelectAllInDate(group.photos)}
                >
                  <PhotoGrid
                    photos={group.photos}
                    selectedPhotos={selectedPhotos}
                    onSelectPhoto={handleSelectPhoto}
                    favorites={favorites}
                    onToggleFavorite={handleToggleFavorite}
                    onOpenPhoto={(photo) => openLightbox(photo, group.photos)}
                  />
                </DateSection>
              ))}

              {/* No Blurry Images Message */}
              {photosByDate.length === 0 && (
                <div className="text-center py-12">
                  <p className="text-gray-500 dark:text-gray-400">
                    No blurry images detected. All your photos are sharp! 📸
                  </p>
                </div>
              )}
            </div>
          )}
        </div>

        <Lightbox
          isOpen={lightboxOpen}
          onClose={() => setLightboxOpen(false)}
          photos={lightboxPhotos}
          startIndex={lightboxStartIndex}
          favorites={favorites}
          onToggleFavorite={handleToggleFavorite}
        />
      </MainLayout>
    </ProtectedRoute>
  );
}

