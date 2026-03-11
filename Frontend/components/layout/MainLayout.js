"use client";
import { useState } from "react";
import {
  Menu,
  Images,
  Album,
  Heart,
  Search,
  Settings,
  LogOut,
  X,
  Trash2,
  Copy,
  ScanEye,
  BarChart3,
  UserCheck,
} from "lucide-react";
import { useSession } from "../providers/SessionProvider";

export default function MainLayout({ children }) {
  const { logout } = useSession();
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const menuItems = [
    { icon: Images, label: "Photos", href: "/photos" },
    { icon: Heart, label: "Favorites", href: "/favorites" },
    { icon: Album, label: "Albums", href: "/albums" },
    { icon: Search, label: "Explore", href: "/explore" },
    { icon: UserCheck, label: "Verifications", href: "/verifications" },
    { icon: Copy, label: "Duplicates", href: "/duplicates" },
    { icon: ScanEye, label: "Blurry Images", href: "/blurry" },
    { icon: Trash2, label: "Bin", href: "/bin" },
    { icon: BarChart3, label: "Statistics", href: "/statistics" },
    { icon: Settings, label: "Settings", href: "/settings" },
  ];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Mobile Header */}
      <div className="lg:hidden fixed top-0 left-0 right-0 h-16 bg-white dark:bg-gray-800 shadow-md z-30 px-4">
        <div className="flex items-center justify-between h-full">
          <h1 className="font-bold text-xl text-gray-800 dark:text-gray-100">
            Picfolio
          </h1>
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <Menu className="w-6 h-6 text-gray-600 dark:text-gray-300" />
          </button>
        </div>
      </div>

      {/* Sidebar Overlay */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div
        className={`fixed top-0 bottom-0 left-0 w-64 bg-white dark:bg-gray-800 shadow-lg transition-transform duration-300 z-50 
          lg:translate-x-0 lg:z-20 ${
            isSidebarOpen ? "translate-x-0" : "-translate-x-full"
          }`}
      >
        <div className="flex flex-col h-full">
          {/* Sidebar Header - Only visible on desktop */}
          <div className="hidden lg:flex p-4 items-center justify-between">
            <h1 className="font-bold text-xl text-gray-800 dark:text-gray-100">
              Picfolio
            </h1>
          </div>

          {/* Mobile Close Button */}
          <div className="lg:hidden p-4 flex justify-end">
            <button
              onClick={() => setIsSidebarOpen(false)}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <X className="w-6 h-6 text-gray-600 dark:text-gray-300" />
            </button>
          </div>

          <nav className="flex-1 p-4">
            <ul className="space-y-2">
              {menuItems.map((item) => (
                <li key={item.label}>
                  <a
                    href={item.href}
                    className="flex items-center gap-4 p-3 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700
                      text-gray-700 dark:text-gray-300"
                    onClick={() => setIsSidebarOpen(false)}
                  >
                    <item.icon className="w-6 h-6" />
                    <span>{item.label}</span>
                  </a>
                </li>
              ))}
            </ul>
          </nav>

          <div className="p-4 border-t dark:border-gray-700">
            <button
              onClick={logout}
              className="flex items-center gap-4 p-3 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700
              text-gray-700 dark:text-gray-300 w-full"
            >
              <LogOut className="w-6 h-6" />
              <span>Logout</span>
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="lg:ml-64 min-h-screen pt-16 lg:pt-0">
        <main className="p-4 lg:p-8">{children}</main>
      </div>
    </div>
  );
}
