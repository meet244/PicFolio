import Image from "next/image";
import { useState } from "react";
import { X, Trash2 } from "lucide-react";
import { API_ENDPOINTS } from "../config/api";

export default function UserCard({ user, onSelect, onUserDeleted }) {
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deletePassword, setDeletePassword] = useState("");
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState("");

  const handleDeleteClick = (e) => {
    e.stopPropagation(); // Prevent triggering the login click
    setShowDeleteModal(true);
  };

  const handleDeleteConfirm = async (e) => {
    e.preventDefault();
    setDeleteError("");
    setIsDeleting(true);

    try {
      // First authenticate the user
      const authResponse = await fetch(API_ENDPOINTS.authUser(), {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          username: user.name,
          password: deletePassword,
        }),
      });

      const authResult = await authResponse.json();

      if (authResult === "true") {
        // Authentication successful, now delete the user
        const deleteResponse = await fetch(
          API_ENDPOINTS.deleteUser(user.name),
          {
            method: "DELETE",
          }
        );

        if (deleteResponse.ok) {
          const deleteResult = await deleteResponse.json();
          alert("User deleted successfully!");
          setShowDeleteModal(false);
          setDeletePassword("");
          // Notify parent component to refresh user list
          if (onUserDeleted) {
            onUserDeleted();
          }
        } else {
          const errorResult = await deleteResponse.json();
          setDeleteError(errorResult.error || "Failed to delete user");
        }
      } else {
        setDeleteError(authResult || "Incorrect password");
      }
    } catch (error) {
      console.error("Error deleting user:", error);
      setDeleteError("Something went wrong. Please try again.");
    } finally {
      setIsDeleting(false);
    }
  };

  const handleDeleteCancel = () => {
    setShowDeleteModal(false);
    setDeletePassword("");
    setDeleteError("");
  };

  return (
    <>
      <div
        onClick={() => onSelect(user)}
        className="w-64 h-72 bg-white dark:bg-gray-800 rounded-xl shadow-lg hover:shadow-xl p-6 cursor-pointer 
          transform transition-all duration-300 hover:-translate-y-1 flex flex-col items-center justify-center gap-6
          border border-gray-100 dark:border-gray-700 relative group"
      >
        {/* Delete button */}
        <button
          onClick={handleDeleteClick}
          className="absolute top-2 right-2 w-8 h-8 bg-red-500 hover:bg-red-600 text-white rounded-full 
            flex items-center justify-center transition-all duration-200 opacity-0 group-hover:opacity-100
            hover:scale-110 shadow-lg"
          title="Delete user"
        >
          <X className="w-4 h-4" />
        </button>

        <div
          className="w-32 h-32 rounded-full bg-gradient-to-br from-blue-100 to-blue-50 
          dark:from-gray-700 dark:to-gray-600 overflow-hidden shadow-inner"
        >
          {user.avatar ? (
            <Image
              src={user.avatar}
              alt={user.name}
              width={128}
              height={128}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-4xl font-light text-blue-500 dark:text-gray-300">
              {user.name[0].toUpperCase()}
            </div>
          )}
        </div>
        <div className="text-center space-y-2">
          <h3 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
            {user.name}
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Click to login
          </p>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="w-full max-w-md rounded-2xl bg-white dark:bg-gray-800 p-8 shadow-xl">
            <div className="flex flex-col items-center mb-6">
              <div className="w-16 h-16 rounded-full bg-red-100 dark:bg-red-900/20 flex items-center justify-center mb-4">
                <Trash2 className="w-8 h-8 text-red-500 dark:text-red-400" />
              </div>
              <h2 className="text-2xl font-semibold text-gray-800 dark:text-gray-100">
                Delete User
              </h2>
              <p className="text-gray-500 dark:text-gray-400 mt-1 text-center">
                Are you sure you want to delete <strong>{user.name}</strong>?
                <br />
                This action cannot be undone.
              </p>
            </div>

            <form onSubmit={handleDeleteConfirm} className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Enter password to confirm deletion
                </label>
                <input
                  type="password"
                  value={deletePassword}
                  onChange={(e) => setDeletePassword(e.target.value)}
                  placeholder="Enter password"
                  className="w-full p-3 border rounded-lg dark:bg-gray-700 dark:border-gray-600
                    focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none
                    transition-all dark:text-gray-100"
                  autoFocus
                  disabled={isDeleting}
                  required
                />
                {deleteError && (
                  <p className="mt-2 text-sm text-red-500 dark:text-red-400">
                    {deleteError}
                  </p>
                )}
              </div>

              <div className="flex justify-end gap-3">
                <button
                  type="button"
                  onClick={handleDeleteCancel}
                  disabled={isDeleting}
                  className="px-5 py-2.5 rounded-lg bg-gray-100 text-gray-700 hover:bg-gray-200
                    dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600 transition-colors
                    disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isDeleting}
                  className="px-5 py-2.5 rounded-lg bg-red-500 text-white hover:bg-red-600
                    transition-colors focus:ring-2 focus:ring-red-500 focus:ring-offset-2
                    dark:focus:ring-offset-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isDeleting ? "Deleting..." : "Delete User"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
