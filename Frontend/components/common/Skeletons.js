export function CardSkeleton() {
  return (
    <div className="animate-pulse rounded-lg bg-gray-200 dark:bg-gray-700 h-40" />
  );
}

export function GridSkeleton({ count = 12 }) {
  return (
    <div className="grid grid-cols-4 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-1 sm:gap-4">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="aspect-square">
          <div className="animate-pulse w-full h-full rounded-md sm:rounded-lg bg-gray-200 dark:bg-gray-700" />
        </div>
      ))}
    </div>
  );
}
