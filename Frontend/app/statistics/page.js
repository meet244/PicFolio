"use client";

import { useState, useEffect, useCallback } from "react";
import MainLayout from "@/components/layout/MainLayout";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { API_ENDPOINTS } from "@/config/api";
import { 
  Image as ImageIcon, 
  Video, 
  Calendar, 
  Album, 
  MapPin, 
  HardDrive 
} from "lucide-react";

export default function StatisticsPage() {
  const { currentUser } = useSession();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Fetch statistics from API
  const fetchStatistics = useCallback(async () => {
    if (!currentUser) return;

    try {
      setLoading(true);
      setError("");

      const formData = new FormData();
      formData.append("username", currentUser);

      const response = await fetch(API_ENDPOINTS.getStatistics(), {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setStats(data);
    } catch (error) {
      console.error("Error fetching statistics:", error);
      setError("Failed to load statistics. Please try again.");
    } finally {
      setLoading(false);
    }
  }, [currentUser]);

  useEffect(() => {
    fetchStatistics();
  }, [fetchStatistics]);

  // Calculate totals
  const totalImages = stats?.image_counts 
    ? Object.values(stats.image_counts).reduce((a, b) => a + b, 0) 
    : 0;
  const totalVideos = stats?.video_counts 
    ? Object.values(stats.video_counts).reduce((a, b) => a + b, 0) 
    : 0;
  const totalAssets = totalImages + totalVideos;

  const storagePercentage = stats?.used_storage && stats?.total_storage
    ? Math.round((stats.used_storage / stats.total_storage) * 100)
    : 0;

  return (
    <ProtectedRoute>
      <MainLayout>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
              Statistics
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Overview of your photo library
            </p>
          </div>

          {/* Loading State */}
          {loading && (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-gray-400">
                Loading statistics...
              </p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="text-center py-12">
              <p className="text-red-500 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={fetchStatistics}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          )}

          {/* Statistics Content */}
          {!loading && !error && stats && (
            <div className="space-y-6">
              {/* Overview Cards */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Total Assets */}
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">Total Assets</p>
                      <p className="text-3xl font-bold text-gray-800 dark:text-gray-100 mt-1">
                        {totalAssets.toLocaleString()}
                      </p>
                    </div>
                    <div className="p-3 bg-blue-100 dark:bg-blue-900/30 rounded-full">
                      <ImageIcon className="w-8 h-8 text-blue-600 dark:text-blue-400" />
                    </div>
                  </div>
                </div>

                {/* Total Images */}
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">Images</p>
                      <p className="text-3xl font-bold text-gray-800 dark:text-gray-100 mt-1">
                        {totalImages.toLocaleString()}
                      </p>
                    </div>
                    <div className="p-3 bg-green-100 dark:bg-green-900/30 rounded-full">
                      <ImageIcon className="w-8 h-8 text-green-600 dark:text-green-400" />
                    </div>
                  </div>
                </div>

                {/* Total Videos */}
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">Videos</p>
                      <p className="text-3xl font-bold text-gray-800 dark:text-gray-100 mt-1">
                        {totalVideos.toLocaleString()}
                      </p>
                    </div>
                    <div className="p-3 bg-purple-100 dark:bg-purple-900/30 rounded-full">
                      <Video className="w-8 h-8 text-purple-600 dark:text-purple-400" />
                    </div>
                  </div>
                </div>
              </div>

              {/* Storage Card */}
              <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                <div className="flex items-center gap-3 mb-4">
                  <HardDrive className="w-6 h-6 text-gray-600 dark:text-gray-400" />
                  <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                    Storage Usage
                  </h2>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-gray-400">
                      {stats.used_storage} GB used of {stats.total_storage} GB
                    </span>
                    <span className="text-gray-600 dark:text-gray-400 font-medium">
                      {storagePercentage}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
                    <div
                      className={`h-3 rounded-full transition-all ${
                        storagePercentage > 90
                          ? "bg-red-500"
                          : storagePercentage > 70
                          ? "bg-yellow-500"
                          : "bg-green-500"
                      }`}
                      style={{ width: `${Math.min(storagePercentage, 100)}%` }}
                    ></div>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Image Formats */}
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center gap-3 mb-4">
                    <ImageIcon className="w-6 h-6 text-gray-600 dark:text-gray-400" />
                    <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                      Image Formats
                    </h2>
                  </div>
                  <div className="space-y-3">
                    {Object.entries(stats.image_counts || {}).map(([format, count]) => (
                      <div key={format} className="flex items-center justify-between">
                        <span className="text-gray-600 dark:text-gray-400 uppercase font-medium">
                          {format}
                        </span>
                        <span className="text-gray-800 dark:text-gray-100 font-semibold">
                          {count.toLocaleString()}
                        </span>
                      </div>
                    ))}
                    {Object.keys(stats.image_counts || {}).length === 0 && (
                      <p className="text-gray-500 dark:text-gray-400 text-center py-4">
                        No images
                      </p>
                    )}
                  </div>
                </div>

                {/* Video Formats */}
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center gap-3 mb-4">
                    <Video className="w-6 h-6 text-gray-600 dark:text-gray-400" />
                    <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                      Video Formats
                    </h2>
                  </div>
                  <div className="space-y-3">
                    {Object.entries(stats.video_counts || {}).map(([format, count]) => (
                      <div key={format} className="flex items-center justify-between">
                        <span className="text-gray-600 dark:text-gray-400 uppercase font-medium">
                          {format}
                        </span>
                        <span className="text-gray-800 dark:text-gray-100 font-semibold">
                          {count.toLocaleString()}
                        </span>
                      </div>
                    ))}
                    {Object.keys(stats.video_counts || {}).length === 0 && (
                      <p className="text-gray-500 dark:text-gray-400 text-center py-4">
                        No videos
                      </p>
                    )}
                  </div>
                </div>

                {/* Yearly Breakdown */}
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center gap-3 mb-4">
                    <Calendar className="w-6 h-6 text-gray-600 dark:text-gray-400" />
                    <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                      By Year
                    </h2>
                  </div>
                  <div className="space-y-3 max-h-64 overflow-y-auto">
                    {stats.yearly_counts && stats.yearly_counts.length > 0 ? (
                      stats.yearly_counts.map(([year, count]) => (
                        <div key={year} className="flex items-center justify-between">
                          <span className="text-gray-600 dark:text-gray-400 font-medium">
                            {year || "Unknown"}
                          </span>
                          <span className="text-gray-800 dark:text-gray-100 font-semibold">
                            {count.toLocaleString()}
                          </span>
                        </div>
                      ))
                    ) : (
                      <p className="text-gray-500 dark:text-gray-400 text-center py-4">
                        No data
                      </p>
                    )}
                  </div>
                </div>

                {/* Top Albums */}
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center gap-3 mb-4">
                    <Album className="w-6 h-6 text-gray-600 dark:text-gray-400" />
                    <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                      Top Albums
                    </h2>
                  </div>
                  <div className="space-y-3">
                    {stats.top_albums && stats.top_albums.length > 0 ? (
                      stats.top_albums.map(([name, count], index) => (
                        <div key={index} className="flex items-center justify-between">
                          <span className="text-gray-600 dark:text-gray-400 font-medium truncate">
                            {name}
                          </span>
                          <span className="text-gray-800 dark:text-gray-100 font-semibold ml-2">
                            {count.toLocaleString()}
                          </span>
                        </div>
                      ))
                    ) : (
                      <p className="text-gray-500 dark:text-gray-400 text-center py-4">
                        No albums
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Top Locations */}
              {stats.top_locations && stats.top_locations.length > 0 && (
                <div className="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
                  <div className="flex items-center gap-3 mb-4">
                    <MapPin className="w-6 h-6 text-gray-600 dark:text-gray-400" />
                    <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                      Top Locations
                    </h2>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    {stats.top_locations.map((item, index) => {
                      // Handle both tuple [location, count] and object {location, count} formats
                      const location = Array.isArray(item)
                        ? item[0]
                        : item.location ?? item.name ?? Object.keys(item)[0];
                      const count = Array.isArray(item)
                        ? item[1]
                        : item.count ?? item.value ?? Object.values(item)[0];
                      return (
                      <div
                        key={index}
                        className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
                      >
                        <span className="text-gray-600 dark:text-gray-400 font-medium truncate">
                          {location}
                        </span>
                        <span className="text-gray-800 dark:text-gray-100 font-semibold ml-2">
                          {typeof count === "number" ? count.toLocaleString() : count}
                        </span>
                      </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </MainLayout>
    </ProtectedRoute>
  );
}



