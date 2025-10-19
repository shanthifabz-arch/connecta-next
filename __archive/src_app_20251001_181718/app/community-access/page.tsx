'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

export default function CommunityAccessPage() {
  const router = useRouter();
  const [showPopup, setShowPopup] = useState(true);

  const handleNext = () => {
    setShowPopup(false);
    router.push('/dashboard'); // Change this if your next step is different
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-100 to-indigo-200">
      {showPopup && (
        <div className="bg-white rounded-xl p-8 shadow-2xl text-center w-full max-w-md border border-gray-200">
          <h2 className="text-xl font-bold text-gray-800 mb-4">Welcome to CONNECTA</h2>
          <p className="mb-6 text-gray-700">
            Please allow <strong>CONNECTA</strong> to access your photos and contacts so that you can upload your business image and invite connectors.
          </p>
          <button
            onClick={handleNext}
            className="px-6 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}

