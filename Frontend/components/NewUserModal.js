import { Dialog } from "@headlessui/react";
import { useState } from "react";
import { UserPlus } from "lucide-react";
import { API_ENDPOINTS } from "../config/api";

export default function NewUserModal({ isOpen, onClose, onUserCreated }) {
  const [userData, setUserData] = useState({
    name: "",
    password: "",
    confirmPassword: "",
  });

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (userData.password !== userData.confirmPassword) {
      alert("Passwords don't match!");
      return;
    }

    try {
      const response = await fetch(API_ENDPOINTS.createUser(), {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          username: userData.name,
          password: userData.password,
        }),
      });

      // Check if the response is ok (status 200-299)
      if (!response.ok) {
        console.error("Backend error:", response.status, response.statusText);
        alert(`Backend error (${response.status}): ${response.statusText}`);
        return;
      }

      const result = await response.json();

      if (result === "true") {
        alert("User created successfully!");
        setUserData({ name: "", password: "", confirmPassword: "" });
        onClose();
        // Trigger user refresh
        if (onUserCreated) {
          onUserCreated();
        }
      } else {
        alert(result); // Show error message from the backend
      }
    } catch (error) {
      console.error("Error creating user:", error);
      // Provide more helpful error messages
      if (error.message && error.message.includes("fetch")) {
        alert(
          "Failed to connect to the server. Please check if the backend is running."
        );
      } else if (error.message && error.message.includes("Unexpected")) {
        alert(
          "Server returned invalid response. Check backend logs for details."
        );
      } else {
        alert(
          `Error: ${error.message || "Something went wrong. Please try again."}`
        );
      }
    }
  };

  // OLD Code

  // const handleSubmit = (e) => {
  //   e.preventDefault();
  //   if (userData.password !== userData.confirmPassword) {
  //     alert("Passwords don't match!");
  //     return;
  //   }
  //   onSubmit(userData);
  //   setUserData({ name: '', password: '', confirmPassword: '' });
  // };

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div
        className="fixed inset-0 bg-black/50 backdrop-blur-sm"
        aria-hidden="true"
      />

      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="w-full max-w-md rounded-2xl bg-white dark:bg-gray-800 p-8 shadow-xl">
          <div className="flex flex-col items-center mb-6">
            <div className="w-16 h-16 rounded-full bg-blue-100 dark:bg-gray-700 flex items-center justify-center mb-4">
              <UserPlus className="w-8 h-8 text-blue-500 dark:text-gray-300" />
            </div>
            <Dialog.Title className="text-2xl font-semibold text-gray-800 dark:text-gray-100">
              Create New User
            </Dialog.Title>
            <p className="text-gray-500 dark:text-gray-400 mt-1">
              Enter user details below
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Name
              </label>
              <input
                type="text"
                value={userData.name}
                onChange={(e) =>
                  setUserData({ ...userData, name: e.target.value })
                }
                className="w-full p-3 border rounded-lg dark:bg-gray-700 dark:border-gray-600
                  focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none
                  transition-all dark:text-gray-100"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Password
              </label>
              <input
                type="password"
                value={userData.password}
                onChange={(e) =>
                  setUserData({ ...userData, password: e.target.value })
                }
                className="w-full p-3 border rounded-lg dark:bg-gray-700 dark:border-gray-600
                  focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none
                  transition-all dark:text-gray-100"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Confirm Password
              </label>
              <input
                type="password"
                value={userData.confirmPassword}
                onChange={(e) =>
                  setUserData({ ...userData, confirmPassword: e.target.value })
                }
                className="w-full p-3 border rounded-lg dark:bg-gray-700 dark:border-gray-600
                  focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none
                  transition-all dark:text-gray-100"
                required
              />
            </div>

            <div className="flex justify-end gap-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="px-5 py-2.5 rounded-lg bg-gray-100 text-gray-700 hover:bg-gray-200
                  dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-5 py-2.5 rounded-lg bg-blue-500 text-white hover:bg-blue-600
                  transition-colors focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
                  dark:focus:ring-offset-gray-800"
              >
                Create User
              </button>
            </div>
          </form>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}
