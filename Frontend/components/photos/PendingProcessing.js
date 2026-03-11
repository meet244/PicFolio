"use client";
import { useState, useEffect } from "react";
import { RefreshCw } from "lucide-react";
import { API_ENDPOINTS } from "@/config/api";

export default function PendingProcessing({ currentUser }) {
  const [pendingCount, setPendingCount] = useState(0);
  const [loading, setLoading] = useState(true);

  const fetchPendingCount = async () => {
    if (!currentUser) return;
    
    try {
      const response = await fetch(API_ENDPOINTS.getPendingCount(currentUser));
      if (response.ok) {
        const data = await response.json();
        setPendingCount(data.pending || 0);
      }
    } catch (error) {
      console.error("Error fetching pending count:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPendingCount();
    
    // Poll every 30 seconds to update the count
    const interval = setInterval(fetchPendingCount, 30000);
    return () => clearInterval(interval);
  }, [currentUser]);

  if (loading || pendingCount === 0) {
    return null;
  }

  return (
    <div className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mb-6">
      <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 flex items-center gap-4 shadow-sm">
        <div className="relative flex-shrink-0">
          <img
            src="https://cdn.dribbble.com/userupload/23708556/file/original-3e063ba3567b2ed7c99f43caa14d628f.gif"
            alt="Processing"
            className="w-32 h-32 object-contain mix-blend-multiply dark:mix-blend-normal"
          />
        </div>
        
        <div className="flex-1">
          <h3 className="text-sm font-semibold text-blue-800 dark:text-blue-300">
            Processing your photos
          </h3>
          <p className="text-sm text-blue-600 dark:text-blue-400 mt-0.5">
            We are currently analyzing and organizing {pendingCount} new {pendingCount === 1 ? 'photo' : 'photos'}. 
            They will appear in your gallery automatically once ready.
          </p>
        </div>

        <button 
          onClick={fetchPendingCount}
          className="p-2 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-800 rounded-full transition-colors"
          title="Refresh status"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
