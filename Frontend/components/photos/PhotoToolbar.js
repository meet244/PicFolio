import {
  Upload,
  Trash2,
  Download,
  Search,
  X,
  Heart,
  FolderInput,
} from "lucide-react";
import { useState } from "react";
import UploadModal from "./UploadModal";
import CreateAlbumModal from "../albums/CreateAlbumModal";
import AddToAlbumModal from "../albums/AddToAlbumModal";

export default function PhotoToolbar({
  selectedCount,
  onSelectAll,
  isAllSelected,
  onClearSelection,
  searchQuery,
  onSearchChange,
  onSearchSubmit,
  onAddToFavorites,
  onUploadPhotos,
  onCreateAlbum,
  onDelete,
  onDownload,
  availablePhotos,
  selectedPhotos,
  currentUser,
}) {
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [isCreateAlbumModalOpen, setIsCreateAlbumModalOpen] = useState(false);
  const [isAddToAlbumModalOpen, setIsAddToAlbumModalOpen] = useState(false);

  const handleUpload = (files) => {
    onUploadPhotos(files);
  };

  const handleCreateNewAlbum = () => {
    setIsAddToAlbumModalOpen(false);
    setIsCreateAlbumModalOpen(true);
  };

  return (
    <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow-md mb-6">
      <div className="flex flex-col space-y-4">
        {/* Search Bar */}
        <div className="relative flex items-center gap-2">
          <div className="relative flex-1">
            <div className="absolute inset-y-0 left-3 flex items-center pointer-events-none">
              <Search className="w-5 h-5 text-gray-400" />
            </div>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  onSearchSubmit?.(searchQuery);
                }
              }}
              placeholder="Search photos..."
              className="w-full pl-10 pr-10 py-2 rounded-lg border border-gray-200 
                dark:border-gray-700 dark:bg-gray-700 dark:text-gray-100
                focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none
                placeholder-gray-400 dark:placeholder-gray-500"
            />
            {searchQuery && (
              <button
                onClick={() => {
                  onSearchChange("");
                  onSearchSubmit?.(""); // Clear search results when clearing input
                }}
                className="absolute inset-y-0 right-3 flex items-center"
              >
                <X className="w-5 h-5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300" />
              </button>
            )}
          </div>
          <button
            onClick={() => onSearchSubmit?.(searchQuery)}
            className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600 
            flex items-center gap-2"
          >
            <Search className="w-5 h-5" />
            <span className="hidden sm:inline">Search</span>
          </button>
        </div>

        {/* Toolbar Actions */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div className="flex flex-wrap items-center gap-3">
            {selectedCount > 0 ? (
              <>
                <button
                  onClick={onClearSelection}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700
                  hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2
                  w-full sm:w-auto justify-center"
                >
                  Clear Selection ({selectedCount})
                </button>
                <button
                  onClick={onAddToFavorites}
                  className="px-4 py-2 rounded-lg bg-red-500 text-white hover:bg-red-600 
                  flex items-center gap-2 w-full sm:w-auto justify-center"
                >
                  <Heart className="w-5 h-5" />
                  <span>Add to Favorites</span>
                </button>
                <button
                  onClick={() => setIsAddToAlbumModalOpen(true)}
                  className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600 
                  flex items-center gap-2 w-full sm:w-auto justify-center"
                >
                  <FolderInput className="w-5 h-5" />
                  <span>Move to Album</span>
                </button>
                <button
                  onClick={onDownload}
                  className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600 
                  flex items-center gap-2 w-full sm:w-auto justify-center"
                >
                  <Download className="w-5 h-5" />
                  <span>Download</span>
                </button>
                <button
                  onClick={onDelete}
                  className="px-4 py-2 rounded-lg bg-red-500 text-white hover:bg-red-600 
                  flex items-center gap-2 w-full sm:w-auto justify-center"
                >
                  <Trash2 className="w-5 h-5" />
                  <span>Delete</span>
                </button>
              </>
            ) : (
              <button
                onClick={() => setIsUploadModalOpen(true)}
                className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600 
                flex items-center gap-2 w-full sm:w-auto justify-center"
              >
                <Upload className="w-5 h-5" />
                <span>Upload</span>
              </button>
            )}
          </div>
        </div>
      </div>

      <UploadModal
        isOpen={isUploadModalOpen}
        onClose={() => setIsUploadModalOpen(false)}
        onUpload={handleUpload}
      />

      <AddToAlbumModal
        isOpen={isAddToAlbumModalOpen}
        onClose={() => setIsAddToAlbumModalOpen(false)}
        currentUser={currentUser}
        selectedPhotoIds={selectedPhotos}
        onCreateNewAlbum={handleCreateNewAlbum}
        onSuccess={onClearSelection}
      />

      <CreateAlbumModal
        isOpen={isCreateAlbumModalOpen}
        onClose={() => setIsCreateAlbumModalOpen(false)}
        onCreateAlbum={onCreateAlbum}
        availablePhotos={availablePhotos}
        preselectedPhotos={selectedPhotos}
      />
    </div>
  );
}
