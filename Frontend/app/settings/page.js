"use client";

import { useState, useEffect } from "react";
import MainLayout from "@/components/layout/MainLayout";
import ProtectedRoute from "@/components/common/ProtectedRoute";
import { useSession } from "@/components/providers/SessionProvider";
import { API_ENDPOINTS } from "@/config/api";
import { useRouter } from "next/navigation";
import { Trash2, AlertTriangle, Server, ExternalLink } from "lucide-react";
import { getServerUrl, clearServerUrl } from "@/utils/serverConfig";

export default function SettingsPage() {
  const { currentUser, logout } = useSession();
  const router = useRouter();
  const [isDeleting, setIsDeleting] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [error, setError] = useState("");
  const [serverUrl, setServerUrl] = useState("");

  useEffect(() => {
    // Get current server URL
    const url = getServerUrl();
    if (url) {
      setServerUrl(url);
    }
  }, []);

  const handleChangeServer = () => {
    // Clear server URL and redirect to setup
    clearServerUrl();
    router.push("/setup");
  };

  const handleDeleteUser = async () => {
    if (!currentUser) return;
    
    setIsDeleting(true);
    setError("");

    try {
      const response = await fetch(API_ENDPOINTS.deleteUser(currentUser), {
        method: "DELETE",
      });

      if (response.ok) {
        logout();
        router.push("/");
      } else {
        const data = await response.json();
        setError(data.error || "Failed to delete account");
      }
    } catch (err) {
      console.error("Error deleting user:", err);
      setError("An error occurred while deleting your account");
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <ProtectedRoute>
      <MainLayout>
        <div className="max-w-2xl mx-auto space-y-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">
              Settings
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
              Manage your account settings
            </p>
          </div>

          {/* Server Configuration Section */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100 flex items-center gap-2">
                <Server className="w-5 h-5" />
                Server Configuration
              </h2>
            </div>
            
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Current Server
                </label>
                <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700">
                  <code className="flex-1 text-sm font-mono text-gray-900 dark:text-gray-100">
                    {serverUrl || "Not configured"}
                  </code>
                  {serverUrl && (
                    <a
                      href={serverUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-700 dark:text-blue-400"
                    >
                      <ExternalLink className="w-4 h-4" />
                    </a>
                  )}
                </div>
              </div>

              <button
                onClick={handleChangeServer}
                className="flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 border border-blue-200 transition-colors dark:bg-blue-900/20 dark:border-blue-800 dark:text-blue-400 dark:hover:bg-blue-900/30"
              >
                <Server className="w-4 h-4" />
                Change Server
              </button>
              
              <p className="text-xs text-gray-500 dark:text-gray-400">
                This will disconnect you from the current server and allow you to scan a new QR code or enter a different server address.
              </p>
            </div>
          </div>

          {/* Account Section */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                Account
              </h2>
            </div>
            
            <div className="p-6 space-y-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Username
                </label>
                <div className="text-gray-900 dark:text-gray-100 font-medium">
                  {currentUser}
                </div>
              </div>

              <div className="pt-6 border-t border-gray-200 dark:border-gray-700">
                <h3 className="text-lg font-medium text-red-600 dark:text-red-400 mb-2">
                  Danger Zone
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Once you delete your account, there is no going back. Please be certain.
                </p>
                
                {!showConfirm ? (
                  <button
                    onClick={() => setShowConfirm(true)}
                    className="flex items-center gap-2 px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 border border-red-200 transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                    Delete Account
                  </button>
                ) : (
                  <div className="bg-red-50 dark:bg-red-900/20 p-4 rounded-lg border border-red-200 dark:border-red-800">
                    <div className="flex items-start gap-3">
                      <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
                      <div className="flex-1">
                        <h4 className="text-sm font-semibold text-red-800 dark:text-red-200">
                          Are you absolutely sure?
                        </h4>
                        <p className="text-sm text-red-700 dark:text-red-300 mt-1">
                          This action cannot be undone. This will permanently delete your account 
                          and remove all your photos, albums, and data from our servers.
                        </p>
                        
                        {error && (
                          <p className="text-sm text-red-600 font-medium mt-2">
                            {error}
                          </p>
                        )}

                        <div className="flex gap-3 mt-4">
                          <button
                            onClick={handleDeleteUser}
                            disabled={isDeleting}
                            className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 text-sm font-medium"
                          >
                            {isDeleting ? "Deleting..." : "Yes, delete my account"}
                          </button>
                          <button
                            onClick={() => {
                              setShowConfirm(false);
                              setError("");
                            }}
                            disabled={isDeleting}
                            className="px-4 py-2 bg-white text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm font-medium"
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </MainLayout>
    </ProtectedRoute>
  );
}



