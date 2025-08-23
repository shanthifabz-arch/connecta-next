"use client";
import { useEffect, useRef } from "react";
import { Html5Qrcode } from "html5-qrcode";

interface QrScannerProps {
  onScanSuccess: (decodedText: string) => void;
  onClose: () => void;
}

export default function QrScanner({ onScanSuccess, onClose }: QrScannerProps) {
  const qrRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const qrCode = new Html5Qrcode("qr-reader");

    qrCode.start(
      { facingMode: "environment" },
      {
        fps: 10,
        qrbox: { width: 250, height: 250 },
      },
      (decodedText) => {
        onScanSuccess(decodedText);
        qrCode.stop().then(() => qrCode.clear());
      },
      (errorMessage) => {
        // silently ignore scan errors
      }
    );

    return () => {
      qrCode.stop().then(() => qrCode.clear());
    };
  }, []);

  return (
    <div className="mt-4">
      <div id="qr-reader" ref={qrRef} className="w-full max-w-xs mx-auto" />
      <button onClick={onClose} className="mt-2 text-sm text-red-600 underline">
        Cancel Scanner
      </button>
    </div>
  );
}

