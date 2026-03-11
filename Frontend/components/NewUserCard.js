import { PlusCircle } from "lucide-react";

export default function NewUserCard({ onClick }) {
  return (
    <div
      onClick={onClick}
      className="w-64 h-72 bg-gradient-to-br from-blue-50 to-blue-100 dark:from-gray-800 dark:to-gray-700 
        rounded-xl shadow-lg hover:shadow-xl p-6 cursor-pointer transform transition-all duration-300 
        hover:-translate-y-1 flex flex-col items-center justify-center gap-6 border-2 border-dashed 
        border-blue-200 dark:border-gray-600 hover:border-blue-300 dark:hover:border-gray-500"
    >
      <div
        className="w-32 h-32 rounded-full bg-white dark:bg-gray-800 flex items-center justify-center
        shadow-inner"
      >
        <PlusCircle className="w-16 h-16 text-blue-500 dark:text-gray-400" />
      </div>
      <div className="text-center space-y-2">
        <h3 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
          Add New User
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Create a new profile
        </p>
      </div>
    </div>
  );
}
