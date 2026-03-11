import Image from "next/image";
import Link from "next/link";
import { API_ENDPOINTS } from "@/config/api";

export default function AutoAlbumsGrid({ autoAlbums = {}, currentUser }) {
  const { Places = [], Things = [], Documents = [] } = autoAlbums;

  const renderAlbumCard = (album, index) => {
    const [name, assetId, date] = album;
    // Use the preview endpoint with the asset ID for the cover image
    const imageUrl = API_ENDPOINTS.getPreview(currentUser, assetId);

    return (
      <Link
        key={`${name}-${index}`}
        href={`/explore/autoalbum/${encodeURIComponent(name)}`}
        className="block"
      >
        <div className="rounded-xl overflow-hidden bg-white dark:bg-gray-800 ring-1 ring-black/10 hover:ring-blue-500 transition-all hover:shadow-lg">
          <div className="aspect-video relative bg-gray-200 dark:bg-gray-700">
            <Image
              src={imageUrl}
              alt={name}
              fill
              className="object-cover"
              unoptimized
            />
          </div>
          <div className="p-3">
            <div className="font-semibold text-gray-800 dark:text-gray-100">
              {name}
            </div>
            {date && (
              <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {new Date(date).toLocaleDateString()}
              </div>
            )}
          </div>
        </div>
      </Link>
    );
  };

  const hasContent = Places.length > 0 || Things.length > 0 || Documents.length > 0;

  if (!hasContent) return null;

  return (
    <div className="space-y-8">
      {/* Places Section */}
      {Places.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
              Places
            </h2>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4">
            {Places.map((album, index) => renderAlbumCard(album, index))}
          </div>
        </div>
      )}

      {/* Things Section */}
      {Things.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
              Things
            </h2>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4">
            {Things.map((album, index) => renderAlbumCard(album, index))}
          </div>
        </div>
      )}

      {/* Documents Section */}
      {Documents.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
              Documents
            </h2>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4">
            {Documents.map((album, index) => renderAlbumCard(album, index))}
          </div>
        </div>
      )}
    </div>
  );
}

