"use client";

import { useState, useEffect, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import MainLayout from "@/components/layout/MainLayout";
import PhotoGrid from "@/components/photos/PhotoGrid";
import DateSection from "@/components/photos/DateSection";
import Lightbox from "@/components/photos/Lightbox";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { useGallery } from "@/store/GalleryStore";
import { API_ENDPOINTS, API_BASE_URL } from "@/config/api";
import Image from "next/image";
import { Trash2, Edit2, ArrowLeft } from "lucide-react";

export default function PersonPhotosPage() {
  const router = useRouter();
  const params = useParams();
  const faceId = params.id;
  const { currentUser } = useSession();
  const { favorites, toggleFavorite, setUser, syncFavorites } = useGallery();

  const [personName, setPersonName] = useState("");
  const [photoCount, setPhotoCount] = useState(0);
  const [photosByDate, setPhotosByDate] = useState([]);
  const [selectedPhotos, setSelectedPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [isEditingName, setIsEditingName] = useState(false);
  const [editedName, setEditedName] = useState("");

  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxPhotos, setLightboxPhotos] = useState([]);
  const [lightboxStartIndex, setLightboxStartIndex] = useState(0);

  // Fetch person details and photos
  const fetchPersonData = useCallback(async () => {
    if (!currentUser || !faceId) return;

    try {
      setLoading(true);
      setError("");

      // Fetch person name and count
      const nameResponse = await fetch(
        API_ENDPOINTS.getFaceName(currentUser, faceId)
      );
      if (nameResponse.ok) {
        const [name, count] = await nameResponse.json();
        setPersonName(name);
        setPhotoCount(count);
      }

      // Fetch person's photos
      const photosResponse = await fetch(
        API_ENDPOINTS.getFaceAssets(currentUser, faceId)
      );

      if (!photosResponse.ok) {
        throw new Error(`HTTP error! status: ${photosResponse.status}`);
      }

      const data = await photosResponse.json();

      // Transform API response
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
      console.error("Error fetching person data:", error);
      setError("Failed to load photos. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [currentUser, faceId]);

  // Sync user and load data
  useEffect(() => {
    if (currentUser) {
      setUser(currentUser);
      syncFavorites();
      fetchPersonData();
    }
  }, [currentUser, setUser, syncFavorites, fetchPersonData]);

  const handleSelectPhoto = (photoId) => {
    setSelectedPhotos((prev) =>
      prev.includes(photoId)
        ? prev.filter((id) => id !== photoId)
        : [...prev, photoId]
    );
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

      // Refresh the person's photos
      await fetchPersonData();
      setSelectedPhotos([]);
    } catch (error) {
      console.error("Error deleting assets:", error);
      alert("Failed to delete assets. Please try again.");
    }
  };

  const handleRenameFace = async () => {
    if (!currentUser || !editedName.trim()) {
      setIsEditingName(false);
      setEditedName(personName);
      return;
    }

    try {
      const response = await fetch(
        API_ENDPOINTS.renameFace(currentUser, faceId, editedName.trim()),
        {
          method: "GET",
        }
      );

      if (!response.ok) {
        throw new Error("Failed to rename face");
      }

      const result = await response.json();
      if (result === "Face renamed successfully") {
        setPersonName(editedName.trim());
        setIsEditingName(false);
      } else {
        throw new Error(result);
      }
    } catch (error) {
      console.error("Error renaming face:", error);
      alert("Failed to rename face. Please try again.");
      setEditedName(personName);
      setIsEditingName(false);
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
          {/* Person Header */}
          <div className="flex items-center gap-4">
            <button
              onClick={() => router.back()}
              className="p-2 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
              aria-label="Go back"
            >
              <ArrowLeft className="w-6 h-6 text-gray-600 dark:text-gray-300" />
            </button>
            <div className="w-24 h-24 rounded-full overflow-hidden ring-2 ring-gray-200 dark:ring-gray-700">
              <Image
                src={`${API_BASE_URL}/api/face/image/${currentUser}/${faceId}`}
                alt={personName}
                width={96}
                height={96}
                className="w-full h-full object-cover"
                unoptimized
              />
            </div>
            <div className="flex-1">
              {isEditingName ? (
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={editedName}
                    onChange={(e) => setEditedName(e.target.value)}
                    className="text-3xl font-bold text-gray-800 dark:text-gray-100 
                      bg-transparent border-b-2 border-blue-500 outline-none"
                    autoFocus
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        handleRenameFace();
                      } else if (e.key === "Escape") {
                        setIsEditingName(false);
                        setEditedName(personName);
                      }
                    }}
                  />
                  <button
                    onClick={handleRenameFace}
                    className="px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600"
                  >
                    Save
                  </button>
                  <button
                    onClick={() => {
                      setIsEditingName(false);
                      setEditedName(personName);
                    }}
                    className="px-3 py-1 text-sm bg-gray-500 text-white rounded hover:bg-gray-600"
                  >
                    Cancel
                  </button>
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
                    {personName || "Loading..."}
                  </h1>
                  <button
                    onClick={() => {
                      setEditedName(personName);
                      setIsEditingName(true);
                    }}
                    className="p-1 text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
                    title="Rename person"
                  >
                    <Edit2 className="w-5 h-5" />
                  </button>
                </div>
              )}
              <p className="text-gray-600 dark:text-gray-400 mt-1">
                {photoCount} {photoCount === 1 ? "photo" : "photos"}
              </p>
            </div>
          </div>

          {/* Action Buttons for Selected Photos */}
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
                Loading photos...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={fetchPersonData}
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

              {/* No Photos Message */}
              {photosByDate.length === 0 && (
                <div className="text-center py-12">
                  <p className="text-gray-500 dark:text-gray-400">
                    No photos found for this person
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
        />
      </MainLayout>
    </ProtectedRoute>
  );
}
