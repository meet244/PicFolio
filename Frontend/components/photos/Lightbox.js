"use client";

import Link from "next/link";
import dynamic from "next/dynamic";
import { Dialog } from "@headlessui/react";
import { useEffect, useRef, useState, useCallback } from "react";
import { X, ChevronLeft, ChevronRight, Heart, Download, Info, Trash2, Edit3, UserPlus, UserMinus, ZoomIn, ZoomOut, Maximize2, Calendar, Camera, Image as ImageIcon, Upload, Cloud, MapPin, FileText } from "lucide-react";
import { API_ENDPOINTS } from "@/config/api";

const LocationMap = dynamic(() => import("./LocationMap"), {
  ssr: false,
});

export default function Lightbox({
  isOpen,
  onClose,
  photos = [],
  startIndex = 0,
  onToggleFavorite,
  favorites = [],
  currentUser,
  onDelete,
}) {
  const [index, setIndex] = useState(startIndex);
  const [showDetails, setShowDetails] = useState(false);
  const [details, setDetails] = useState(null);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const [isEditingFaces, setIsEditingFaces] = useState(false);
  const [allPeople, setAllPeople] = useState([]);
  const [loadingPeople, setLoadingPeople] = useState(false);
  const [isEditingDate, setIsEditingDate] = useState(false);
  const [editedDate, setEditedDate] = useState("");
  const [isLocationModalOpen, setIsLocationModalOpen] = useState(false);
  const [locationLat, setLocationLat] = useState("");
  const [locationLng, setLocationLng] = useState("");
  const [savingLocation, setSavingLocation] = useState(false);
  const containerRef = useRef(null);
  const imageRef = useRef(null);

  // Parse date from API format (DD-MM-YYYY or YYYY-MM-DD)
  const parseDate = (dateString) => {
    if (!dateString) return null;
    try {
      // Check if it's DD-MM-YYYY format (from API)
      if (dateString.includes("-") && dateString.split("-")[0].length === 2) {
        const [day, month, year] = dateString.split("-");
        return new Date(`${year}-${month}-${day}T00:00:00`);
      }
      // Otherwise try standard format
      return new Date(dateString + "T00:00:00");
    } catch {
      return null;
    }
  };

  // Format date for display (e.g., "Oct 28, 2023")
  const formatDateDisplay = (dateString) => {
    try {
      const date = parseDate(dateString);
      if (!date || isNaN(date.getTime())) return dateString;
      return date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      });
    } catch {
      return dateString;
    }
  };

  // Format date and time for display (e.g., "Sat, 8:48 PM")
  const formatDateTimeDisplay = (dateString, timeString) => {
    try {
      if (!dateString) return timeString || "";
      const date = parseDate(dateString);
      if (!date || isNaN(date.getTime())) return timeString || "";
      
      const dayName = date.toLocaleDateString("en-US", { weekday: "short" });
      // Format time from "09:33 AM" format or parse it
      let formattedTime = timeString;
      if (timeString && !timeString.includes("AM") && !timeString.includes("PM")) {
        // If time is in 24h format, convert it
        const [hours, minutes] = timeString.split(":");
        const hour24 = parseInt(hours);
        const ampm = hour24 >= 12 ? "PM" : "AM";
        const hour12 = hour24 % 12 || 12;
        formattedTime = `${hour12}:${minutes} ${ampm}`;
      }
      return `${dayName}, ${formattedTime}`;
    } catch {
      return timeString || "";
    }
  };

  // Convert date to YYYY-MM-DD format for editing
  const convertDateToInputFormat = (dateString) => {
    try {
      const date = parseDate(dateString);
      if (!date || isNaN(date.getTime())) return "";
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, "0");
      const day = String(date.getDate()).padStart(2, "0");
      return `${year}-${month}-${day}`;
    } catch {
      return "";
    }
  };
  const lastFetchedPhotoIdRef = useRef(null);
  const isFetchingRef = useRef(false);
  
  // Zoom and pan states
  const [scale, setScale] = useState(1);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

  useEffect(() => {
    if (isOpen) {
      setIndex(startIndex);
      setShowDetails(false);
      setDetails(null);
      // Reset zoom when opening lightbox
      setScale(1);
      setPosition({ x: 0, y: 0 });
      // Reset fetch tracking when lightbox opens
      lastFetchedPhotoIdRef.current = null;
      isFetchingRef.current = false;
    }
  }, [isOpen, startIndex]);

  // Reset zoom when changing photos
  useEffect(() => {
    setScale(1);
    setPosition({ x: 0, y: 0 });
  }, [index]);

  const fetchPhotoDetails = useCallback(async (force = false) => {
    if (!currentUser || !photos[index]) return;

    const photoId = photos[index].id;

    // Prevent duplicate calls - check if already fetching or if we already fetched this photo
    if (!force && (isFetchingRef.current || lastFetchedPhotoIdRef.current === photoId)) {
      return;
    }

    try {
      isFetchingRef.current = true;
      setLoadingDetails(true);
      const response = await fetch(
        API_ENDPOINTS.getAssetDetails(currentUser, photoId)
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setDetails(data);
      lastFetchedPhotoIdRef.current = photoId;
    } catch (error) {
      console.error("Error fetching photo details:", error);
      setDetails(null);
      lastFetchedPhotoIdRef.current = null;
    } finally {
      setLoadingDetails(false);
      isFetchingRef.current = false;
    }
  }, [currentUser, photos, index]);

  // Reset last fetched photo ID when index changes
  useEffect(() => {
    lastFetchedPhotoIdRef.current = null;
  }, [index]);

  // Fetch details when photo changes and details panel is open
  useEffect(() => {
    if (showDetails && currentUser && photos[index]) {
      fetchPhotoDetails();
    }
  }, [index, showDetails, currentUser, photos, fetchPhotoDetails]);

  const handleDetailsClick = () => {
    if (!showDetails) {
      setShowDetails(true);
      // fetchPhotoDetails will be called automatically by useEffect when showDetails changes
    } else {
      setShowDetails(false);
      setIsEditingFaces(false);
    }
  };

  const fetchAllPeople = useCallback(async () => {
    if (!currentUser || loadingPeople) return;

    try {
      setLoadingPeople(true);
      const formData = new FormData();
      formData.append("username", currentUser);

      const response = await fetch(API_ENDPOINTS.getFacesList(), {
        method: "POST",
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        const peopleList = data.map(([faceId, name]) => ({
          id: faceId.toString(),
          name: name,
        }));
        setAllPeople(peopleList);
      }
    } catch (error) {
      console.error("Error fetching people:", error);
    } finally {
      setLoadingPeople(false);
    }
  }, [currentUser, loadingPeople]);

  const handleRemoveFace = async (faceId) => {
    if (!currentUser || !photos[index]) return;

    if (!window.confirm("Remove this face from the photo?")) {
      return;
    }

    try {
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("asset_id", photos[index].id);
      formData.append("face_id", faceId.toString());

      const response = await fetch(API_ENDPOINTS.removeFaceFromPhoto(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error("Failed to remove face");
      }

      // Refresh details
      await fetchPhotoDetails(true);
    } catch (error) {
      console.error("Error removing face:", error);
      alert("Failed to remove face. Please try again.");
    }
  };

  const handleAddFace = async (faceId) => {
    if (!currentUser || !photos[index]) return;

    try {
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("asset_id", photos[index].id);
      formData.append("face_id", faceId.toString());

      const response = await fetch(API_ENDPOINTS.addFaceToPhoto(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error("Failed to add face");
      }

      // Refresh details
      await fetchPhotoDetails(true);
    } catch (error) {
      console.error("Error adding face:", error);
      alert("Failed to add face. Please try again.");
    }
  };

  const handleEditFacesClick = () => {
    if (!isEditingFaces) {
      fetchAllPeople();
    }
    setIsEditingFaces(!isEditingFaces);
  };

  const handleDateClick = () => {
    if (!isEditingDate && details?.date) {
      // Convert API date format (DD-MM-YYYY) to input format (YYYY-MM-DD)
      const inputFormat = convertDateToInputFormat(details.date);
      setEditedDate(inputFormat);
    }
    setIsEditingDate(!isEditingDate);
  };

  const handleSaveDate = async () => {
    if (!currentUser || !photos[index] || !editedDate) return;

    try {
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("id", photos[index].id);
      formData.append("date", editedDate);

      const response = await fetch(API_ENDPOINTS.redateAssets(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error("Failed to change date");
      }

      const result = await response.json();
      if (result === "Date changed successfully") {
        // Refresh details
        await fetchPhotoDetails(true);
        setIsEditingDate(false);
      } else {
        throw new Error(result);
      }
    } catch (error) {
      console.error("Error changing date:", error);
      alert("Failed to change date. Please try again.");
    }
  };

  // Wheel zoom handler
  const handleWheel = useCallback((e) => {
    const currentPhoto = photos[index];
    if (currentPhoto && !currentPhoto.isVideo) {
      e.preventDefault();
      const delta = e.deltaY * -0.01;
      const newScale = Math.min(Math.max(1, scale + delta), 5);
      setScale(newScale);
      
      // Reset position if zooming out to 1x
      if (newScale === 1) {
        setPosition({ x: 0, y: 0 });
      }
    }
  }, [scale, photos, index]);

  // Double click to zoom
  const handleDoubleClick = useCallback(() => {
    const currentPhoto = photos[index];
    if (currentPhoto && !currentPhoto.isVideo) {
      if (scale === 1) {
        setScale(2);
      } else {
        setScale(1);
        setPosition({ x: 0, y: 0 });
      }
    }
  }, [scale, photos, index]);

  // Mouse drag handlers
  const handleMouseDown = useCallback((e) => {
    const currentPhoto = photos[index];
    if (scale > 1 && currentPhoto && !currentPhoto.isVideo) {
      setIsDragging(true);
      setDragStart({ x: e.clientX - position.x, y: e.clientY - position.y });
    }
  }, [scale, position, photos, index]);

  const handleMouseMove = useCallback((e) => {
    if (isDragging && scale > 1) {
      setPosition({
        x: e.clientX - dragStart.x,
        y: e.clientY - dragStart.y,
      });
    }
  }, [isDragging, dragStart, scale]);

  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
  }, []);

  // Touch handlers for mobile pinch zoom
  const touchStartRef = useRef({ dist: 0, scale: 1 });

  const handleTouchStart = useCallback((e) => {
    const currentPhoto = photos[index];
    if (e.touches.length === 2 && currentPhoto && !currentPhoto.isVideo) {
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      const dist = Math.hypot(
        touch2.clientX - touch1.clientX,
        touch2.clientY - touch1.clientY
      );
      touchStartRef.current = { dist, scale };
    }
  }, [scale, photos, index]);

  const handleTouchMove = useCallback((e) => {
    const currentPhoto = photos[index];
    if (e.touches.length === 2 && currentPhoto && !currentPhoto.isVideo) {
      e.preventDefault();
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      const dist = Math.hypot(
        touch2.clientX - touch1.clientX,
        touch2.clientY - touch1.clientY
      );
      
      const newScale = Math.min(
        Math.max(1, touchStartRef.current.scale * (dist / touchStartRef.current.dist)),
        5
      );
      setScale(newScale);
      
      if (newScale === 1) {
        setPosition({ x: 0, y: 0 });
      }
    }
  }, [photos, index]);

  useEffect(() => {
    function onKey(e) {
      if (e.key === "Escape") onClose();
      if (e.key === "ArrowRight")
        setIndex((i) => Math.min(i + 1, photos.length - 1));
      if (e.key === "ArrowLeft") setIndex((i) => Math.max(i - 1, 0));
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose, photos.length]);

  if (!isOpen || photos.length === 0) return null;
  const photo = photos[index];
  
  // Safety check for when photos array changes but index hasn't updated yet
  if (!photo) return null;

  const isFav = favorites.includes(photo.id);

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/90" aria-hidden="true" />

      <div
        className="fixed inset-0 flex items-center justify-center p-4"
        ref={containerRef}
      >
        <Dialog.Panel className="w-full h-full max-w-7xl max-h-[95vh] flex flex-col">
          <div className="flex items-center justify-between p-3 text-white bg-black/50">
            <div className="text-sm opacity-75">{photo.title}</div>
            <div className="flex items-center gap-2">
              <button
                onClick={handleDetailsClick}
                className={`p-2 rounded bg-white/10 hover:bg-white/20 ${
                  showDetails ? "bg-white/20" : ""
                }`}
                aria-label="Details"
              >
                <Info className="w-5 h-5" />
              </button>
              <button
                onClick={() => onToggleFavorite(photo.id)}
                className={`p-2 rounded bg-white/10 hover:bg-white/20 ${
                  isFav ? "text-red-400" : "text-white"
                }`}
                aria-label="Favorite"
              >
                <Heart
                  className="w-5 h-5"
                  fill={isFav ? "currentColor" : "none"}
                />
              </button>
              <button
                onClick={() => {
                  if (!currentUser) return;
                  const downloadUrl = API_ENDPOINTS.getMaster(currentUser, photo.id);
                  const link = document.createElement('a');
                  link.href = downloadUrl;
                  link.download = `photo-${photo.id}`;
                  link.target = '_blank';
                  document.body.appendChild(link);
                  link.click();
                  document.body.removeChild(link);
                }}
                className="p-2 rounded bg-white/10 hover:bg-white/20"
                aria-label="Download"
              >
                <Download className="w-5 h-5" />
              </button>
              {onDelete && (
                <button
                  onClick={() => onDelete(photo.id)}
                  className="p-2 rounded bg-white/10 hover:bg-red-500/50"
                  aria-label="Delete"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              )}
              <button
                onClick={onClose}
                className="p-2 rounded bg-white/10 hover:bg-white/20"
                aria-label="Close"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          <div className="flex-1 relative select-none flex overflow-hidden">
            <div 
              className={`flex-1 ${showDetails ? "mr-80" : ""} transition-all duration-300 flex items-center justify-center p-4 overflow-hidden`}
              onWheel={handleWheel}
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
              onTouchStart={handleTouchStart}
              onTouchMove={handleTouchMove}
              style={{ cursor: scale > 1 && !photo.isVideo ? (isDragging ? 'grabbing' : 'grab') : 'default' }}
            >
              {photo.isVideo ? (
                <video
                  src={currentUser ? API_ENDPOINTS.getMaster(currentUser, photo.id) : photo.url}
                  poster={photo.url}
                  className="max-w-full max-h-full object-contain"
                  controls
                  autoPlay
                  playsInline
                  style={{ maxHeight: 'calc(95vh - 80px)' }}
                >
                  Your browser does not support the video tag.
                </video>
              ) : (
                <img
                  ref={imageRef}
                  src={currentUser ? API_ENDPOINTS.getMaster(currentUser, photo.id) : photo.url}
                  alt={photo.title || "Photo"}
                  className="max-w-full max-h-full object-contain transition-transform duration-200"
                  style={{ 
                    maxHeight: 'calc(95vh - 80px)',
                    transform: `scale(${scale}) translate(${position.x / scale}px, ${position.y / scale}px)`,
                    transformOrigin: 'center center',
                  }}
                  draggable={false}
                  onDoubleClick={handleDoubleClick}
                />
              )}

              {/* Zoom Controls */}
              {!photo.isVideo && (
                <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex items-center gap-2 bg-black/70 rounded-lg px-3 py-2 text-white">
                  <button
                    onClick={() => {
                      const newScale = Math.max(1, scale - 0.5);
                      setScale(newScale);
                      if (newScale === 1) setPosition({ x: 0, y: 0 });
                    }}
                    disabled={scale <= 1}
                    className="p-1 rounded hover:bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed"
                    aria-label="Zoom out"
                  >
                    <ZoomOut className="w-4 h-4" />
                  </button>
                  <span className="text-sm font-medium min-w-[3rem] text-center">
                    {Math.round(scale * 100)}%
                  </span>
                  <button
                    onClick={() => setScale(Math.min(5, scale + 0.5))}
                    disabled={scale >= 5}
                    className="p-1 rounded hover:bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed"
                    aria-label="Zoom in"
                  >
                    <ZoomIn className="w-4 h-4" />
                  </button>
                  {scale > 1 && (
                    <button
                      onClick={() => {
                        setScale(1);
                        setPosition({ x: 0, y: 0 });
                      }}
                      className="p-1 rounded hover:bg-white/20 ml-1"
                      aria-label="Reset zoom"
                    >
                      <Maximize2 className="w-4 h-4" />
                    </button>
                  )}
                </div>
              )}

              {/* Navigation */}
              {index > 0 && (
                <button
                  onClick={() => setIndex((i) => Math.max(i - 1, 0))}
                  className="absolute left-2 top-1/2 -translate-y-1/2 p-2 rounded bg-white/10 hover:bg-white/20 text-white"
                  aria-label="Previous"
                >
                  <ChevronLeft className="w-6 h-6" />
                </button>
              )}
              {index < photos.length - 1 && (
                <button
                  onClick={() =>
                    setIndex((i) => Math.min(i + 1, photos.length - 1))
                  }
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-2 rounded bg-white/10 hover:bg-white/20 text-white"
                  aria-label="Next"
                >
                  <ChevronRight className="w-6 h-6" />
                </button>
              )}
            </div>

            {/* Details Panel */}
            {showDetails && (
              <div className="absolute right-0 top-0 bottom-0 w-80 bg-gray-900 text-white overflow-y-auto">
                {/* Header */}
                <div className="sticky top-0 bg-gray-900 z-10 border-b border-gray-700">
                  <div className="flex items-center justify-between p-4">
                    <button
                      onClick={() => setShowDetails(false)}
                      className="p-1.5 rounded hover:bg-gray-800 transition-colors"
                      aria-label="Close Details"
                    >
                      <X className="w-5 h-5" />
                    </button>
                    <h2 className="text-lg font-semibold">Info</h2>
                    <div className="w-9"></div> {/* Spacer for centering */}
                  </div>
                </div>

                <div className="p-4 space-y-6">
                  {loadingDetails ? (
                    <div className="flex items-center justify-center py-12">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
                    </div>
                  ) : details ? (
                    <>
                      {/* Description Field */}
                      <div className="border-b border-gray-700 pb-4">
                        <div className="flex items-center justify-between mb-2">
                          <label className="text-sm text-gray-400">Add a description</label>
                          <button
                            className="p-1 rounded hover:bg-gray-800 text-gray-400 hover:text-white transition"
                            title="Edit description"
                          >
                            <Edit3 className="w-4 h-4" />
                          </button>
                        </div>
                        <div className="border-b border-gray-600 pb-1">
                          <input
                            type="text"
                            placeholder="Add a description"
                            className="w-full bg-transparent text-white placeholder-gray-500 focus:outline-none text-sm"
                          />
                        </div>
                      </div>

                      {/* People Section */}
                      <div>
                        <div className="flex items-center justify-between mb-3">
                          <h3 className="text-base font-medium">People</h3>
                          <button
                            onClick={handleEditFacesClick}
                            className="p-1 rounded hover:bg-gray-800 text-gray-400 hover:text-white transition"
                            title="Edit people"
                          >
                            <Edit3 className="w-4 h-4" />
                          </button>
                        </div>
                        {!isEditingFaces ? (
                          <div className="space-y-3">
                            {details.faces && details.faces.length > 0 ? (
                              details.faces.map((face, idx) => (
                                <Link
                                  key={idx}
                                  href={face[0] ? `/explore/people/${face[0]}` : "#"}
                                  className={`flex items-center gap-3 group ${
                                    face[0] ? "cursor-pointer" : ""
                                  }`}
                                >
                                  {face[0] && currentUser ? (
                                    <img
                                      src={`${API_ENDPOINTS.getFaceImage(currentUser, face[0])}`}
                                      alt={face[1]}
                                      className="w-12 h-12 rounded-lg object-cover ring-1 ring-gray-700 group-hover:ring-gray-600 transition-all"
                                    />
                                  ) : (
                                    <div className="w-12 h-12 rounded-lg bg-gray-800 flex items-center justify-center">
                                      <span className="text-xs text-gray-400">?</span>
                                    </div>
                                  )}
                                  <p className="text-sm text-white font-medium group-hover:text-blue-400 transition-colors">
                                    {face[1]}
                                  </p>
                                </Link>
                              ))
                            ) : (
                              <p className="text-sm text-gray-500">No people detected</p>
                            )}
                          </div>
                        ) : (
                          <div className="space-y-3">
                            {details.faces && details.faces.length > 0 && (
                              <div>
                                <p className="text-xs text-gray-400 mb-2">Current People</p>
                                <div className="space-y-2">
                                  {details.faces.map((face, idx) => (
                                    <div
                                      key={idx}
                                      className="flex items-center gap-3 bg-gray-800/50 px-3 py-2 rounded-lg"
                                    >
                                      {face[0] && currentUser ? (
                                        <img
                                          src={`${API_ENDPOINTS.getFaceImage(currentUser, face[0])}`}
                                          alt={face[1]}
                                          className="w-10 h-10 rounded-lg object-cover"
                                        />
                                      ) : (
                                        <div className="w-10 h-10 rounded-lg bg-gray-700 flex items-center justify-center">
                                          <span className="text-xs text-gray-400">?</span>
                                        </div>
                                      )}
                                      <div className="flex-1 min-w-0">
                                        <p className="text-sm text-white font-medium truncate">
                                          {face[1]}
                                        </p>
                                      </div>
                                      {face[0] && (
                                        <button
                                          onClick={() => handleRemoveFace(face[0])}
                                          className="p-1.5 rounded bg-red-500/20 hover:bg-red-500/30 text-red-400 transition"
                                          title="Remove person"
                                        >
                                          <UserMinus className="w-4 h-4" />
                                        </button>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                            <div>
                              <p className="text-xs text-gray-400 mb-2">Add Person</p>
                              {loadingPeople ? (
                                <div className="text-center py-4">
                                  <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white mx-auto"></div>
                                </div>
                              ) : (
                                <div className="space-y-2 max-h-48 overflow-y-auto">
                                  {allPeople
                                    .filter(
                                      (person) =>
                                        !details.faces?.some((f) => f[0] === parseInt(person.id))
                                    )
                                    .map((person) => (
                                      <button
                                        key={person.id}
                                        onClick={() => handleAddFace(person.id)}
                                        className="w-full flex items-center gap-3 bg-gray-800/30 hover:bg-gray-800/50 px-3 py-2 rounded-lg transition"
                                      >
                                        <img
                                          src={`${API_ENDPOINTS.getFaceImage(currentUser, person.id)}`}
                                          alt={person.name}
                                          className="w-10 h-10 rounded-lg object-cover"
                                        />
                                        <div className="flex-1 min-w-0 text-left">
                                          <p className="text-sm text-white font-medium truncate">
                                            {person.name}
                                          </p>
                                        </div>
                                        <UserPlus className="w-4 h-4 text-green-400" />
                                      </button>
                                    ))}
                                  {allPeople.filter(
                                    (person) =>
                                      !details.faces?.some((f) => f[0] === parseInt(person.id))
                                  ).length === 0 && (
                                    <p className="text-xs text-gray-500 text-center py-4">
                                      All people are already in this photo
                                    </p>
                                  )}
                                </div>
                              )}
                            </div>
                          </div>
                        )}
                      </div>

                      {/* Details Section */}
                      <div>
                        <h3 className="text-base font-medium mb-4">Details</h3>
                        <div className="space-y-4">
                          {/* Date and Time */}
                          <div>
                            <div className="flex items-start gap-3">
                              <Calendar className="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0" />
                              <div className="flex-1">
                                <div className="flex items-center justify-between">
                                  <div>
                                    {isEditingDate ? (
                                      <div className="flex items-center gap-2">
                                        <input
                                          type="date"
                                          value={editedDate}
                                          onChange={(e) => setEditedDate(e.target.value)}
                                          className="px-2 py-1 rounded bg-gray-800 text-white border border-gray-600 focus:outline-none focus:border-blue-500 text-sm"
                                          onClick={(e) => e.target.showPicker && e.target.showPicker()}
                                        />
                                        <button
                                          onClick={handleSaveDate}
                                          className="px-2 py-1 rounded bg-green-600 hover:bg-green-700 text-white text-xs"
                                        >
                                          Save
                                        </button>
                                        <button
                                          onClick={() => {
                                            setIsEditingDate(false);
                                            setEditedDate("");
                                          }}
                                          className="px-2 py-1 rounded bg-gray-600 hover:bg-gray-700 text-white text-xs"
                                        >
                                          Cancel
                                        </button>
                                      </div>
                                    ) : (
                                      <div>
                                        <p className="text-sm text-white font-medium cursor-pointer hover:text-blue-400" onClick={handleDateClick}>
                                          {details.date ? formatDateDisplay(details.date) : "N/A"}
                                        </p>
                                        {details.time && (
                                          <p className="text-xs text-gray-400 mt-1">
                                            {formatDateTimeDisplay(details.date, details.time)}
                                          </p>
                                        )}
                                      </div>
                                    )}
                                  </div>
                                  {!isEditingDate && (
                                    <button
                                      onClick={handleDateClick}
                                      className="p-1 rounded hover:bg-gray-800 text-gray-400 hover:text-white transition"
                                      title="Edit date"
                                    >
                                      <Edit3 className="w-4 h-4" />
                                    </button>
                                  )}
                                </div>
                              </div>
                            </div>
                          </div>

      {/* Location Modal */}
      {isLocationModalOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/70">
          <div className="bg-gray-900 rounded-xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between px-4 py-3 border-b border-gray-700">
              <h3 className="text-lg font-semibold text-white">
                {details?.location ? "Edit location" : "Add location"}
              </h3>
              <button
                type="button"
                onClick={() => setIsLocationModalOpen(false)}
                className="p-1.5 rounded hover:bg-gray-800 text-gray-300"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Map picker using Leaflet */}
            <div className="px-4 py-4 space-y-4">
              <p className="text-sm text-gray-300">
                Click on the map to drop a pin where this photo was taken.
              </p>
              <div className="w-full h-64 rounded-lg overflow-hidden border border-gray-700">
                <LocationMap
                  lat={locationLat ? parseFloat(locationLat) : undefined}
                  lng={locationLng ? parseFloat(locationLng) : undefined}
                  onChange={(pos) => {
                    if (!pos) return;
                    setLocationLat(pos.lat.toFixed(5));
                    setLocationLng(pos.lng.toFixed(5));
                  }}
                />
              </div>

              <div className="flex items-center justify-between text-xs text-gray-300">
                <div>
                  <span className="mr-4">
                    Latitude:{" "}
                    {locationLat ? locationLat : "—"}
                  </span>
                  <span>
                    Longitude:{" "}
                    {locationLng ? locationLng : "—"}
                  </span>
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-2 px-4 pb-4">
              <button
                type="button"
                className="px-3 py-1.5 rounded-lg bg-gray-700 hover:bg-gray-600 text-sm text-white"
                onClick={() => setIsLocationModalOpen(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={
                  savingLocation ||
                  !locationLat ||
                  !locationLng
                }
                className="px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-700 disabled:bg-blue-900 disabled:cursor-not-allowed text-sm text-white"
                onClick={async () => {
                  if (!currentUser || !photos[index]) return;

                  try {
                    setSavingLocation(true);
                    const formData = new FormData();
                    formData.append("username", currentUser);
                    formData.append("asset_id", photos[index].id);
                    formData.append("latitude", String(locationLat));
                    formData.append("longitude", String(locationLng));

                    const response = await fetch(API_ENDPOINTS.updateLocation(), {
                      method: "POST",
                      body: formData,
                    });

                    if (!response.ok) {
                      throw new Error(await response.text());
                    }

                    const result = await response.json();
                    if (result !== "Location changed successfully") {
                      console.warn("Unexpected location response:", result);
                    }

                    await fetchPhotoDetails(true);
                    setIsLocationModalOpen(false);
                  } catch (error) {
                    console.error("Failed to update location:", error);
                    alert("Failed to update location. Please try again.");
                  } finally {
                    setSavingLocation(false);
                  }
                }}
              >
                {savingLocation ? "Saving..." : "Save"}
              </button>
            </div>
          </div>
        </div>
      )}

                          {/* Camera Information - Show if we have format or dimensions */}
                          {(details.format || (details.width && details.height)) && (
                            <div>
                              <div className="flex items-start gap-3">
                                <Camera className="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0" />
                                <div className="flex-1">
                                  <p className="text-sm text-white font-medium">
                                    {details.format ? details.format.toUpperCase() : "Unknown format"}
                                  </p>
                                  {details.width && details.height && (
                                    <p className="text-xs text-gray-400 mt-1">
                                      {details.width} × {details.height}
                                    </p>
                                  )}
                                </div>
                              </div>
                            </div>
                          )}

                          {/* File Information */}
                          <div>
                            <div className="flex items-start gap-3">
                              <ImageIcon className="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0" />
                              <div className="flex-1">
                                <p className="text-sm text-white font-medium">
                                  {details.name || "Unknown file"}
                                </p>
                                <div className="flex items-center gap-2 mt-1">
                                  {details.mp && (
                                    <span className="text-xs text-gray-400">{details.mp}</span>
                                  )}
                                  {details.width && details.height && (
                                    <>
                                      {details.mp && <span className="text-xs text-gray-500">•</span>}
                                      <span className="text-xs text-gray-400">
                                        {details.width} × {details.height}
                                      </span>
                                    </>
                                  )}
                                </div>
                              </div>
                            </div>
                          </div>

                          {/* Upload Source */}
                          <div>
                            <div className="flex items-start gap-3">
                              <Upload className="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0" />
                              <div className="flex-1">
                                <p className="text-sm text-white font-medium">Uploaded from web browser</p>
                              </div>
                            </div>
                          </div>

                          {/* Backup Status */}
                          {details.size && (
                            <div>
                              <div className="flex items-start gap-3">
                                <Cloud className="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0" />
                                <div className="flex-1">
                                  <p className="text-sm text-white font-medium">Backed up ({details.size})</p>
                                  <p className="text-xs text-gray-400 mt-1">
                                    {details.compress ? "Storage saver" : "Original quality"}
                                  </p>
                                </div>
                              </div>
                            </div>
                          )}

                          {/* Location */}
                          <div>
                            <div className="flex items-start gap-3">
                              <MapPin className="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0" />
                              <div className="flex-1">
                                <div className="flex items-center justify-between">
                                  <button
                                    type="button"
                                    onClick={() => {
                                      const loc = details.location;
                                      if (loc && typeof loc === "object") {
                                        if (typeof loc.latitude === "number") {
                                          setLocationLat(loc.latitude.toString());
                                        }
                                        if (typeof loc.longitude === "number") {
                                          setLocationLng(loc.longitude.toString());
                                        }
                                      } else {
                                        setLocationLat("");
                                        setLocationLng("");
                                      }
                                      setIsLocationModalOpen(true);
                                    }}
                                    className="text-left text-sm text-white font-medium cursor-pointer hover:text-blue-400"
                                  >
                                    {details.location && typeof details.location === "object"
                                      ? `Lat ${details.location.latitude.toFixed(4)}, Lng ${details.location.longitude.toFixed(4)}`
                                      : "Add a location"}
                                  </button>
                                  <button
                                    type="button"
                                    onClick={() => {
                                      const loc = details.location;
                                      if (loc && typeof loc === "object") {
                                        if (typeof loc.latitude === "number") {
                                          setLocationLat(loc.latitude.toString());
                                        }
                                        if (typeof loc.longitude === "number") {
                                          setLocationLng(loc.longitude.toString());
                                        }
                                      } else {
                                        setLocationLat("");
                                        setLocationLng("");
                                      }
                                      setIsLocationModalOpen(true);
                                    }}
                                    className="p-1 rounded hover:bg-gray-800 text-gray-400 hover:text-white transition"
                                    title={details.location ? "Edit location" : "Add location"}
                                  >
                                    <Edit3 className="w-4 h-4" />
                                  </button>
                                </div>

                                {details.location &&
                                  typeof details.location === "object" &&
                                  typeof details.location.latitude === "number" &&
                                  typeof details.location.longitude === "number" && (
                                    <div className="mt-3 h-32 rounded-lg overflow-hidden border border-gray-700">
                                      <LocationMap
                                        lat={details.location.latitude}
                                        lng={details.location.longitude}
                                        onChange={() => {}}
                                      />
                                    </div>
                                  )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Tags Section */}
                      {details.tags && details.tags.length > 0 && (
                        <div>
                          <h3 className="text-base font-medium mb-3">Tags</h3>
                          <div className="flex flex-wrap gap-2">
                            {details.tags.map((tag, idx) => (
                              <span
                                key={idx}
                                className="px-2.5 py-1 bg-gray-800 rounded-md text-xs text-gray-300"
                              >
                                {tag}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}

                      <div>
                        <div className="flex items-center justify-between mb-2">
                          <label className="text-sm text-gray-400">Faces</label>
                          <button
                            onClick={handleEditFacesClick}
                            className="p-1 rounded hover:bg-white/10 text-gray-400 hover:text-white transition"
                            title="Edit faces"
                          >
                            <Edit3 className="w-4 h-4" />
                          </button>
                        </div>

                            {!isEditingFaces ? (
                              <div className="mt-2 space-y-2">
                                {details.faces && details.faces.length > 0 ? (
                                  details.faces.map((face, idx) => (
                                    <Link
                                      key={idx}
                                      href={face[0] ? `/explore/people/${face[0]}` : "#"}
                                      className={`flex items-center gap-3 bg-white/10 px-3 py-3 rounded group transition-colors ${
                                        face[0] ? "hover:bg-white/20 cursor-pointer" : ""
                                      }`}
                                    >
                                      {face[0] && currentUser ? (
                                        <img
                                          src={`${API_ENDPOINTS.getFaceImage(currentUser, face[0])}`}
                                          alt={face[1]}
                                          className="w-16 h-16 rounded-full object-cover ring-2 ring-white/20 group-hover:ring-white/40 transition-all"
                                        />
                                      ) : (
                                        <div className="w-16 h-16 rounded-full bg-gray-600 flex items-center justify-center">
                                          <span className="text-sm text-gray-300">?</span>
                                        </div>
                                      )}
                                      <div className="flex-1">
                                        <p className="text-base text-white font-medium group-hover:text-blue-300 transition-colors">
                                          {face[1]}
                                        </p>
                                        {face[0] && (
                                          <p className="text-xs text-gray-400">
                                            ID: {face[0]}
                                          </p>
                                        )}
                                      </div>
                                    </Link>
                                  ))
                                ) : (
                                  <span className="text-gray-500">No faces detected</span>
                                )}
                              </div>
                            ) : (
                          <div className="mt-2 space-y-3">
                            {/* Current Faces */}
                            {details.faces && details.faces.length > 0 && (
                              <div>
                                <p className="text-xs text-gray-400 mb-2">Current Faces</p>
                                <div className="space-y-2">
                                  {details.faces.map((face, idx) => (
                                    <div
                                      key={idx}
                                      className="flex items-center gap-3 bg-white/10 px-3 py-2 rounded"
                                    >
                                      {face[0] && currentUser ? (
                                        <img
                                          src={`${API_ENDPOINTS.getFaceImage(currentUser, face[0])}`}
                                          alt={face[1]}
                                          className="w-12 h-12 rounded-full object-cover"
                                        />
                                      ) : (
                                        <div className="w-12 h-12 rounded-full bg-gray-600 flex items-center justify-center">
                                          <span className="text-xs text-gray-300">?</span>
                                        </div>
                                      )}
                                      <div className="flex-1 min-w-0">
                                        <p className="text-sm text-white font-medium truncate">
                                          {face[1]}
                                        </p>
                                      </div>
                                      {face[0] && (
                                        <button
                                          onClick={() => handleRemoveFace(face[0])}
                                          className="p-1 rounded bg-red-500/20 hover:bg-red-500/40 text-red-400"
                                          title="Remove face"
                                        >
                                          <UserMinus className="w-4 h-4" />
                                        </button>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}

                            {/* Add Face */}
                            <div>
                              <p className="text-xs text-gray-400 mb-2">Add Person</p>
                              {loadingPeople ? (
                                <div className="text-center py-4">
                                  <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white mx-auto"></div>
                                </div>
                              ) : (
                                <div className="space-y-2 max-h-48 overflow-y-auto">
                                  {allPeople
                                    .filter(
                                      (person) =>
                                        !details.faces?.some((f) => f[0] === parseInt(person.id))
                                    )
                                    .map((person) => (
                                      <button
                                        key={person.id}
                                        onClick={() => handleAddFace(person.id)}
                                        className="w-full flex items-center gap-3 bg-white/5 hover:bg-white/10 px-3 py-2 rounded transition"
                                      >
                                        <img
                                          src={`${API_ENDPOINTS.getFaceImage(currentUser, person.id)}`}
                                          alt={person.name}
                                          className="w-10 h-10 rounded-full object-cover"
                                        />
                                        <div className="flex-1 min-w-0 text-left">
                                          <p className="text-sm text-white font-medium truncate">
                                            {person.name}
                                          </p>
                                        </div>
                                        <UserPlus className="w-4 h-4 text-green-400" />
                                      </button>
                                    ))}
                                  {allPeople.filter(
                                    (person) =>
                                      !details.faces?.some((f) => f[0] === parseInt(person.id))
                                  ).length === 0 && (
                                    <p className="text-xs text-gray-500 text-center py-4">
                                      All people are already in this photo
                                    </p>
                                  )}
                                </div>
                              )}
                            </div>
                          </div>
                        )}
                      </div>

                      {/* OCR Text */}
                      {details.ocr_text && (
                        <div>
                          <h3 className="text-base font-medium mb-3">Text</h3>
                          <div className="bg-gray-800/50 rounded-lg p-3">
                            <p className="text-sm text-gray-300 whitespace-pre-wrap">
                              {details.ocr_text}
                            </p>
                          </div>
                        </div>
                      )}
                    </>
                  ) : (
                    <div className="text-center py-12 text-gray-400">
                      <p className="text-sm">Failed to load details</p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}
