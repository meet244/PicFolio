"use client";
import { useState, useEffect, useCallback } from "react";
import MainLayout from "@/components/layout/MainLayout";
import PhotoGrid from "@/components/photos/PhotoGrid";
import PhotoToolbar from "@/components/photos/PhotoToolbar";
import DateSection from "@/components/photos/DateSection";
import { useGallery } from "@/store/GalleryStore";
import Lightbox from "@/components/photos/Lightbox";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { API_ENDPOINTS, API_BASE_URL } from "@/config/api";

export default function FavoritesPage() {
  const { currentUser } = useSession();
  const [selectedPhotos, setSelectedPhotos] = useState([]);
  const [searchQuery, setSearchQuery] = useState("");
  const { favorites, toggleFavorite, setUser } = useGallery();
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxPhotos, setLightboxPhotos] = useState([]);
  const [lightboxStartIndex, setLightboxStartIndex] = useState(0);

  // Real data from API
  const [photosByDate, setPhotosByDate] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Fetch favorite photos from API
  const fetchFavorites = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      setError("");

      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("query", "favourite");
      formData.append("type", "buttons");

      const response = await fetch(API_ENDPOINTS.searchAssets(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      // Transform API response to match our component structure
      const transformedData = data.map(([date, ids]) => ({
        date: date,
        photos: ids.map(([id, _, duration]) => ({
          id: id.toString(),
          url: API_ENDPOINTS.getPreview(currentUser, id),
          title: `Photo ${id}`,
          isVideo: duration !== null && duration !== undefined,
          duration: duration || null,
        })),
      }));

      setPhotosByDate(transformedData);
    } catch (error) {
      console.error("Error fetching favorites:", error);
      setError("Failed to load favorite photos. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  // Sync user and load favorites when currentUser changes
  useEffect(() => {
    if (currentUser) {
      setUser(currentUser);
      fetchFavorites();
    }
  }, [currentUser, setUser, fetchFavorites]);

  const handleSelectPhoto = (photoId) => {
    setSelectedPhotos((prev) =>
      prev.includes(photoId)
        ? prev.filter((id) => id !== photoId)
        : [...prev, photoId]
    );
  };

  const handleToggleFavorite = async (photoId) => {
    await toggleFavorite(photoId);
    // Refresh the favorites list after toggling
    fetchFavorites();
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

      // Refresh the favorites list
      await fetchFavorites();
      setSelectedPhotos([]);
    } catch (error) {
      console.error("Error deleting assets:", error);
      alert("Failed to delete assets. Please try again.");
    }
  };

  const handleDeleteSinglePhoto = async (photoId) => {
    if (!currentUser) return;

    if (
      !window.confirm(
        `Move this photo to bin? It will be permanently deleted after 90 days.`
      )
    ) {
      return;
    }

    try {
      const response = await fetch(
        API_ENDPOINTS.deleteAssets(currentUser, photoId),
        {
          method: "DELETE",
        }
      );

      if (!response.ok) {
        throw new Error("Failed to delete asset");
      }

      // Close lightbox and refresh
      setLightboxOpen(false);
      await fetchFavorites();
    } catch (error) {
      console.error("Error deleting asset:", error);
      alert("Failed to delete photo. Please try again.");
    }
  };

  // Filter photos based on search query
  const filteredPhotosByDate = photosByDate
    .map((group) => ({
      ...group,
      photos: group.photos.filter((photo) =>
        photo.title.toLowerCase().includes(searchQuery.toLowerCase())
      ),
    }))
    .filter((group) => group.photos.length > 0);

  const openLightbox = (photo, photos) => {
    // Create high-definition versions for lightbox
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
              Favorites
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Browse your favorite photos
            </p>
          </div>

          <PhotoToolbar
            selectedCount={selectedPhotos.length}
            onClearSelection={() => setSelectedPhotos([])}
            searchQuery={searchQuery}
            onSearchChange={setSearchQuery}
            onDelete={handleDeletePhotos}
            currentUser={currentUser}
          />

          {/* Loading State */}
          {loading && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-gray-400">
                Loading favorites...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={fetchFavorites}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          {/* Photos Grid */}
          {!loading && !error && (
            <div className="space-y-8">
              {filteredPhotosByDate.map((group) => (
                <DateSection key={group.date} date={group.date}>
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

              {/* No Results Message */}
              {filteredPhotosByDate.length === 0 && (
                <div className="text-center py-12">
                  <p className="text-gray-500 dark:text-gray-400">
                    {searchQuery
                      ? `No favorites found matching "${searchQuery}"`
                      : "No favorite photos yet. Start adding some from your photos!"}
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
          currentUser={currentUser}
          onDelete={handleDeleteSinglePhoto}
        />
      </MainLayout>
    </ProtectedRoute>
  );
}
