import Image from "next/image";
import Link from "next/link";

export default function PeopleCarousel({ people = [] }) {
  return (
    <div className="flex items-center justify-between">
      <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
        People
      </h2>
      {people.length > 0 && (
        <Link
          href="/explore/people"
          className="text-sm text-blue-500 hover:underline"
        >
          View All
        </Link>
      )}
    </div>
  );
}

export function PeopleRow({ people = [] }) {
  return (
    <div className="mt-4 overflow-x-auto">
      <div className="flex gap-6 min-w-full pr-4">
        {people.map((p) => (
          <Link
            key={p.id}
            href={`/explore/people/${p.id}`}
            className="flex flex-col items-center shrink-0 group"
          >
            <div className="w-24 h-24 rounded-full overflow-hidden ring-2 ring-gray-200 dark:ring-gray-700 group-hover:ring-blue-500 transition">
              <Image
                src={p.avatar}
                alt={p.name}
                width={96}
                height={96}
                className="w-full h-full object-cover"
                unoptimized
              />
            </div>
            <span className="mt-2 text-sm text-gray-700 dark:text-gray-300 text-center max-w-[96px] truncate">
              {p.name}
            </span>
            {p.photoCount > 0 && (
              <span className="text-xs text-gray-500 dark:text-gray-400">
                {p.photoCount} photos
              </span>
            )}
          </Link>
        ))}
      </div>
    </div>
  );
}
