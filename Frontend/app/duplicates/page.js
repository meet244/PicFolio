"use client";

import { useState, useEffect, useCallback, useMemo } from "react";
import MainLayout from "@/components/layout/MainLayout";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { useGallery } from "@/store/GalleryStore";
import { API_ENDPOINTS, API_BASE_URL } from "@/config/api";
import Image from "next/image";
import { Trash2, X, Star } from "lucide-react";
import Lightbox from "@/components/photos/Lightbox";

export default function DuplicatesPage() {
  const { currentUser } = useSession();
  const { favorites, toggleFavorite, setUser, syncFavorites } = useGallery();
  
  const [duplicateGroups, setDuplicateGroups] = useState([]);
  const [selectedPhotos, setSelectedPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxPhotos, setLightboxPhotos] = useState([]);
  const [lightboxStartIndex, setLightboxStartIndex] = useState(0);

  // Fetch duplicates from API
  const fetchDuplicates = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      setError("");

      const formData = new FormData();
      formData.append("username", currentUser);

      const response = await fetch(API_ENDPOINTS.getDuplicates(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        if (response.status === 404) {
          // No duplicates found
          setDuplicateGroups([]);
          return;
        }
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      // Response format: [[date, asset_id, asset_id2], ...]
      // Group by date
      const groupedByDate = {};
      
      data.forEach(([date, assetId1, assetId2]) => {
        if (!groupedByDate[date]) {
          groupedByDate[date] = [];
        }
        
        // Create a pair object
        const pair = {
          id: `${assetId1}-${assetId2}`,
          bestPhotoId: assetId1.toString(), // API returns best quality asset first
          photo1: {
            id: assetId1.toString(),
            url: API_ENDPOINTS.getPreview(currentUser, assetId1),
            title: `Photo ${assetId1}`,
            isVideo: false, // Default to false as duplicates API doesn't provide duration
            duration: null,
          },
          photo2: {
            id: assetId2.toString(),
            url: API_ENDPOINTS.getPreview(currentUser, assetId2),
            title: `Photo ${assetId2}`,
            isVideo: false, // Default to false as duplicates API doesn't provide duration
            duration: null,
          },
        };
        
        groupedByDate[date].push(pair);
      });

      // Convert to array format
      const duplicatesArray = Object.entries(groupedByDate).map(([date, pairs]) => ({
        date,
        pairs,
      }));

      // Sort by date (newest first)
      duplicatesArray.sort((a, b) => new Date(b.date) - new Date(a.date));

      setDuplicateGroups(duplicatesArray);
    } catch (error) {
      console.error("Error fetching duplicates:", error);
      setError("Failed to load duplicates. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  // Sync user and load duplicates
  useEffect(() => {
    if (currentUser) {
      setUser(currentUser);
      syncFavorites();
      fetchDuplicates();
    }
  }, [currentUser, setUser, syncFavorites, fetchDuplicates]);

  const handleSelectPhoto = (photoId) => {
    setSelectedPhotos((prev) =>
      prev.includes(photoId)
        ? prev.filter((id) => id !== photoId)
        : [...prev, photoId]
    );
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

      // Refresh the duplicates list
      await fetchDuplicates();
      setSelectedPhotos([]);
    } catch (error) {
      console.error("Error deleting assets:", error);
      alert("Failed to delete assets. Please try again.");
    }
  };

  const openLightbox = (photo, pairPhotos) => {
    const hdPhotos = pairPhotos.map((p) => ({
      ...p,
      url: API_ENDPOINTS.getPreview(currentUser, p.id),
    }));
    setLightboxPhotos(hdPhotos);
    const idx = pairPhotos.findIndex((p) => p.id === photo.id);
    setLightboxStartIndex(Math.max(0, idx));
    setLightboxOpen(true);
  };

  const handleToggleFavorite = (photoId) => {
    toggleFavorite(photoId);
  };

  const duplicatePhotoIds = useMemo(() => {
    const ids = [];
    duplicateGroups.forEach((group) => {
      group.pairs.forEach((pair) => {
        const duplicateId =
          pair.photo1.id === pair.bestPhotoId ? pair.photo2.id : pair.photo1.id;
        ids.push(duplicateId);
      });
    });

    return [...new Set(ids)];
  }, [duplicateGroups]);

  const handleToggleAllDuplicates = () => {
    const allSelected = duplicatePhotoIds.every((id) =>
      selectedPhotos.includes(id)
    );

    if (allSelected) {
      setSelectedPhotos((prev) =>
        prev.filter((id) => !duplicatePhotoIds.includes(id))
      );
    } else {
      setSelectedPhotos((prev) => [...new Set([...prev, ...duplicatePhotoIds])]);
    }
  };

  return (
    <ProtectedRoute>
      <MainLayout>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
              Duplicates
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Find and manage duplicate photos
            </p>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <button
              onClick={handleToggleAllDuplicates}
              disabled={duplicatePhotoIds.length === 0}
              className={`px-4 py-2 rounded-lg flex items-center gap-2 ${
                duplicatePhotoIds.length === 0
                  ? "bg-gray-200 text-gray-500 cursor-not-allowed dark:bg-gray-700"
                  : "bg-green-100 text-green-700 hover:bg-green-200 dark:bg-green-900/30 dark:text-green-300"
              }`}
            >
              <Star className="w-4 h-4" />
              {duplicatePhotoIds.every((id) => selectedPhotos.includes(id))
                ? "Deselect All Duplicates"
                : `Select All Duplicates (${duplicatePhotoIds.length})`}
            </button>

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
          </div>

          {/* Loading State */}
          {loading && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-gray-400">
                Loading duplicates...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={fetchDuplicates}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          {/* Duplicates Grid */}
          {!loading && !error && (
            <div className="space-y-8">
              {duplicateGroups.map((group) => (
                <div key={group.date}>
                  <h2 className="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-4">
                    {new Date(group.date).toLocaleDateString("en-US", {
                      year: "numeric",
                      month: "long",
                      day: "numeric",
                    })}
                  </h2>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {group.pairs.map((pair) => (
                      <div
                        key={pair.id}
                        className="grid grid-cols-1 gap-6 sm:grid-cols-2"
                      >
                        {[pair.photo1, pair.photo2].map((photo) => (
                          <div
                            key={photo.id}
                            className="relative group cursor-pointer"
                            onClick={() => openLightbox(photo, [pair.photo1, pair.photo2])}
                          >
                            <div
                              className={`relative overflow-hidden rounded-2xl ${
                                photo.id === pair.bestPhotoId
                                  ? "ring-2 ring-green-500"
                                  : "ring-1 ring-transparent"
                              }`}
                            >
                              <div className="relative aspect-square w-full">
                                <Image
                                  src={photo.url}
                                  alt={photo.title}
                                  fill
                                  className={`object-cover transition-all ${
                                    selectedPhotos.includes(photo.id)
                                      ? "brightness-75 ring-2 ring-blue-500"
                                      : "group-hover:scale-105"
                                  }`}
                                  sizes="(max-width: 768px) 100vw, 40vw"
                                  unoptimized
                                />
                              </div>
                              
                              {photo.id === pair.bestPhotoId && (
                                <div className="absolute top-3 left-3 z-10 rounded-full bg-green-500/90 p-2 text-white shadow">
                                  <Star className="w-4 h-4 fill-white text-green-500" />
                                </div>
                              )}
                              
                              {/* Selection Checkbox */}
                              <div
                                className="absolute top-3 right-3 z-10"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleSelectPhoto(photo.id);
                                }}
                              >
                                <div
                                  className={`w-7 h-7 rounded-full border-2 flex items-center justify-center cursor-pointer
                                    ${
                                      selectedPhotos.includes(photo.id)
                                        ? "bg-blue-500 border-blue-500"
                                        : "bg-white/80 border-gray-300"
                                    }`}
                                >
                                  {selectedPhotos.includes(photo.id) && (
                                    <svg
                                      className="w-4 h-4 text-white"
                                      fill="none"
                                      strokeLinecap="round"
                                      strokeLinejoin="round"
                                      strokeWidth="2"
                                      viewBox="0 0 24 24"
                                      stroke="currentColor"
                                    >
                                      <path d="M5 13l4 4L19 7"></path>
                                    </svg>
                                  )}
                                </div>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    ))}
                  </div>
                </div>
              ))}

              {/* No Duplicates Message */}
              {duplicateGroups.length === 0 && (
                <div className="text-center py-12">
                  <p className="text-gray-500 dark:text-gray-400">
                    No duplicate photos found. Your library is clean! 🎉
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

