"use client";
import { useState, useEffect, useCallback } from "react";
import MainLayout from "@/components/layout/MainLayout";
import AlbumCard from "@/components/albums/AlbumCard";
import CreateAlbumModal from "@/components/albums/CreateAlbumModal";
import { Plus } from "lucide-react";
import { useSession } from "@/components/providers/SessionProvider";
import { API_ENDPOINTS, API_BASE_URL } from "@/config/api";
import ProtectedRoute from "@/components/common/ProtectedRoute";

export default function AlbumsPage() {
  const { currentUser } = useSession();
  const [albums, setAlbums] = useState([]);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Fetch albums from API
  const fetchAlbums = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      setError("");

      const formData = new FormData();
      formData.append("username", currentUser);

      const response = await fetch(API_ENDPOINTS.listAlbums(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      // Transform API response: [album_id, name, cover_image_id, start_date]
      const transformedAlbums = data.map(([albumId, name, coverImageId, startDate]) => ({
        id: albumId.toString(),
        title: name,
        coverImageId: coverImageId ? coverImageId.toString() : null,
        startDate: startDate,
        coverUrl: coverImageId
          ? API_ENDPOINTS.getPreview(currentUser, coverImageId)
          : null,
      }));

      setAlbums(transformedAlbums);
    } catch (error) {
      console.error("Error fetching albums:", error);
      setError("Failed to load albums. Please try again.");
      setAlbums([]);
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  // Load albums on component mount
  useEffect(() => {
    fetchAlbums();
  }, [fetchAlbums]);

  const handleCreateAlbum = async ({ title, photoIds }) => {
    if (!currentUser) return;

    try {
      // Step 1: Create the album
      const createFormData = new FormData();
      createFormData.append("username", currentUser);
      createFormData.append("name", title);

      const createResponse = await fetch(API_ENDPOINTS.createAlbum(), {
        method: "POST",
        body: createFormData,
      });

      if (!createResponse.ok) {
        const errorText = await createResponse.text();
        throw new Error(errorText || "Failed to create album");
      }

      const createResult = await createResponse.text();
      if (createResult !== "Album created successfully") {
        throw new Error(createResult);
      }

      // Step 2: Add assets to the album if provided
      if (photoIds && photoIds.length > 0) {
        // Get the newly created album ID by fetching the updated list
        const latestFormData = new FormData();
        latestFormData.append("username", currentUser);
        
        const latestResponse = await fetch(API_ENDPOINTS.listAlbums(), {
          method: "POST",
          body: latestFormData,
        });
        
        if (latestResponse.ok) {
          const latestData = await latestResponse.json();
          // Find the album by name (since we just created it with this name)
          const newAlbum = latestData.find(([, name]) => name === title);
          
          if (newAlbum) {
            const albumId = newAlbum[0];

            // Add assets to album
            const addFormData = new FormData();
            addFormData.append("username", currentUser);
            addFormData.append("album_id", albumId.toString());
            addFormData.append("asset_id", photoIds.join(","));

            const addResponse = await fetch(API_ENDPOINTS.addAssetsToAlbum(), {
              method: "POST",
              body: addFormData,
            });

            if (!addResponse.ok) {
              const errorText = await addResponse.text();
              console.error("Failed to add assets to album:", errorText);
              // Album was created, but assets couldn't be added
              alert("Album created, but failed to add photos. You can add them manually.");
            }
          } else {
            console.warn("Could not find newly created album to add photos");
            alert("Album created, but failed to add photos. You can add them manually.");
          }
        }
      }

      // Refresh the albums list
      await fetchAlbums();
      setIsCreateModalOpen(false);
    } catch (error) {
      console.error("Error creating album:", error);
      alert(error.message || "Failed to create album. Please try again.");
    }
  };

  const handleDeleteAlbum = async (albumId) => {
    if (!currentUser) return;

    if (!window.confirm("Are you sure you want to delete this album?")) {
      return;
    }

    try {
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("album_id", albumId.toString());

      const response = await fetch(API_ENDPOINTS.deleteAlbum(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText || "Failed to delete album");
      }

      const result = await response.text();
      if (result !== "Album deleted successfully") {
        throw new Error(result);
      }

      // Refresh the albums list
      await fetchAlbums();
    } catch (error) {
      console.error("Error deleting album:", error);
      alert(error.message || "Failed to delete album. Please try again.");
    }
  };

  // Fetch available photos for the create modal
  const [availablePhotos, setAvailablePhotos] = useState([]);

  useEffect(() => {
    const fetchPhotos = async () => {
      if (!currentUser) return;

      try {
        const formData = new FormData();
        formData.append("username", currentUser);
        formData.append("page", "0");

        const response = await fetch(API_ENDPOINTS.getPhotosList(), {
          method: "POST",
          body: formData,
        });

        if (response.ok) {
          const data = await response.json();
          const photos = data.flatMap(([date, ids]) =>
            ids.map(([id, _, duration]) => ({
              id: id.toString(),
              url: API_ENDPOINTS.getPreview(currentUser, id),
              title: `Photo ${id}`,
              isVideo: duration !== null && duration !== undefined,
              duration: duration || null,
            }))
          );
          setAvailablePhotos(photos);
        }
      } catch (error) {
        console.error("Error fetching photos:", error);
      }
    };

    fetchPhotos();
  }, [currentUser]);

  return (
    <ProtectedRoute>
      <MainLayout>
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
                Albums
              </h1>
              <p className="text-gray-600 dark:text-gray-400 mt-2">
                Organize your photos into collections
              </p>
            </div>
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600 
                flex items-center gap-2"
            >
              <Plus className="w-5 h-5" />
              <span className="text-nowrap hidden sm:block">Create Album</span>
            </button>
          </div>

          {/* Loading State */}
          {loading && albums.length === 0 && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-gray-400">
                Loading albums...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && !loading && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={() => fetchAlbums()}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          {/* Albums Grid */}
          {!loading && albums.length > 0 && (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {albums.map((album) => (
                <AlbumCard
                  key={album.id}
                  album={album}
                  onDelete={handleDeleteAlbum}
                />
              ))}
            </div>
          )}

          {!loading && !error && albums.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500 dark:text-gray-400">
                No albums yet. Create your first album!
              </p>
            </div>
          )}

          <CreateAlbumModal
            isOpen={isCreateModalOpen}
            onClose={() => setIsCreateModalOpen(false)}
            onCreateAlbum={handleCreateAlbum}
            availablePhotos={availablePhotos}
          />
        </div>
      </MainLayout>
    </ProtectedRoute>
  );
}