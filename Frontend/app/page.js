"use client";
import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import UserCard from "../components/UserCard";
import NewUserCard from "../components/NewUserCard";
import PasswordModal from "../components/PasswordModal";
import NewUserModal from "../components/NewUserModal";
import { API_ENDPOINTS } from "../config/api";
import { useSession } from "../components/providers/SessionProvider";

export default function Home() {
  const { isAuthenticated, isLoading: sessionLoading, login } = useSession();
  const router = useRouter();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  const [selectedUser, setSelectedUser] = useState(null);
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false);
  const [isNewUserModalOpen, setIsNewUserModalOpen] = useState(false);

  // Redirect authenticated users to photos page
  useEffect(() => {
    if (!sessionLoading && isAuthenticated) {
      router.push("/photos");
    }
  }, [isAuthenticated, sessionLoading, router]);

  const fetchUsers = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch(API_ENDPOINTS.getUsers());
      const usernames = await response.json();

      // Convert backend usernames to user objects
      const userObjects = usernames.map((username, index) => ({
        id: index + 1,
        name: username,
      }));

      setUsers(userObjects);
    } catch (error) {
      console.error("Error fetching users:", error);
      alert("Failed to fetch users. Please check if the backend is running.");
    } finally {
      setLoading(false);
    }
  }, []);

  // Fetch users from backend on mount
  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleUserSelect = (user) => {
    setSelectedUser(user);
    setIsPasswordModalOpen(true);
  };

  const handlePasswordSubmit = (password) => {
    console.log(`Successful login for ${selectedUser.name}`);
    // Create session
    login(selectedUser.name, password);
    setIsPasswordModalOpen(false);
    setSelectedUser(null);
    // Redirect to photos page after successful login
    router.push("/photos");
  };

  const handleNewUserCreated = () => {
    // Refresh user list after new user is created
    fetchUsers();
  };

  // Show loading while checking session or fetching users
  if (sessionLoading || loading) {
    return (
      <div
        className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 
        dark:from-gray-900 dark:to-gray-800 flex items-center justify-center"
      >
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p className="text-gray-600 dark:text-gray-400">
            {sessionLoading ? "Checking authentication..." : "Loading users..."}
          </p>
        </div>
      </div>
    );
  }

  // Don't render login page if user is authenticated (will redirect)
  if (isAuthenticated) {
    return null;
  }

  return (
    <div
      className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 
      dark:from-gray-900 dark:to-gray-800 p-8"
    >
      <div className="max-w-7xl mx-auto">
        <h1 className="text-4xl font-bold text-center mb-4 text-gray-800 dark:text-gray-100">
          Welcome to Picfolio
        </h1>
        <p className="text-center text-gray-600 dark:text-gray-400 mb-12">
          Select your profile to continue
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8 justify-items-center">
          {users.map((user) => (
            <UserCard
              key={user.id}
              user={user}
              onSelect={handleUserSelect}
              onUserDeleted={handleNewUserCreated}
            />
          ))}
          <NewUserCard onClick={() => setIsNewUserModalOpen(true)} />
        </div>
      </div>

      <PasswordModal
        isOpen={isPasswordModalOpen}
        onClose={() => setIsPasswordModalOpen(false)}
        onSubmit={handlePasswordSubmit}
        userName={selectedUser?.name}
      />

      <NewUserModal
        isOpen={isNewUserModalOpen}
        onClose={() => setIsNewUserModalOpen(false)}
        onUserCreated={handleNewUserCreated}
      />
    </div>
  );
}
