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
import { RotateCcw, Trash2 } from "lucide-react";

export default function BinPage() {
  const { currentUser } = useSession();
  const { favorites, toggleFavorite, setUser } = useGallery();
  const [photosByDate, setPhotosByDate] = useState([]);
  const [selectedPhotos, setSelectedPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxPhotos, setLightboxPhotos] = useState([]);
  const [lightboxStartIndex, setLightboxStartIndex] = useState(0);

  // Sync user when currentUser changes
  useEffect(() => {
    if (currentUser) {
      setUser(currentUser);
    }
  }, [currentUser, setUser]);

  // Fetch deleted photos from API
  const fetchDeletedPhotos = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      setError("");

      const formData = new FormData();
      formData.append("username", currentUser);

      const response = await fetch(API_ENDPOINTS.getDeletedAssets(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      // Transform API response: [["days_until_deletion", [[id], [id, null, duration], ...]], ...]
      const transformedData = data.map(([daysRemaining, assets]) => ({
        date: `${daysRemaining} days until permanent deletion`,
        photos: assets.map(([id, _, duration]) => ({
          id: id.toString(),
          url: API_ENDPOINTS.getPreview(currentUser, id),
          title: `Photo ${id}`,
          isVideo: duration !== null && duration !== undefined,
          duration: duration || null,
        })),
      }));

      setPhotosByDate(transformedData);
    } catch (error) {
      console.error("Error fetching deleted photos:", error);
      setError("Failed to load deleted photos. Please try again.");
      setPhotosByDate([]);
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  // Load photos on component mount
  useEffect(() => {
    fetchDeletedPhotos();
  }, [fetchDeletedPhotos]);

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

  const handleRestore = async () => {
    if (!currentUser || selectedPhotos.length === 0) return;

    if (!window.confirm(`Restore ${selectedPhotos.length} item(s)?`)) {
      return;
    }

    try {
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("ids", selectedPhotos.join(","));

      const response = await fetch(API_ENDPOINTS.restoreAssets(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error("Failed to restore assets");
      }

      const result = await response.json();

      // Refresh the list
      await fetchDeletedPhotos();
      setSelectedPhotos([]);
    } catch (error) {
      console.error("Error restoring assets:", error);
      alert("Failed to restore assets. Please try again.");
    }
  };

  const handlePermanentDelete = async () => {
    if (!currentUser || selectedPhotos.length === 0) return;

    if (
      !window.confirm(
        `Permanently delete ${selectedPhotos.length} item(s)? This action cannot be undone!`
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

      // Refresh the list
      await fetchDeletedPhotos();
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
          <div>
            <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
              Bin
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Items in bin will be permanently deleted after 90 days
            </p>
          </div>

          {/* Toolbar */}
          {selectedPhotos.length > 0 && (
            <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow-md">
              <div className="flex flex-wrap items-center gap-3">
                <button
                  onClick={() => setSelectedPhotos([])}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700
                    hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300"
                >
                  Clear Selection ({selectedPhotos.length})
                </button>
                <button
                  onClick={handleRestore}
                  className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600 
                    flex items-center gap-2"
                >
                  <RotateCcw className="w-5 h-5" />
                  <span>Restore</span>
                </button>
                <button
                  onClick={handlePermanentDelete}
                  className="px-4 py-2 rounded-lg bg-red-500 text-white hover:bg-red-600 
                    flex items-center gap-2"
                >
                  <Trash2 className="w-5 h-5" />
                  <span>Delete Permanently</span>
                </button>
              </div>
            </div>
          )}

          {/* Loading State */}
          {loading && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-gray-400">
                Loading deleted items...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && !loading && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={fetchDeletedPhotos}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          {/* Photos Grid */}
          {!loading && !error && (
            <div className="space-y-8">
              {photosByDate.map((group) => {
                const datePhotoIds = group.photos.map((photo) => photo.id);
                const dateSelectionCount = datePhotoIds.filter((id) =>
                  selectedPhotos.includes(id)
                ).length;

                return (
                  <DateSection
                    key={group.date}
                    date={group.date}
                    onSelectAll={() => handleSelectAllInDate(group.photos)}
                    isAllSelected={datePhotoIds.every((id) =>
                      selectedPhotos.includes(id)
                    )}
                    selectionCount={dateSelectionCount}
                  >
                    <PhotoGrid
                      photos={group.photos}
                      selectedPhotos={selectedPhotos}
                      onSelectPhoto={handleSelectPhoto}
                      favorites={favorites}
                      onToggleFavorite={toggleFavorite}
                      onOpenPhoto={(photo) => openLightbox(photo, group.photos)}
                    />
                  </DateSection>
                );
              })}

              {/* No Photos Message */}
              {photosByDate.length === 0 && (
                <div className="text-center py-12">
                  <p className="text-gray-500 dark:text-gray-400">
                    Bin is empty
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
          onToggleFavorite={toggleFavorite}
          currentUser={currentUser}
        />
      </MainLayout>
    </ProtectedRoute>
  );
}

