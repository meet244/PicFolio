// Server configuration utilities for managing dynamic base URL

const SERVER_URL_KEY = 'picfolio_server_url';

/**
 * Extract base URL from QR scan result
 * QR format: https://picfolio.vercel.app/scan/http://192.168.0.109:7251
 * Extract: http://192.168.0.109:7251
 */
export const extractBaseUrlFromScan = (scanResult) => {
  try {
    // Check if it's a full scan URL
    if (scanResult.includes('/scan/')) {
      const parts = scanResult.split('/scan/');
      if (parts.length > 1) {
        return parts[1].replace(/\/+$/, ''); // Remove trailing slashes
      }
    }
    
    // If it's just a URL, validate and return
    if (scanResult.startsWith('http://') || scanResult.startsWith('https://')) {
      return scanResult.replace(/\/+$/, '');
    }
    
    return null;
  } catch (error) {
    console.error('Error extracting base URL:', error);
    return null;
  }
};

/**
 * Save server URL to local storage
 */
export const saveServerUrl = (url) => {
  try {
    if (typeof window !== 'undefined') {
      localStorage.setItem(SERVER_URL_KEY, url);
      return true;
    }
    return false;
  } catch (error) {
    console.error('Error saving server URL:', error);
    return false;
  }
};

/**
 * Get server URL from local storage
 */
export const getServerUrl = () => {
  try {
    if (typeof window !== 'undefined') {
      return localStorage.getItem(SERVER_URL_KEY);
    }
    return null;
  } catch (error) {
    console.error('Error getting server URL:', error);
    return null;
  }
};

/**
 * Clear server URL from local storage
 */
export const clearServerUrl = () => {
  try {
    if (typeof window !== 'undefined') {
      localStorage.removeItem(SERVER_URL_KEY);
      return true;
    }
    return false;
  } catch (error) {
    console.error('Error clearing server URL:', error);
    return false;
  }
};

/**
 * Verify if server is running at the given URL
 * Expected response: "Hello There!"
 */
export const verifyServerConnection = async (baseUrl) => {
  try {
    const response = await fetch(`${baseUrl}`, {
      method: 'GET',
      headers: {
        'Accept': 'text/plain, application/json',
      },
      // Add timeout
      signal: AbortSignal.timeout(5000),
    });

    if (response.ok) {
      const text = await response.text();
      // Check if response contains "Hello There!"
      return text.includes('Hello There!');
    }
    
    return false;
  } catch (error) {
    console.error('Error verifying server connection:', error);
    return false;
  }
};

/**
 * Validate URL format
 */
export const isValidUrl = (url) => {
  try {
    const urlObj = new URL(url);
    return urlObj.protocol === 'http:' || urlObj.protocol === 'https:';
  } catch (error) {
    return false;
  }
};
