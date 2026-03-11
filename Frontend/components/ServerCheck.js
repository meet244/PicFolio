"use client";
import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { getServerUrl, verifyServerConnection } from "@/utils/serverConfig";
import { Loader2, Server } from "lucide-react";

/**
 * ServerCheck component
 * Verifies server availability on load and redirects to setup if needed
 */
export default function ServerCheck({ children }) {
  const router = useRouter();
  const pathname = usePathname();
  const [isChecking, setIsChecking] = useState(true);
  const [isServerAvailable, setIsServerAvailable] = useState(false);

  useEffect(() => {
    // Skip check if already on setup page
    if (pathname === "/setup") {
      setIsChecking(false);
      setIsServerAvailable(true);
      return;
    }

    const checkServer = async () => {
      try {
        // Get saved server URL
        const serverUrl = getServerUrl();

        if (!serverUrl) {
          // No server URL saved, redirect to setup
          router.push("/setup");
          return;
        }

        // Verify server connection
        const isConnected = await verifyServerConnection(serverUrl);

        if (isConnected) {
          setIsServerAvailable(true);
          setIsChecking(false);
        } else {
          // Server not available, redirect to setup
          router.push("/setup");
        }
      } catch (error) {
        console.error("Error checking server:", error);
        router.push("/setup");
      }
    };

    checkServer();
  }, [pathname, router]);

  // Show loading screen while checking
  if (isChecking && pathname !== "/setup") {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex flex-col items-center justify-center p-4">
        <div className="text-center space-y-6">
          {/* Animated Logo/Icon */}
          <div className="relative">
            <div className="absolute inset-0 bg-blue-500 rounded-full blur-xl opacity-50 animate-pulse"></div>
            <div className="relative bg-gray-800 p-6 rounded-full border-2 border-blue-500">
              <Server size={48} className="text-blue-500" />
            </div>
          </div>

          {/* Loading Text */}
          <div className="space-y-3">
            <h2 className="text-2xl font-bold text-white">
              Connecting to Server
            </h2>
            <div className="flex items-center justify-center space-x-2 text-gray-400">
              <Loader2 size={20} className="animate-spin" />
              <span>Verifying connection...</span>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="w-64 h-1 bg-gray-700 rounded-full overflow-hidden">
            <div className="h-full bg-gradient-to-r from-blue-500 to-purple-500 animate-pulse"></div>
          </div>
        </div>
      </div>
    );
  }

  // If server is available or on setup page, render children
  if (isServerAvailable || pathname === "/setup") {
    return <>{children}</>;
  }

  // Fallback (shouldn't reach here)
  return null;
}
