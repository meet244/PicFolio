"use client";
import { createContext, useContext, useState, useEffect } from "react";

const SessionContext = createContext();

export function SessionProvider({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Check for existing session on mount
  useEffect(() => {
    const checkSession = () => {
      try {
        const sessionData = localStorage.getItem("picfolio_session");
        if (sessionData) {
          const { user, timestamp } = JSON.parse(sessionData);
          const now = Date.now();
          const sessionAge = now - timestamp;

          // Session expires after 24 hours (optional)
          const maxAge = 24 * 60 * 60 * 1000; // 24 hours

          if (sessionAge < maxAge) {
            setIsAuthenticated(true);
            setCurrentUser(user);
          } else {
            // Session expired, clear it
            localStorage.removeItem("picfolio_session");
          }
        }
      } catch (error) {
        console.error("Error checking session:", error);
        localStorage.removeItem("picfolio_session");
      } finally {
        setIsLoading(false);
      }
    };

    checkSession();
  }, []);

  // Clean up session only when browser is closed (not tab close/switch)
  useEffect(() => {
    let isNavigating = false;

    const handleBeforeUnload = (event) => {
      // Don't clear session on navigation (tab switch, page refresh, etc.)
      // Only clear when browser is actually closing
      isNavigating = true;

      // Use a small timeout to detect if this is really a browser close
      setTimeout(() => {
        if (!isNavigating) {
          // Browser is actually closing
          localStorage.removeItem("picfolio_session");
        }
      }, 100);
    };

    const handlePageShow = () => {
      // Reset navigation flag when page becomes visible again
      isNavigating = false;
    };

    const handlePageHide = (event) => {
      // Only clear session if the page is being unloaded permanently
      // and not due to navigation or tab switching
      if (!event.persisted && !isNavigating) {
        localStorage.removeItem("picfolio_session");
      }
    };

    // Listen for page visibility changes
    window.addEventListener("beforeunload", handleBeforeUnload);
    window.addEventListener("pagehide", handlePageHide);
    window.addEventListener("pageshow", handlePageShow);

    return () => {
      window.removeEventListener("beforeunload", handleBeforeUnload);
      window.removeEventListener("pagehide", handlePageHide);
      window.removeEventListener("pageshow", handlePageShow);
    };
  }, []);

  const login = (user, password) => {
    const sessionData = {
      user,
      password, // Store for API calls
      timestamp: Date.now(),
    };

    localStorage.setItem("picfolio_session", JSON.stringify(sessionData));
    setIsAuthenticated(true);
    setCurrentUser(user);
  };

  const logout = () => {
    localStorage.removeItem("picfolio_session");
    setIsAuthenticated(false);
    setCurrentUser(null);
  };

  const value = {
    isAuthenticated,
    currentUser,
    isLoading,
    login,
    logout,
  };

  return (
    <SessionContext.Provider value={value}>{children}</SessionContext.Provider>
  );
}

export function useSession() {
  const context = useContext(SessionContext);
  if (context === undefined) {
    throw new Error("useSession must be used within a SessionProvider");
  }
  return context;
}
