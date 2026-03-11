"use client";
import { useState, useEffect, useCallback, useRef } from "react";
import MainLayout from "@/components/layout/MainLayout";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { API_ENDPOINTS } from "@/config/api";
import { Check, X, HelpCircle, UserCheck } from "lucide-react";

// Component to display the cropped face
const FaceCrop = ({ src, x, y, w, h, className }) => {
  const canvasRef = useRef(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!x || !y || !w || !h || !src) return;

    const img = new Image();
    img.crossOrigin = "anonymous";
    img.onload = () => {
      const canvas = canvasRef.current;
      if (!canvas) return;

      const ctx = canvas.getContext("2d");
      canvas.width = w;
      canvas.height = h;

      // Draw the cropped portion of the image
      ctx.drawImage(img, x, y, w, h, 0, 0, w, h);
      setLoading(false);
    };
    img.onerror = () => {
      setLoading(false);
    };
    img.src = src;
  }, [src, x, y, w, h]);

  if (!x || !y || !w || !h) {
    return (
      <div className={`overflow-hidden bg-gray-200 dark:bg-gray-700 ${className}`}>
        <img src={src} alt="Face" className="w-full h-full object-cover" />
      </div>
    );
  }

  return (
    <div className={`relative overflow-hidden bg-gray-200 dark:bg-gray-700 ${className}`}>
      {loading && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-gray-400"></div>
        </div>
      )}
      <canvas
        ref={canvasRef}
        className="w-full h-full object-cover"
        style={{ opacity: loading ? 0 : 1 }}
      />
    </div>
  );
};

export default function VerificationsPage() {
  const { currentUser } = useSession();
  const [verifications, setVerifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [currentIndex, setCurrentIndex] = useState(0);
  const [processing, setProcessing] = useState(false);
  const [imageDimensions, setImageDimensions] = useState(null);
  const imageRef = useRef(null);

  const handleMainImageLoad = (e) => {
    const updateDimensions = () => {
      if (imageRef.current) {
        setImageDimensions({
          width: imageRef.current.width,
          height: imageRef.current.height,
          naturalWidth: imageRef.current.naturalWidth,
          naturalHeight: imageRef.current.naturalHeight,
        });
      }
    };
    // Small delay to ensure image is properly rendered
    setTimeout(updateDimensions, 100);
  };

  // Update dimensions on resize and when current item changes
  useEffect(() => {
    const handleResize = () => {
      if (imageRef.current) {
        setImageDimensions({
          width: imageRef.current.width,
          height: imageRef.current.height,
          naturalWidth: imageRef.current.naturalWidth,
          naturalHeight: imageRef.current.naturalHeight,
        });
      }
    };
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  // Reset dimensions when switching items
  useEffect(() => {
    setImageDimensions(null);
  }, [currentIndex]);

  const fetchVerifications = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      const response = await fetch(
        API_ENDPOINTS.getPendingVerifications(currentUser)
      );

      if (!response.ok) {
        throw new Error("Failed to fetch verifications");
      }

      const data = await response.json();
      // API response format: [{ asset_id, face_id, person_name, box: { x, y, w, h }, created }, ...]
      const normalizedData = data.map((item) => {
        return {
          asset_id: item.asset_id,
          face_id: item.face_id,
          face_name: item.person_name,
          x: item.box.x,
          y: item.box.y,
          w: item.box.w,
          h: item.box.h,
        };
      });

      setVerifications(normalizedData);
      setCurrentIndex(0);
    } catch (error) {
      console.error("Error fetching verifications:", error);
      setError("Failed to load verifications. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  useEffect(() => {
    fetchVerifications();
  }, [fetchVerifications]);

  const handleVerification = async (status) => {
    if (!currentUser || verifications.length === 0) return;

    const currentItem = verifications[currentIndex];
    
    // If "Not Sure" (status === null), just move to next
    if (status === null) {
      setVerifications((prev) => prev.filter((_, i) => i !== currentIndex));
      if (currentIndex >= verifications.length - 1) {
        setCurrentIndex(0);
      }
      return;
    }

    try {
      setProcessing(true);
      const formData = new FormData();
      formData.append("username", currentUser);
      formData.append("asset_id", currentItem.asset_id);
      formData.append("face_id", currentItem.face_id);
      formData.append("status", status.toString());

      const response = await fetch(API_ENDPOINTS.updateVerification(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error("Failed to update verification");
      }

      // Remove the processed item from the list
      setVerifications((prev) => prev.filter((_, i) => i !== currentIndex));
      if (currentIndex >= verifications.length - 1) {
        setCurrentIndex(0);
      }
    } catch (error) {
      console.error("Error updating verification:", error);
      alert("Failed to update verification. Please try again.");
    } finally {
      setProcessing(false);
    }
  };

  const currentItem = verifications[currentIndex];

  // Calculate overlay style with proper image scaling
  const getOverlayStyle = () => {
    if (!currentItem || !imageDimensions || !currentItem.w || !imageRef.current) return {};
    
    const { x, y, w, h } = currentItem;
    const { width: displayWidth, height: displayHeight, naturalWidth, naturalHeight } = imageDimensions;
    
    // Calculate the actual scale factor (image might be scaled to fit container)
    const scaleX = displayWidth / naturalWidth;
    const scaleY = displayHeight / naturalHeight;
    
    // Get the image's position in the container (for object-contain centering)
    const img = imageRef.current;
    const container = img.parentElement;
    
    const containerWidth = container.offsetWidth;
    const containerHeight = container.offsetHeight;
    
    // Calculate offset if image is centered
    const offsetX = (containerWidth - displayWidth) / 2;
    const offsetY = (containerHeight - displayHeight) / 2;
    
    // Use the larger dimension to make it square
    const size = Math.max(w * scaleX, h * scaleY);
    
    // Center the square on the face
    const centerX = offsetX + (x * scaleX) + (w * scaleX) / 2;
    const centerY = offsetY + (y * scaleY) + (h * scaleY) / 2;
    
    return {
      left: `${centerX - size / 2}px`,
      top: `${centerY - size / 2}px`,
      width: `${size}px`,
      height: `${size}px`,
    };
  };

  return (
    <ProtectedRoute>
      <MainLayout>
        <div className="w-full h-[calc(100vh-100px)] flex flex-col">
          <div className="mb-4 flex-shrink-0 px-4">
            <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-100 flex items-center gap-2">
              <UserCheck className="w-6 h-6 text-blue-500" />
              Face Verification
            </h1>
          </div>

          {loading ? (
            <div className="flex-1 flex justify-center items-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
            </div>
          ) : error ? (
            <div className="flex-1 flex flex-col justify-center items-center">
              <p className="text-red-500 mb-4">{error}</p>
              <button
                onClick={fetchVerifications}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          ) : verifications.length === 0 ? (
            <div className="flex-1 flex flex-col justify-center items-center text-center bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 mx-4">
              <UserCheck className="w-16 h-16 text-green-500 mb-4" />
              <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100 mb-2">
                All Caught Up!
              </h2>
              <p className="text-gray-600 dark:text-gray-400">
                No pending verifications at the moment.
              </p>
            </div>
          ) : (
            <div className="flex-1 flex flex-col lg:flex-row bg-white dark:bg-gray-800 rounded-2xl shadow-lg overflow-hidden mx-4">
              {/* Image Section - Takes full width on mobile (top half), left side on desktop */}
              <div className="relative flex-1 lg:w-1/2 bg-black flex items-center justify-center overflow-hidden min-h-[50vh] lg:min-h-0">
                <img
                  ref={imageRef}
                  src={API_ENDPOINTS.getMaster(currentUser, currentItem.asset_id)}
                  alt="Verification candidate"
                  className="max-w-full max-h-full object-contain"
                  onLoad={handleMainImageLoad}
                />
                {/* Face Overlay with Rounded Square Highlight */}
                {currentItem.w && imageDimensions && (
                  <>
                    {/* Rounded square cutout with white border - the area inside stays clear */}
                    <div
                      className="absolute border-4 border-white rounded-2xl pointer-events-none transition-all duration-300"
                      style={{
                        ...getOverlayStyle(),
                        boxShadow: '0 0 0 9999px rgba(0, 0, 0, 0.7)',
                      }}
                    />
                  </>
                )}
              </div>

              {/* Question & Actions Section - Takes full width on mobile (bottom half), right side on desktop */}
              <div className="flex-1 lg:w-1/2 p-6 lg:p-8 flex flex-col items-center justify-center bg-white dark:bg-gray-900 border-t lg:border-t-0 lg:border-l border-gray-200 dark:border-gray-800 overflow-y-auto">
                <h2 className="text-xl lg:text-2xl font-medium text-gray-800 dark:text-gray-100 mb-6 lg:mb-8">
                  Same or different person?
                </h2>

                <div className="flex items-center justify-center gap-6 lg:gap-8 mb-6 lg:mb-8">
                  {/* Reference Face */}
                  <div className="flex flex-col items-center gap-2">
                    <div className="w-20 h-20 lg:w-28 lg:h-28 rounded-full overflow-hidden ring-4 ring-gray-100 dark:ring-gray-800 shadow-lg">
                      <img
                        src={API_ENDPOINTS.getFaceImage(currentUser, currentItem.face_id)}
                        alt={currentItem.face_name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <span className="text-xs lg:text-sm font-medium text-gray-500 dark:text-gray-400">
                      {currentItem.face_name}
                    </span>
                  </div>

                  {/* Candidate Face Crop */}
                  <div className="flex flex-col items-center gap-2">
                    <div className="w-20 h-20 lg:w-28 lg:h-28 rounded-full overflow-hidden ring-4 ring-gray-100 dark:ring-gray-800 shadow-lg relative">
                      <FaceCrop
                        src={API_ENDPOINTS.getMaster(currentUser, currentItem.asset_id)}
                        x={currentItem.x}
                        y={currentItem.y}
                        w={currentItem.w}
                        h={currentItem.h}
                        className="w-full h-full"
                      />
                    </div>
                    <span className="text-xs lg:text-sm font-medium text-gray-500 dark:text-gray-400">
                      In Photo
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-4 lg:gap-6 w-full max-w-md">
                  <button
                    onClick={() => handleVerification(true)}
                    disabled={processing}
                    className="flex-1 flex flex-col items-center gap-1 group"
                  >
                    <div className="p-3 lg:p-4 rounded-full bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 group-hover:scale-110 transition-transform shadow-sm">
                      <Check className="w-6 h-6 lg:w-8 lg:h-8" />
                    </div>
                    <span className="text-xs lg:text-sm font-medium text-gray-600 dark:text-gray-400">Same</span>
                  </button>

                  <button
                    onClick={() => handleVerification(false)}
                    disabled={processing}
                    className="flex-1 flex flex-col items-center gap-1 group"
                  >
                    <div className="p-3 lg:p-4 rounded-full bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 group-hover:scale-110 transition-transform shadow-sm">
                      <X className="w-6 h-6 lg:w-8 lg:h-8" />
                    </div>
                    <span className="text-xs lg:text-sm font-medium text-gray-600 dark:text-gray-400">Different</span>
                  </button>

                  <button
                    onClick={() => handleVerification(null)}
                    disabled={processing}
                    className="flex-1 flex flex-col items-center gap-1 group"
                  >
                    <div className="p-3 lg:p-4 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 group-hover:scale-110 transition-transform shadow-sm">
                      <HelpCircle className="w-6 h-6 lg:w-8 lg:h-8" />
                    </div>
                    <span className="text-xs lg:text-sm font-medium text-gray-600 dark:text-gray-400">Not sure</span>
                  </button>
                </div>

                <div className="mt-4 lg:mt-6 text-xs lg:text-sm text-gray-400">
                  {verifications.length - 1} more to verify
                </div>
              </div>
            </div>
          )}
        </div>
      </MainLayout>
    </ProtectedRoute>
  );
}
