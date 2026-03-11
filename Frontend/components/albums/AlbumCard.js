import Image from "next/image";
import Link from "next/link";
import { ImageIcon, Trash2 } from "lucide-react";

export default function AlbumCard({ album, onDelete }) {
  const handleDelete = (e) => {
    e.preventDefault(); // Prevent navigation
    onDelete(album.id);
  };

  return (
    <Link
      href={`/albums/${album.id}`}
      className="group rounded-lg overflow-hidden bg-white dark:bg-gray-800 shadow-md hover:shadow-lg transition-shadow"
    >
      <div className="aspect-video relative bg-gray-100 dark:bg-gray-700">
        {album.coverUrl ? (
          <Image
            src={album.coverUrl}
            alt={album.title}
            fill
            className="object-cover"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center">
            <ImageIcon className="w-12 h-12 text-gray-400" />
          </div>
        )}
        {/* Delete Button Overlay */}
        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors">
          <button
            onClick={handleDelete}
            className="absolute top-2 right-2 p-2 rounded-full bg-red-500/0 group-hover:bg-red-500/80 
              text-white opacity-0 group-hover:opacity-100 transition-all hover:bg-red-500"
          >
            <Trash2 className="w-5 h-5" />
          </button>
        </div>
      </div>
      <div className="p-4">
        <h3 className="font-medium text-gray-800 dark:text-gray-100 mb-1">
          {album.title}
        </h3>
        {album.startDate && (
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {new Date(album.startDate).toLocaleDateString()}
          </p>
        )}
      </div>
    </Link>
  );
}