// Backend API Configuration
import { getServerUrl } from "@/utils/serverConfig";

// Get the base URL dynamically from local storage or environment
const getBaseUrl = () => {
  // First check local storage (for scanned/manually entered URLs)
  const savedUrl = getServerUrl();
  if (savedUrl) {
    return savedUrl.replace(/\/+$/, "");
  }
  
  // Fallback to environment variable or default
  return (process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:5000").replace(/\/+$/, "");
};

export const API_BASE_URL = getBaseUrl();

export const API_ENDPOINTS = {
  getUsers: () => `${getBaseUrl()}/api/users`,
  createUser: () => `${getBaseUrl()}/api/user/create`,
  authUser: () => `${getBaseUrl()}/api/user/auth`,
  renameUser: (username, newUsername) =>
    `${getBaseUrl()}/api/user/rename/${username}/${newUsername}`,
  deleteUser: (username) => `${getBaseUrl()}/api/user/delete/${username}`,
  uploadAsset: () => `${getBaseUrl()}/api/upload`,
  getPhotosList: () => `${getBaseUrl()}/api/list/general`,
  getAssetDetails: (username, photoId) =>
    `${getBaseUrl()}/api/details/${username}/${photoId}`,
  getPreview: (username, photoId) =>
    `${getBaseUrl()}/api/preview/${username}/${photoId}`,
  getMaster: (username, photoId) =>
    `${getBaseUrl()}/api/asset/${username}/${photoId}`,

  // Favorites APIs
  toggleLike: (username, assetId) =>
    `${getBaseUrl()}/api/like/${username}/${assetId}`,
  checkLiked: (username, assetId) =>
    `${getBaseUrl()}/api/liked/${username}/${assetId}`,
  searchAssets: () => `${getBaseUrl()}/api/search`,

  // Faces APIs
  getFacesList: () => `${getBaseUrl()}/api/list/faces`,
  getFaceImage: (username, faceId) =>
    `${getBaseUrl()}/api/face/image/${username}/${faceId}`,
  getFaceName: (username, faceId) =>
    `${getBaseUrl()}/api/face/name/${username}/${faceId}`,
  getFaceAssets: (username, faceId) =>
    `${getBaseUrl()}/api/list/face/${username}/${faceId}`,
  renameFace: (username, faceId, name) =>
    `${getBaseUrl()}/api/face/rename/${username}/${faceId}/${encodeURIComponent(name)}`,
  deleteFace: (username, faceId) =>
    `${getBaseUrl()}/api/face/delete/${username}/${faceId}`,
  joinFaces: () => `${getBaseUrl()}/api/face/join`,
  addFaceToPhoto: () => `${getBaseUrl()}/api/face/add`,
  removeFaceFromPhoto: () => `${getBaseUrl()}/api/face/remove`,
  getPendingVerifications: (username) =>
    `${getBaseUrl()}/api/face/verify/pending/${username}`,
  updateVerification: () => `${getBaseUrl()}/api/face/verify/update`,

  // Auto Albums APIs
  getAutoAlbumsList: () => `${getBaseUrl()}/api/list/autoalbums`,
  getAutoAlbumCover: (username, autoAlbumName) =>
    `${getBaseUrl()}/api/autoalbum/${username}/${encodeURIComponent(autoAlbumName)}`,
  getAutoAlbumAssets: () => `${getBaseUrl()}/api/list/autoalbums`,

  // Album APIs
  listAlbums: () => `${getBaseUrl()}/api/list/albums`,
  createAlbum: () => `${getBaseUrl()}/api/album/create`,
  addAssetsToAlbum: () => `${getBaseUrl()}/api/album/add`,
  removeAssetsFromAlbum: () => `${getBaseUrl()}/api/album/remove`,
  deleteAlbum: () => `${getBaseUrl()}/api/album/delete`,
  getAlbumAssets: (username, albumId) =>
    `${getBaseUrl()}/api/album/${username}/${albumId}`,
  renameAlbum: () => `${getBaseUrl()}/api/album/rename`,
  redateAlbum: () => `${getBaseUrl()}/api/album/redate`,

  // Delete/Bin APIs
  deleteAssets: (username, ids) =>
    `${getBaseUrl()}/api/delete/${username}/${ids}`,
  getDeletedAssets: () => `${getBaseUrl()}/api/list/deleted`,
  restoreAssets: () => `${getBaseUrl()}/api/restore`,

  // Duplicates API
  getDuplicates: () => `${getBaseUrl()}/api/list/duplicate`,

  // Statistics API
  getStatistics: () => `${getBaseUrl()}/api/stats`,

  // Redate API
  redateAssets: () => `${getBaseUrl()}/api/redate`,

  // Location API
  updateLocation: () => `${getBaseUrl()}/api/location`,

  // Pending Assets API
  getPendingCount: (username) => `${getBaseUrl()}/api/pending/${username}`,
};
