"use client";
import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  extractBaseUrlFromScan,
  saveServerUrl,
  verifyServerConnection,
  isValidUrl,
} from "@/utils/serverConfig";
import { Monitor, QrCode, Loader2, CheckCircle, XCircle, Upload, AlertCircle } from "lucide-react";

export default function SetupPage() {
  const router = useRouter();
  const [mode, setMode] = useState("select"); // 'select', 'scan', 'manual'
  const [manualUrl, setManualUrl] = useState("");
  const [error, setError] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const [scannerActive, setScannerActive] = useState(false);
  const [cameraSupported, setCameraSupported] = useState(true);
  const qrCodeRef = useRef(null);
  const html5QrCodeRef = useRef(null);
  const fileInputRef = useRef(null);

  // Check camera support on mount
  useEffect(() => {
    const isSecure =
      typeof window !== "undefined" &&
      (window.isSecureContext || location.hostname === "localhost" || location.hostname === "127.0.0.1");
    const hasGetUserMedia =
      typeof navigator !== "undefined" &&
      !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
    setCameraSupported(isSecure && hasGetUserMedia);
  }, []);

  // Suppress html5-qrcode internal clipboard errors (harmless library bug)
  useEffect(() => {
    const originalConsoleError = console.error;
    console.error = (...args) => {
      if (
        args[0] &&
        typeof args[0] === "string" &&
        args[0].includes("clipboard")
      ) {
        return; // silence clipboard errors from html5-qrcode
      }
      originalConsoleError.apply(console, args);
    };
    return () => {
      console.error = originalConsoleError;
    };
  }, []);

  // Cleanup scanner on unmount
  useEffect(() => {
    return () => {
      if (html5QrCodeRef.current && scannerActive) {
        html5QrCodeRef.current
          .stop()
          .catch(() => {});
      }
    };
  }, [scannerActive]);

  const handleConnectToServer = async (baseUrl) => {
    setError("");
    setIsVerifying(true);

    try {
      const isConnected = await verifyServerConnection(baseUrl);

      if (isConnected) {
        saveServerUrl(baseUrl);
        router.push("/");
      } else {
        setError(
          "Could not connect to server. Please check the URL and try again."
        );
      }
    } catch (err) {
      setError("Failed to connect to server. Please try again.");
      console.error("Connection error:", err);
    } finally {
      setIsVerifying(false);
    }
  };

  const handleQrResult = async (decodedText) => {
    const baseUrl = extractBaseUrlFromScan(decodedText);
    if (baseUrl && isValidUrl(baseUrl)) {
      await handleConnectToServer(baseUrl);
    } else {
      setError("Invalid QR code format. Please try again.");
      setMode("select");
    }
  };

  const startQrScanner = async () => {
    if (!cameraSupported) {
      setMode("scan");
      return;
    }

    setMode("scan");
    setError("");

    try {
      await new Promise((resolve) => setTimeout(resolve, 200));

      // Dynamic import to avoid SSR issues
      const { Html5Qrcode } = await import("html5-qrcode");

      const html5QrCode = new Html5Qrcode("qr-reader");
      html5QrCodeRef.current = html5QrCode;

      await html5QrCode.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: { width: 250, height: 250 } },
        async (decodedText) => {
          await html5QrCode.stop().catch(() => {});
          setScannerActive(false);
          await handleQrResult(decodedText);
        },
        () => {} // ignore per-frame errors
      );

      setScannerActive(true);
    } catch (err) {
      setScannerActive(false);
      // Camera failed — stay on scan screen showing the file upload fallback
      setCameraSupported(false);
      setError(
        "Camera not available. This usually requires HTTPS. You can upload a QR code image instead."
      );
    }
  };

  const stopQrScanner = async () => {
    if (html5QrCodeRef.current && scannerActive) {
      try {
        await html5QrCodeRef.current.stop();
        setScannerActive(false);
      } catch {}
    }
    setMode("select");
    setError("");
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setError("");
    setIsVerifying(true);

    try {
      const { Html5Qrcode } = await import("html5-qrcode");
      const html5QrCode = new Html5Qrcode("qr-reader-file");
      const result = await html5QrCode.scanFile(file, false);
      await handleQrResult(result);
    } catch (err) {
      setError("Could not read QR code from image. Please try again.");
      console.error("File scan error:", err);
    } finally {
      setIsVerifying(false);
      // Reset file input
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const handleManualSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!manualUrl.trim()) {
      setError("Please enter a server URL");
      return;
    }

    // Add http:// if not present
    let url = manualUrl.trim();
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = `http://${url}`;
    }

    if (!isValidUrl(url)) {
      setError("Invalid URL format. Please enter a valid URL.");
      return;
    }

    await handleConnectToServer(url);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-4">
      <div className="max-w-2xl w-full bg-gray-800 rounded-2xl shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-blue-600 to-purple-600 p-6">
          <h1 className="text-3xl font-bold text-white text-center">
            PicFolio Setup
          </h1>
          <p className="text-blue-100 text-center mt-2">
            Connect to your PicFolio server
          </p>
        </div>

        {/* Main Content */}
        <div className="p-8">
          {/* Mode Selection */}
          {mode === "select" && (
            <div className="space-y-6">
              <div className="text-center mb-8">
                <h2 className="text-xl font-semibold text-gray-200 mb-2">
                  Choose Connection Method
                </h2>
                <p className="text-gray-400">
                  Scan a QR code or enter the server address manually
                </p>
              </div>

              {/* Option Cards */}
              <div className="grid md:grid-cols-2 gap-4">
                {/* QR Code Option */}
                <button
                  onClick={startQrScanner}
                  className="group relative p-6 bg-gray-700 hover:bg-gray-600 rounded-xl transition-all duration-300 transform hover:scale-105 border-2 border-transparent hover:border-blue-500"
                >
                  <div className="flex flex-col items-center space-y-4">
                    <div className="p-4 bg-blue-600 rounded-full group-hover:bg-blue-500 transition-colors">
                      <QrCode size={40} className="text-white" />
                    </div>
                    <div className="text-center">
                      <h3 className="font-semibold text-lg text-white mb-1">
                        Scan QR Code
                      </h3>
                      <p className="text-sm text-gray-300">
                        Use your camera to scan
                      </p>
                    </div>
                  </div>
                </button>

                {/* Manual Entry Option */}
                <button
                  onClick={() => setMode("manual")}
                  className="group relative p-6 bg-gray-700 hover:bg-gray-600 rounded-xl transition-all duration-300 transform hover:scale-105 border-2 border-transparent hover:border-purple-500"
                >
                  <div className="flex flex-col items-center space-y-4">
                    <div className="p-4 bg-purple-600 rounded-full group-hover:bg-purple-500 transition-colors">
                      <Monitor size={40} className="text-white" />
                    </div>
                    <div className="text-center">
                      <h3 className="font-semibold text-lg text-white mb-1">
                        Manual Entry
                      </h3>
                      <p className="text-sm text-gray-300">
                        Enter server address manually
                      </p>
                    </div>
                  </div>
                </button>
              </div>

              {/* Error Display */}
              {error && (
                <div className="mt-6 p-4 bg-red-900/50 border border-red-600 rounded-lg flex items-start space-x-3">
                  <XCircle size={20} className="text-red-400 flex-shrink-0 mt-0.5" />
                  <p className="text-red-200 text-sm">{error}</p>
                </div>
              )}
            </div>
          )}

          {/* QR Scanner */}
          {mode === "scan" && (
            <div className="space-y-6">
              <div className="text-center">
                <h2 className="text-xl font-semibold text-gray-200 mb-2">
                  Scan QR Code
                </h2>
                <p className="text-gray-400">
                  {cameraSupported
                    ? "Point your camera at the QR code"
                    : "Camera requires HTTPS. Upload a QR code image instead."}
                </p>
              </div>

              {/* Camera warning banner */}
              {!cameraSupported && (
                <div className="p-4 bg-yellow-900/40 border border-yellow-700 rounded-lg flex items-start space-x-3">
                  <AlertCircle size={20} className="text-yellow-400 flex-shrink-0 mt-0.5" />
                  <div className="text-sm text-yellow-200">
                    <p className="font-medium mb-1">Camera not available in this context</p>
                    <p>Browsers require HTTPS to access the camera (except on localhost). You can instead upload a screenshot/photo of the QR code.</p>
                  </div>
                </div>
              )}

              {/* Camera QR Reader */}
              {cameraSupported && (
                <div className="relative">
                  <div
                    id="qr-reader"
                    ref={qrCodeRef}
                    className="rounded-lg overflow-hidden"
                  ></div>
                </div>
              )}

              {/* File Upload QR fallback */}
              <div className="space-y-3">
                {/* Hidden div required by html5-qrcode scanFile */}
                <div id="qr-reader-file" className="hidden"></div>

                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleFileUpload}
                  className="hidden"
                  id="qr-file-input"
                />
                <label
                  htmlFor="qr-file-input"
                  className={`flex items-center justify-center space-x-2 w-full py-3 px-4 rounded-lg transition-colors cursor-pointer border-2 border-dashed ${
                    isVerifying
                      ? "opacity-50 cursor-not-allowed border-gray-600 text-gray-500"
                      : "border-blue-600 text-blue-400 hover:bg-blue-900/20"
                  }`}
                >
                  {isVerifying ? (
                    <>
                      <Loader2 size={20} className="animate-spin" />
                      <span>Reading QR code...</span>
                    </>
                  ) : (
                    <>
                      <Upload size={20} />
                      <span>Upload QR Code Image</span>
                    </>
                  )}
                </label>
              </div>

              {/* Cancel Button */}
              <button
                onClick={stopQrScanner}
                disabled={isVerifying}
                className="w-full py-3 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors disabled:opacity-50"
              >
                Cancel
              </button>

              {/* Error Display */}
              {error && (
                <div className="p-4 bg-red-900/50 border border-red-600 rounded-lg flex items-start space-x-3">
                  <XCircle size={20} className="text-red-400 flex-shrink-0 mt-0.5" />
                  <p className="text-red-200 text-sm">{error}</p>
                </div>
              )}
            </div>
          )}

          {/* Manual Entry Form */}
          {mode === "manual" && (
            <div className="space-y-6">
              <div className="text-center">
                <h2 className="text-xl font-semibold text-gray-200 mb-2">
                  Enter Server Address
                </h2>
                <p className="text-gray-400">
                  Enter the IP address or URL of your PicFolio server
                </p>
              </div>

              <form onSubmit={handleManualSubmit} className="space-y-4">
                <div>
                  <label
                    htmlFor="serverUrl"
                    className="block text-sm font-medium text-gray-300 mb-2"
                  >
                    Server URL
                  </label>
                  <input
                    type="text"
                    id="serverUrl"
                    value={manualUrl}
                    onChange={(e) => setManualUrl(e.target.value)}
                    placeholder="e.g., 192.168.0.109:7251"
                    className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                    disabled={isVerifying}
                  />
                  <p className="mt-2 text-xs text-gray-400">
                    Enter IP address with port (e.g., 192.168.0.109:7251)
                  </p>
                </div>

                {/* Error Display */}
                {error && (
                  <div className="p-4 bg-red-900/50 border border-red-600 rounded-lg flex items-start space-x-3">
                    <XCircle size={20} className="text-red-400 flex-shrink-0 mt-0.5" />
                    <p className="text-red-200 text-sm">{error}</p>
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex space-x-4">
                  <button
                    type="button"
                    onClick={() => {
                      setMode("select");
                      setManualUrl("");
                      setError("");
                    }}
                    className="flex-1 py-3 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    disabled={isVerifying}
                  >
                    Back
                  </button>
                  <button
                    type="submit"
                    className="flex-1 py-3 px-4 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
                    disabled={isVerifying}
                  >
                    {isVerifying ? (
                      <>
                        <Loader2 size={20} className="animate-spin" />
                        <span>Connecting...</span>
                      </>
                    ) : (
                      <>
                        <CheckCircle size={20} />
                        <span>Connect</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
