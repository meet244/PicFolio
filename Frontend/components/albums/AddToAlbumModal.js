import { Dialog } from "@headlessui/react";
import { X, FolderPlus, Image as ImageIcon, Calendar } from "lucide-react";
import { useState, useEffect } from "react";
import { API_ENDPOINTS } from "@/config/api";
import Image from "next/image";

export default function AddToAlbumModal({
  isOpen,
  onClose,
  currentUser,
  selectedPhotoIds = [],
  onCreateNewAlbum,
  onSuccess,
}) {
  const [albums, setAlbums] = useState([]);
  const [loading, setLoading] = useState(false);
  const [addingToAlbum, setAddingToAlbum] = useState(null);

  useEffect(() => {
    if (isOpen && currentUser) {
      fetchAlbums();
    }
  }, [isOpen, currentUser]);

  const fetchAlbums = async () => {
    try {
      setLoading(true);
      const formData = new FormData();
      formData.append("username", currentUser);

      const response = await fetch(API_ENDPOINTS.listAlbums(), {
        method: "POST",
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        // Transform array data to object: [id, name, coverId, date]
        const transformedAlbums = data.map(([id, name, coverId, date]) => ({
          id,
          name,
          coverId,
          date,
        }));
        setAlbums(transformedAlbums);
      }
    } catch (error) {
      console.error("Error fetching albums:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddToAlbum = async (albumId) => {
    try {
      setAddingToAlbum(albumId);
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("album_id", albumId);
      formData.append("asset_id", selectedPhotoIds.join(","));

      const response = await fetch(API_ENDPOINTS.addAssetsToAlbum(), {
        method: "POST",
        body: formData,
      });

      if (response.ok) {
        onSuccess?.();
        onClose();
      } else {
        console.error("Failed to add to album");
      }
    } catch (error) {
      console.error("Error adding to album:", error);
    } finally {
      setAddingToAlbum(null);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div
        className="fixed inset-0 bg-black/50 backdrop-blur-sm"
        aria-hidden="true"
      />

      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="w-full max-w-2xl rounded-2xl bg-white dark:bg-gray-800 p-6 shadow-xl max-h-[80vh] flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <Dialog.Title className="text-2xl font-semibold text-gray-800 dark:text-gray-100">
              Move to Album
            </Dialog.Title>
            <button
              onClick={onClose}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto min-h-0">
            <button
              onClick={onCreateNewAlbum}
              className="w-full flex items-center gap-4 p-4 rounded-xl border-2 border-dashed border-gray-300 dark:border-gray-600 hover:border-blue-500 dark:hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors mb-4 group"
            >
              <div className="p-3 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-500 group-hover:bg-blue-500 group-hover:text-white transition-colors">
                <FolderPlus className="w-6 h-6" />
              </div>
              <div className="text-left">
                <h3 className="font-semibold text-gray-900 dark:text-white">
                  Create New Album
                </h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Create a new album with selected photos
                </p>
              </div>
            </button>

            {loading ? (
              <div className="flex justify-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {albums.map((album) => (
                  <button
                    key={album.id}
                    onClick={() => handleAddToAlbum(album.id)}
                    disabled={addingToAlbum === album.id}
                    className="flex items-center gap-4 p-3 rounded-xl border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-all text-left group disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-800 flex-shrink-0">
                      {album.coverId ? (
                        <Image
                          src={API_ENDPOINTS.getAssetDetails(currentUser, album.coverId).replace('details', 'preview')} // Guessing preview URL, or construct it properly
                          alt={album.name}
                          fill
                          className="object-cover"
                          // Fallback logic might be needed but for now let's try constructing preview URL
                          loader={({ src }) => `${src}`} 
                          unoptimized
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-gray-400">
                          <ImageIcon className="w-8 h-8" />
                        </div>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold text-gray-900 dark:text-white truncate group-hover:text-blue-500 transition-colors">
                        {album.name}
                      </h3>
                      <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400 mt-1">
                        <Calendar className="w-3 h-3" />
                        <span>{album.date || "No date"}</span>
                      </div>
                    </div>
                    {addingToAlbum === album.id && (
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500"></div>
                    )}
                  </button>
                ))}
              </div>
            )}
            
            {!loading && albums.length === 0 && (
              <div className="text-center py-8 text-gray-500 dark:text-gray-400">
                No existing albums found.
              </div>
            )}
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}



