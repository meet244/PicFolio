import Image from "next/image";

export default function PlacesGrid({ places = [] }) {
  return (
    <div className="mt-8">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
          Places
        </h2>
        <button className="text-sm text-blue-500 hover:underline">
          View All
        </button>
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4 mt-4">
        {places.map((pl) => (
          <div
            key={pl.id}
            className="rounded-xl overflow-hidden bg-gray-800 ring-1 ring-black/10"
          >
            <div className="aspect-video relative">
              <Image
                src={pl.cover}
                alt={pl.name}
                fill
                className="object-cover"
              />
            </div>
            <div className="p-2">
              <div className="text-white font-semibold drop-shadow">
                {pl.name}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
