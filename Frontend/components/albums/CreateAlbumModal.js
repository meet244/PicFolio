"use client";
import { useState, useEffect } from "react";
import { Dialog } from "@headlessui/react";
import { X } from "lucide-react";
import Image from "next/image";

export default function CreateAlbumModal({
  isOpen,
  onClose,
  onCreateAlbum,
  availablePhotos = [],
  preselectedPhotos = [],
}) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [date, setDate] = useState("");
  const [selectedPhotos, setSelectedPhotos] = useState([]);

  // Reset form and update selections when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      // Only update selected photos if they're different from current selection
      if (
        JSON.stringify(selectedPhotos) !== JSON.stringify(preselectedPhotos)
      ) {
        setSelectedPhotos(preselectedPhotos);
      }
      // Set default date to today
      setDate(new Date().toISOString().slice(0, 10));
    } else {
      // Reset form when modal closes
      setTitle("");
      setDescription("");
      setDate("");
      setSelectedPhotos([]);
    }
  }, [isOpen]); // Only depend on isOpen, not preselectedPhotos

  const handleSubmit = (e) => {
    e.preventDefault();
    onCreateAlbum({
      title,
      description,
      date,
      photoIds: selectedPhotos,
    });
    setTitle("");
    setDescription("");
    setDate("");
    setSelectedPhotos([]);
    onClose();
  };

  const togglePhotoSelection = (photoId) => {
    setSelectedPhotos((prev) =>
      prev.includes(photoId)
        ? prev.filter((id) => id !== photoId)
        : [...prev, photoId]
    );
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
              Create New Album
            </Dialog.Title>
            <button
              onClick={onClose}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label
                htmlFor="title"
                className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
              >
                Album Title
              </label>
              <input
                type="text"
                id="title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
                className="w-full px-4 py-2 rounded-lg border border-gray-200 
                  dark:border-gray-700 dark:bg-gray-700 dark:text-gray-100
                  focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                placeholder="Enter album title"
              />
            </div>

            <div>
              <label
                htmlFor="date"
                className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
              >
                Date
              </label>
              <input
                type="date"
                id="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                required
                className="w-full px-4 py-2 rounded-lg border border-gray-200 
                  dark:border-gray-700 dark:bg-gray-700 dark:text-gray-100
                  focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none
                  cursor-pointer"
                onClick={(e) => e.target.showPicker && e.target.showPicker()}
              />
            </div>

            <div>
              <label
                htmlFor="description"
                className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
              >
                Description
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                rows={3}
                className="w-full px-4 py-2 rounded-lg border border-gray-200 
                  dark:border-gray-700 dark:bg-gray-700 dark:text-gray-100
                  focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                placeholder="Enter album description"
              />
            </div>

            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700
                  hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={!title}
                className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600
                  disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Create Album
              </button>
            </div>
          </form>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}