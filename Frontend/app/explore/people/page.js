"use client";

import { useState, useEffect, useCallback } from "react";
import MainLayout from "@/components/layout/MainLayout";
import Image from "next/image";
import Link from "next/link";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { API_ENDPOINTS, API_BASE_URL } from "@/config/api";
import { Trash2, Edit2, X, UserPlus } from "lucide-react";

export default function AllPeoplePage() {
  const { currentUser } = useSession();
  const [people, setPeople] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedPeople, setSelectedPeople] = useState([]);
  const [isSelecting, setIsSelecting] = useState(false);

  // Fetch faces from API
  const fetchFaces = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      setError("");

      const formData = new FormData();
      formData.append("username", currentUser);

      const response = await fetch(API_ENDPOINTS.getFacesList(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      // Transform API response and fetch counts
      const transformedPeople = await Promise.all(
        data.map(async ([faceId, name]) => {
          try {
            const countResponse = await fetch(
              API_ENDPOINTS.getFaceName(currentUser, faceId)
            );
            const [faceName, count] = await countResponse.json();
            return {
              id: faceId.toString(),
              name: faceName,
              avatar: `${API_BASE_URL}/api/face/image/${currentUser}/${faceId}`,
              photoCount: count || 0,
            };
          } catch {
            return {
              id: faceId.toString(),
              name: name,
              avatar: `${API_BASE_URL}/api/face/image/${currentUser}/${faceId}`,
              photoCount: 0,
            };
          }
        })
      );

      setPeople(transformedPeople);
    } catch (error) {
      console.error("Error fetching faces:", error);
      setError("Failed to load people. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  // Load faces on component mount
  useEffect(() => {
    fetchFaces();
  }, [fetchFaces]);

  // Filter people based on search
  const filteredPeople = people.filter((person) =>
    person.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleSelectPerson = (personId) => {
    setSelectedPeople((prev) =>
      prev.includes(personId)
        ? prev.filter((id) => id !== personId)
        : [...prev, personId]
    );
  };

  const handleDeleteSelected = async () => {
    if (!currentUser || selectedPeople.length === 0) return;

    if (
      !window.confirm(
        `Delete ${selectedPeople.length} person(s)? This will remove them from the system.`
      )
    ) {
      return;
    }

    try {
      let successCount = 0;
      let failCount = 0;

      for (const faceId of selectedPeople) {
        try {
          const response = await fetch(
            API_ENDPOINTS.deleteFace(currentUser, faceId),
            {
              method: "DELETE",
            }
          );

          if (!response.ok) {
            throw new Error(`Failed to delete face ${faceId}`);
          }

          const result = await response.json();
          if (result === "Face deleted successfully") {
            successCount++;
          } else {
            throw new Error(result);
          }
        } catch (error) {
          console.error(`Error deleting face ${faceId}:`, error);
          failCount++;
        }
      }

      if (successCount > 0) {
        await fetchFaces();
        setSelectedPeople([]);
        setIsSelecting(false);
        alert(
          `Deleted ${successCount} face(s)${
            failCount > 0 ? `\nFailed to delete ${failCount}` : ""
          }`
        );
      } else if (failCount > 0) {
        alert("Failed to delete selected faces. Please try again.");
      }
    } catch (error) {
      console.error("Error deleting faces:", error);
      alert("Failed to delete selected faces. Please try again.");
    }
  };

  const handleRenameSelected = async () => {
    if (selectedPeople.length !== 1) {
      alert("Please select exactly one person to rename");
      return;
    }

    const person = people.find((p) => p.id === selectedPeople[0]);
    if (!person) return;

    const newName = prompt("Enter new name:", person.name);
    if (!newName || newName === person.name) return;

    try {
      const response = await fetch(
        API_ENDPOINTS.renameFace(currentUser, person.id, newName),
        {
          method: "GET",
        }
      );

      if (!response.ok) {
        throw new Error("Failed to rename face");
      }

      const result = await response.json();
      if (result === "Face renamed successfully") {
        // Refresh the list
        await fetchFaces();
        setSelectedPeople([]);
        setIsSelecting(false);
      } else {
        throw new Error(result);
      }
    } catch (error) {
      console.error("Error renaming face:", error);
      alert("Failed to rename person. Please try again.");
    }
  };

  const handleMergeFaces = async () => {
    if (selectedPeople.length < 2) {
      alert("Please select at least 2 people to merge");
      return;
    }

    const selectedPersons = selectedPeople.map(id => people.find(p => p.id === id)).filter(Boolean);
    
    if (selectedPersons.length < 2) return;

    // Create a list of names for selection
    const namesList = selectedPersons.map((p, idx) => `${idx + 1}. ${p.name}`).join('\n');

    // Ask which person should be the main one
    const mainPersonName = prompt(
      `Select the person to KEEP (all others will be merged into this person):\n\n` +
      namesList +
      `\n\nType the exact name of the person to KEEP:`,
      selectedPersons[0].name
    );

    if (!mainPersonName) return;

    const mainPerson = selectedPersons.find(p => p.name === mainPersonName);
    
    if (!mainPerson) {
      alert("Invalid selection. Please type the exact name.");
      return;
    }

    const sidePeople = selectedPersons.filter(p => p.id !== mainPerson.id);
    const sideNames = sidePeople.map(p => `"${p.name}"`).join(", ");

    if (
      !window.confirm(
        `Are you sure you want to merge these faces?\n\n` +
        `${sideNames} will be removed and all their photos will be moved to "${mainPerson.name}".\n\n` +
        `This action cannot be undone.`
      )
    ) {
      return;
    }

    try {
      let successCount = 0;
      let failCount = 0;

      // Merge each side person into the main person
      for (const sidePerson of sidePeople) {
        try {
          const formData = new FormData();
          formData.append("username", currentUser);
          formData.append("main_face_id1", mainPerson.id);
          formData.append("side_face_id2", sidePerson.id);

          const response = await fetch(API_ENDPOINTS.joinFaces(), {
            method: "POST",
            body: formData,
          });

          if (!response.ok) {
            throw new Error("Failed to merge faces");
          }

          const result = await response.json();
          if (result === "Faces joined successfully") {
            successCount++;
          } else {
            throw new Error(result);
          }
        } catch (error) {
          console.error(`Error merging ${sidePerson.name}:`, error);
          failCount++;
        }
      }

      if (successCount > 0) {
        alert(`Successfully merged ${successCount} face(s) into "${mainPerson.name}"!${failCount > 0 ? `\n\nFailed to merge ${failCount} face(s).` : ''}`);
        // Refresh the list
        await fetchFaces();
        setSelectedPeople([]);
        setIsSelecting(false);
      } else {
        alert("Failed to merge faces. Please try again.");
      }
    } catch (error) {
      console.error("Error merging faces:", error);
      alert("Failed to merge faces. Please try again.");
    }
  };

  return (
    <ProtectedRoute>
      <MainLayout>
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
              All People
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Browse all detected faces in your photos
            </p>
          </div>

          {/* Search Bar and Actions */}
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
            <div className="flex-1 max-w-md">
              <input
                type="text"
                placeholder="Search people..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="flex gap-2">
              {!isSelecting ? (
                <button
                  onClick={() => setIsSelecting(true)}
                  className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600 transition"
                >
                  Select
                </button>
              ) : (
                <>
                  <button
                    onClick={() => {
                      setIsSelecting(false);
                      setSelectedPeople([]);
                    }}
                    className="px-4 py-2 rounded-lg bg-gray-500 text-white hover:bg-gray-600 transition flex items-center gap-2"
                  >
                    <X className="w-4 h-4" />
                    Cancel
                  </button>
                  {selectedPeople.length === 1 && (
                    <button
                      onClick={handleRenameSelected}
                      className="px-4 py-2 rounded-lg bg-green-500 text-white hover:bg-green-600 transition flex items-center gap-2"
                    >
                      <Edit2 className="w-4 h-4" />
                      Rename
                    </button>
                  )}
                  {selectedPeople.length >= 2 && (
                    <button
                      onClick={handleMergeFaces}
                      className="px-4 py-2 rounded-lg bg-purple-500 text-white hover:bg-purple-600 transition flex items-center gap-2"
                    >
                      <UserPlus className="w-4 h-4" />
                      Merge Faces ({selectedPeople.length})
                    </button>
                  )}
                  {selectedPeople.length > 0 && (
                    <button
                      onClick={handleDeleteSelected}
                      className="px-4 py-2 rounded-lg bg-red-500 text-white hover:bg-red-600 transition flex items-center gap-2"
                    >
                      <Trash2 className="w-4 h-4" />
                      Delete ({selectedPeople.length})
                    </button>
                  )}
                </>
              )}
            </div>
          </div>

          {/* Loading State */}
          {loading && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-gray-400">
                Loading people...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={fetchFaces}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          {/* People Grid */}
          {!loading && !error && filteredPeople.length > 0 && (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-6">
              {filteredPeople.map((person) => (
                <div key={person.id} className="flex flex-col items-center group relative">
                  {isSelecting ? (
                    <div
                      onClick={() => handleSelectPerson(person.id)}
                      className="flex flex-col items-center cursor-pointer"
                    >
                      <div
                        className={`w-32 h-32 rounded-2xl overflow-hidden ring-2 transition ${
                          selectedPeople.includes(person.id)
                            ? "ring-blue-500 brightness-75"
                            : "ring-gray-200 dark:ring-gray-700 group-hover:ring-blue-500"
                        }`}
                      >
                        <Image
                          src={person.avatar}
                          alt={person.name}
                          width={128}
                          height={128}
                          className="w-full h-full object-cover"
                          unoptimized
                        />
                        {/* Selection Checkbox */}
                        <div className="absolute top-2 right-2 z-10">
                          <div
                            className={`w-6 h-6 rounded-full border-2 flex items-center justify-center ${
                              selectedPeople.includes(person.id)
                                ? "bg-blue-500 border-blue-500"
                                : "bg-white/80 border-gray-300"
                            }`}
                          >
                            {selectedPeople.includes(person.id) && (
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
                      <span className="mt-3 text-sm font-medium text-gray-700 dark:text-gray-300 text-center max-w-[128px] truncate">
                        {person.name}
                      </span>
                      {person.photoCount > 0 && (
                        <span className="text-xs text-gray-500 dark:text-gray-400">
                          {person.photoCount} photos
                        </span>
                      )}
                    </div>
                  ) : (
                    <Link
                      href={`/explore/people/${person.id}`}
                      className="flex flex-col items-center"
                    >
                      <div className="w-32 h-32 rounded-2xl overflow-hidden ring-2 ring-gray-200 dark:ring-gray-700 group-hover:ring-blue-500 transition">
                        <Image
                          src={person.avatar}
                          alt={person.name}
                          width={128}
                          height={128}
                          className="w-full h-full object-cover"
                          unoptimized
                        />
                      </div>
                      <span className="mt-3 text-sm font-medium text-gray-700 dark:text-gray-300 text-center max-w-[128px] truncate">
                        {person.name}
                      </span>
                      {person.photoCount > 0 && (
                        <span className="text-xs text-gray-500 dark:text-gray-400">
                          {person.photoCount} photos
                        </span>
                      )}
                    </Link>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* No Results */}
          {!loading && !error && filteredPeople.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500 dark:text-gray-400">
                {searchQuery
                  ? `No people found matching "${searchQuery}"`
                  : "No people detected yet. Upload photos with faces to see them here!"}
              </p>
            </div>
          )}
        </div>
      </MainLayout>
    </ProtectedRoute>
  );
}
