"use client";
import { useState, useCallback } from "react";
import { Dialog } from "@headlessui/react";
import { Upload, X, Image as ImageIcon } from "lucide-react";
import { useDropzone } from "react-dropzone";
import { API_ENDPOINTS } from "../../config/api";
import { useSession } from "../providers/SessionProvider";

export default function UploadModal({ isOpen, onClose, onUpload }) {
  const { currentUser } = useSession();
  const [files, setFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadedCount, setUploadedCount] = useState(0);
  const [error, setError] = useState("");

  const onDrop = useCallback((acceptedFiles) => {
    // Create preview URLs for the files
    const newFiles = acceptedFiles.map((file) => ({
      file,
      preview: URL.createObjectURL(file),
      name: file.name,
      size: file.size,
    }));
    setFiles((prev) => [...prev, ...newFiles]);
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      "image/*": [
        ".jpeg",
        ".jpg",
        ".png",
        ".gif",
        ".webp",
        ".avif",
        ".heic",
        ".ttif",
        ".jfif",
      ],
      "video/*": [".mp4", ".mov", ".avi", ".webm", ".flv", ".wmv", ".mkv"],
    },
  });

  const removeFile = (fileToRemove) => {
    setFiles((prev) =>
      prev.filter((file) => file.preview !== fileToRemove.preview)
    );
    URL.revokeObjectURL(fileToRemove.preview);
  };

  const handleUpload = async () => {
    if (!currentUser) {
      setError("No user logged in");
      return;
    }

    setUploading(true);
    setError("");
    setUploadProgress(0);
    setUploadedCount(0);

    try {
      const totalFiles = files.length;
      let completed = 0;

      // Upload files sequentially to track progress properly
      for (let i = 0; i < files.length; i++) {
        const fileItem = files[i];
        const formData = new FormData();
        formData.append("username", currentUser);
        formData.append("asset", fileItem.file);
        formData.append("compress", "true"); // Enable compression

        try {
          const response = await fetch(API_ENDPOINTS.uploadAsset(), {
            method: "POST",
            body: formData,
          });

          if (!response.ok) {
            const errorData = await response.json();
            throw new Error(
              errorData.error || `Upload failed for ${fileItem.name}`
            );
          }

          await response.json();
          completed++;
          setUploadedCount(completed);
          setUploadProgress(Math.round((completed / totalFiles) * 100));
        } catch (error) {
          console.error(`Upload failed for ${fileItem.name}:`, error);
          throw error;
        }
      }

      // All uploads successful
      alert(`Successfully uploaded ${completed} file(s)!`);
      setFiles([]);
      onClose();

      // Call the callback to refresh the photo list
      if (onUpload) {
        onUpload(files.map((f) => f.file));
      }
    } catch (error) {
      console.error("Upload failed:", error);
      setError(error.message || "Upload failed. Please try again.");
    } finally {
      setUploading(false);
      setUploadProgress(0);
      setUploadedCount(0);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div
        className="fixed inset-0 bg-black/50 backdrop-blur-sm"
        aria-hidden="true"
      />

      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="w-full max-w-3xl rounded-2xl bg-white dark:bg-gray-800 p-6 shadow-xl">
          <div className="flex justify-between items-center mb-6">
            <Dialog.Title className="text-2xl font-semibold text-gray-800 dark:text-gray-100">
              Upload Files
            </Dialog.Title>
            <button
              onClick={onClose}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>

          {/* Dropzone */}
          <div
            {...getRootProps()}
            className={`border-2 border-dashed rounded-xl p-8 text-center cursor-pointer
              transition-colors ${
                isDragActive
                  ? "border-blue-500 bg-blue-50 dark:bg-blue-500/10"
                  : "border-gray-300 dark:border-gray-600 hover:border-blue-500 dark:hover:border-blue-500"
              }`}
          >
            <input {...getInputProps()} />
            <Upload
              className={`w-12 h-12 mx-auto mb-4 ${
                isDragActive ? "text-blue-500" : "text-gray-400"
              }`}
            />
            <p className="text-gray-600 dark:text-gray-300 mb-2">
              {isDragActive
                ? "Drop the files here..."
                : "Drag & drop files here, or click to select"}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Supports: Images (JPG, PNG, GIF, WEBP, AVIF, HEIC) and Videos
              (MP4, MOV, AVI, WEBM)
            </p>
          </div>

          {/* Preview Grid */}
          {files.length > 0 && (
            <div className="mt-6">
              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-100 mb-3">
                Selected Files ({files.length})
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 max-h-96 overflow-y-auto pr-2">
                {files.map((file) => (
                  <div
                    key={file.preview}
                    className="relative group aspect-square rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-700"
                  >
                    {file.file.type.startsWith("video/") ? (
                      <video
                        src={file.preview}
                        className="w-full h-full object-cover"
                        muted
                      />
                    ) : (
                      <img
                        src={file.preview}
                        alt={file.name}
                        className="w-full h-full object-cover"
                      />
                    )}
                    <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity">
                      <div className="absolute inset-0 flex flex-col items-center justify-center p-2 text-white">
                        <p className="text-sm truncate w-full text-center">
                          {file.name}
                        </p>
                        <p className="text-xs text-gray-300">
                          {(file.size / 1024 / 1024).toFixed(2)} MB
                        </p>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            removeFile(file);
                          }}
                          className="mt-2 p-1 rounded-full bg-red-500/50 hover:bg-red-500"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Error Display */}
          {error && (
            <div className="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
              <p className="text-red-600 dark:text-red-400 text-sm">{error}</p>
            </div>
          )}

          {/* Upload Progress */}
          {uploading && files.length > 0 && (
            <div className="mt-4">
              <div className="flex justify-between items-center mb-2">
                <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Upload Progress
                </h4>
                <span className="text-sm text-gray-600 dark:text-gray-400">
                  {uploadedCount} / {files.length} files
                </span>
              </div>
              <div className="flex items-center gap-3">
                <div className="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-3">
                  <div
                    className="bg-blue-500 h-3 rounded-full transition-all duration-300 flex items-center justify-center"
                    style={{ width: `${uploadProgress}%` }}
                  >
                    {uploadProgress > 10 && (
                      <span className="text-xs text-white font-medium">
                        {uploadProgress}%
                      </span>
                    )}
                  </div>
                </div>
                {uploadProgress <= 10 && (
                  <span className="text-sm text-gray-600 dark:text-gray-400 min-w-[3rem]">
                    {uploadProgress}%
                  </span>
                )}
              </div>
            </div>
          )}

          {/* Actions */}
          <div className="mt-6 flex justify-end gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700
                hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300"
            >
              Cancel
            </button>
            <button
              onClick={handleUpload}
              disabled={files.length === 0 || uploading}
              className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600
                disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {uploading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Uploading...</span>
                </>
              ) : (
                <>
                  <Upload className="w-5 h-5" />
                  <span>
                    Upload {files.length} File{files.length !== 1 ? "s" : ""}
                  </span>
                </>
              )}
            </button>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}
