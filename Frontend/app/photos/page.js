"use client";
import { useState, useEffect, useCallback, useRef } from "react";
import MainLayout from "@/components/layout/MainLayout";
import PhotoGrid from "@/components/photos/PhotoGrid";
import PhotoToolbar from "@/components/photos/PhotoToolbar";
import DateSection from "@/components/photos/DateSection";
import { dummyPhotosByDate } from "@/data/photos";
import { v4 as uuidv4 } from "uuid";
import { useGallery } from "@/store/GalleryStore";
import Lightbox from "@/components/photos/Lightbox";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { API_ENDPOINTS, API_BASE_URL } from "@/config/api";
import PendingProcessing from "@/components/photos/PendingProcessing";

export default function PhotosPage() {
  const { currentUser, logout } = useSession();
  const [selectedPhotos, setSelectedPhotos] = useState([]);
  const [searchQuery, setSearchQuery] = useState("");
  const { favorites, toggleFavorite, addFavorites, addAlbum, setUser } = useGallery();
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxPhotos, setLightboxPhotos] = useState([]);
  const [lightboxStartIndex, setLightboxStartIndex] = useState(0);
  const [visibleGroups, setVisibleGroups] = useState(2);

  // Real data from API
  const [photosByDate, setPhotosByDate] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [currentPage, setCurrentPage] = useState(0);
  const [isFetchingMore, setIsFetchingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const loadMoreRef = useRef(null);

  // Set user when currentUser changes
  useEffect(() => {
    if (currentUser) {
      setUser(currentUser);
    }
  }, [currentUser, setUser]);

  // Fetch photos from API
  const fetchPhotos = useCallback(
    async (page = 0) => {
      if (!currentUser) return;

      try {
        if (page === 0) {
          setLoading(true);
        } else {
          setIsFetchingMore(true);
        }
        setError("");

        const formData = new FormData();
        formData.append("username", currentUser);
        formData.append("page", page.toString());

        const response = await fetch(API_ENDPOINTS.getPhotosList(), {
          method: "POST",
          body: formData,
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        // Transform API response to match our component structure
        const transformedData = data.map(([date, ids]) => {
          const uniquePhotos = [];
          const seenIds = new Set();

          ids.forEach(([id, _, duration]) => {
            const idStr = id.toString();
            if (!seenIds.has(idStr)) {
              seenIds.add(idStr);
              uniquePhotos.push({
                id: idStr,
                url: API_ENDPOINTS.getPreview(currentUser, id),
                title: `Photo ${id}`,
                isVideo: duration !== null && duration !== undefined,
                duration: duration || null,
              });
            }
          });

          return {
            date: date,
            photos: uniquePhotos,
          };
        });

        if (page === 0) {
          setPhotosByDate(transformedData);
        } else {
          // Merge duplicate dates when appending new data
          setPhotosByDate((prev) => {
            const merged = [...prev];
            transformedData.forEach((newGroup) => {
              const existingIndex = merged.findIndex(
                (g) => g.date === newGroup.date
              );
              if (existingIndex >= 0) {
                // Merge photos into existing date group
                const existingPhotos = merged[existingIndex].photos;
                const existingIds = new Set(existingPhotos.map((p) => p.id));
                const uniqueNewPhotos = newGroup.photos.filter(
                  (p) => !existingIds.has(p.id)
                );

                merged[existingIndex] = {
                  ...merged[existingIndex],
                  photos: [...existingPhotos, ...uniqueNewPhotos],
                };
              } else {
                // Add new date group
                merged.push(newGroup);
              }
            });
            return merged;
          });
        }

        setHasMore(transformedData.length > 0);
      } catch (error) {
        console.error("Error fetching photos:", error);
        setError("Failed to load photos. Please try again.");
        // Fallback to dummy data if API fails
        setPhotosByDate(dummyPhotosByDate);
        setHasMore(false);
      } finally {
        if (page === 0) {
          setLoading(false);
        } else {
          setIsFetchingMore(false);
        }
      }
    },
    [currentUser]
  );

  // Load photos on component mount
  useEffect(() => {
    fetchPhotos(0);
  }, [fetchPhotos]);

  const loadMore = useCallback(() => {
    if (loading || isFetchingMore || !hasMore) return;
    setCurrentPage((prev) => {
      const nextPage = prev + 1;
      fetchPhotos(nextPage);
      return nextPage;
    });
  }, [loading, isFetchingMore, hasMore, fetchPhotos]);

  useEffect(() => {
    if (!hasMore) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0];
        if (entry.isIntersecting) {
          loadMore();
        }
      },
      { rootMargin: "200px" }
    );

    const current = loadMoreRef.current;
    if (current) {
      observer.observe(current);
    }

    return () => {
      if (current) {
        observer.unobserve(current);
      }
    };
  }, [loadMore, hasMore]);

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

  const handleSelectAll = () => {
    const allPhotoIds = photosByDate.flatMap((group) =>
      group.photos.map((photo) => photo.id)
    );

    if (selectedPhotos.length === allPhotoIds.length) {
      setSelectedPhotos([]);
    } else {
      setSelectedPhotos(allPhotoIds);
    }
  };

  const handleToggleFavorite = (photoId) => {
    toggleFavorite(photoId);
  };

  const handleAddSelectedToFavorites = () => {
    addFavorites(selectedPhotos);
    setSelectedPhotos([]);
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

      // Refresh the photos list
      setCurrentPage(0);
      await fetchPhotos(0);
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
      setCurrentPage(0);
      await fetchPhotos(0);
    } catch (error) {
      console.error("Error deleting asset:", error);
      alert("Failed to delete photo. Please try again.");
    }
  };

  const handleDownloadPhotos = async () => {
    if (!currentUser || selectedPhotos.length === 0) return;

    try {
      // Download each selected photo
      for (const photoId of selectedPhotos) {
        const downloadUrl = API_ENDPOINTS.getMaster(currentUser, photoId);
        
        // Create a temporary link and trigger download
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.download = `photo-${photoId}`;
        link.target = '_blank';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        // Add a small delay between downloads to avoid browser blocking
        if (selectedPhotos.length > 1) {
          await new Promise(resolve => setTimeout(resolve, 300));
        }
      }
    } catch (error) {
      console.error("Error downloading photos:", error);
      alert("Failed to download photos. Please try again.");
    }
  };

  const handleSearch = async (query) => {
    if (!query) {
      fetchPhotos(0);
      return;
    }

    setLoading(true);
    setError("");
    setPhotosByDate([]);

    try {
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("query", query);
      formData.append("type", "search");

      const response = await fetch(API_ENDPOINTS.searchAssets(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      const transformedData = data.map(([date, ids]) => {
        const uniquePhotos = [];
        const seenIds = new Set();

        ids.forEach((idArr) => {
          const id = idArr[0];
          const idStr = id.toString();

          if (!seenIds.has(idStr)) {
            seenIds.add(idStr);
            uniquePhotos.push({
              id: idStr,
              url: API_ENDPOINTS.getPreview(currentUser, id),
              title: `Photo ${id}`,
              isVideo: false,
              duration: null,
            });
          }
        });

        return {
          date: date,
          photos: uniquePhotos,
        };
      });

      setPhotosByDate(transformedData);
      setHasMore(false);
    } catch (error) {
      console.error("Error searching photos:", error);
      setError("Failed to search photos. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  // Filter photos based on search query
  // We now use backend search, so we don't filter client-side
  const filteredPhotosByDate = photosByDate;

  const handleUploadPhotos = async (files) => {
    // After successful upload, refresh the photos list
    setCurrentPage(0);
    await fetchPhotos(0);
    setSelectedPhotos([]);
  };

  const handleCreateAlbum = async ({ title, description, date, photoIds }) => {
    if (!currentUser || !title) return;

    try {
      // 1. Create Album
      const createFormData = new FormData();
      createFormData.append("username", currentUser);
      createFormData.append("name", title);
      if (date) createFormData.append("start", date); // Sending date as start
      // createFormData.append("description", description); // Not supported by backend yet

      const createResponse = await fetch(API_ENDPOINTS.createAlbum(), {
        method: "POST",
        body: createFormData,
      });

      if (!createResponse.ok) {
        throw new Error("Failed to create album");
      }

      // 2. Add photos if selected
      if (photoIds && photoIds.length > 0) {
        // Since create API doesn't return ID, we try to find the album by fetching list
        // This is a workaround until backend returns ID
        const listFormData = new FormData();
        listFormData.append("username", currentUser);
        const listResponse = await fetch(API_ENDPOINTS.listAlbums(), {
          method: "POST",
          body: listFormData,
        });

        if (listResponse.ok) {
          const albums = await listResponse.json();
          // Find album with matching name and recent date
          // We assume the newest album with this name is the one we just created
          // Album structure: [id, name, coverId, date]
          const match = albums.find((a) => a[1] === title); 
          
          if (match) {
            const albumId = match[0];
            const addFormData = new FormData();
            addFormData.append("username", currentUser);
            addFormData.append("album_id", albumId);
            addFormData.append("asset_id", photoIds.join(","));

            await fetch(API_ENDPOINTS.addAssetsToAlbum(), {
              method: "POST",
              body: addFormData,
            });
          }
        }
      }

      // Refresh local state via context if needed, or just clear selection
      setSelectedPhotos([]);
      // Optionally refresh album list if we were displaying albums here
      alert("Album created successfully!");
    } catch (error) {
      console.error("Error creating album:", error);
      alert("Failed to create album. Please try again.");
    }
  };

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
              Photos
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Welcome back, {currentUser}!
            </p>
          </div>

          <PhotoToolbar
            selectedCount={selectedPhotos.length}
            onSelectAll={handleSelectAll}
            isAllSelected={
              selectedPhotos.length ===
              photosByDate.flatMap((g) => g.photos).length
            }
            onClearSelection={() => setSelectedPhotos([])}
            searchQuery={searchQuery}
            onSearchChange={setSearchQuery}
            onSearchSubmit={handleSearch}
            onAddToFavorites={handleAddSelectedToFavorites}
            onUploadPhotos={handleUploadPhotos}
            onCreateAlbum={handleCreateAlbum}
            onDelete={handleDeletePhotos}
            onDownload={handleDownloadPhotos}
            availablePhotos={photosByDate.flatMap((group) => group.photos)}
            selectedPhotos={selectedPhotos}
            currentUser={currentUser}
          />

          <PendingProcessing currentUser={currentUser} />

          {/* Loading State */}
          {loading && photosByDate.length === 0 && (
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
                onClick={() => fetchPhotos(0)}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          <div className="space-y-8">
            {filteredPhotosByDate.map((group, index) => {
              const datePhotoIds = group.photos.map((photo) => photo.id);
              const dateSelectionCount = datePhotoIds.filter((id) =>
                selectedPhotos.includes(id)
              ).length;

              // Create unique key by combining date with first photo ID and index
              // This ensures uniqueness even if same date appears multiple times
              const uniqueKey = `${group.date}-${group.photos[0]?.id || index}-${index}`;

              return (
                <DateSection
                  key={uniqueKey}
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
                    isAllSelected={datePhotoIds.every((id) =>
                      selectedPhotos.includes(id)
                    )}
                    favorites={favorites}
                    onToggleFavorite={handleToggleFavorite}
                    onOpenPhoto={(photo) => openLightbox(photo, group.photos)}
                  />
                </DateSection>
              );
            })}

            {/* No Results Message */}
            {filteredPhotosByDate.length === 0 && (
              <div className="text-center py-12">
                <p className="text-gray-500 dark:text-gray-400">
                  No photos found matching {`"${searchQuery}"`}
                </p>
              </div>
            )}

            <div ref={loadMoreRef} className="flex justify-center py-6">
              {isFetchingMore && (
                <div className="text-gray-500 dark:text-gray-400 text-sm">
                  Loading more photos...
                </div>
              )}
              {!hasMore && !loading && photosByDate.length > 0 && (
                <div className="text-gray-400 dark:text-gray-600 text-sm">
                  You&apos;re all caught up.
                </div>
              )}
            </div>
          </div>
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
