"use client";

import L from "leaflet";
import { useEffect, useRef } from "react";

// Fix default icon paths for Leaflet when using bundlers
const markerIcon = new L.Icon({
  iconUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

export default function LocationMap({ lat, lng, onChange }) {
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const markerRef = useRef(null);

  // Initialize map once
  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    const initialCenter =
      typeof lat === "number" && typeof lng === "number"
        ? [lat, lng]
        : [20, 0];

    const map = L.map(mapRef.current).setView(initialCenter, 3);
    mapInstanceRef.current = map;

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    }).addTo(map);

    map.on("click", (e) => {
      const { lat, lng } = e.latlng;

      if (markerRef.current) {
        markerRef.current.setLatLng(e.latlng);
      } else {
        markerRef.current = L.marker(e.latlng, { icon: markerIcon }).addTo(
          map
        );
      }

      onChange?.({ lat, lng });
    });

    // Try to get current location if no coordinates provided
    if (
      typeof lat !== "number" &&
      typeof lng !== "number" &&
      "geolocation" in navigator
    ) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          const newPos = L.latLng(latitude, longitude);

          // Update map view
          map.setView(newPos, 13);

          // Add marker
          if (markerRef.current) {
            markerRef.current.setLatLng(newPos);
          } else {
            markerRef.current = L.marker(newPos, { icon: markerIcon }).addTo(
              map
            );
          }

          // Notify parent
          onChange?.({ lat: latitude, lng: longitude });
        },
        (error) => {
          console.warn("Geolocation error:", error);
        }
      );
    }

    return () => {
      map.off();
      map.remove();
      mapInstanceRef.current = null;
      markerRef.current = null;
    };
  }, []);

  // Update marker if lat/lng props change
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map || typeof lat !== "number" || typeof lng !== "number") return;

    const newPos = L.latLng(lat, lng);
    if (markerRef.current) {
      markerRef.current.setLatLng(newPos);
    } else {
      markerRef.current = L.marker(newPos, { icon: markerIcon }).addTo(map);
    }
    map.setView(newPos, 8);
  }, [lat, lng]);

  return <div ref={mapRef} className="w-full h-full" />;
}

