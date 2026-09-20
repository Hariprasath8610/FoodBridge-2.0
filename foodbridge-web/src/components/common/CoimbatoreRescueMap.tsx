import React, { useState, useEffect, useRef } from 'react';
import { useApp } from '../../context/AppContext';
import type { Recipient } from '../../types';

interface CoimbatoreRescueMapProps {
  mode?: 'matching' | 'mission' | 'preview';
  selectedRecipient?: Recipient | null;
  heightClass?: string;
  showAllRecipients?: boolean;
}

// Coimbatore Demo Landmark Coordinates
const COIMBATORE_CENTER = { lat: 11.0168, lng: 76.9558 };
const DONOR_LOCATION = {
  name: 'FoodBridge Demo Kitchen (Grand Palace Pavilion)',
  lat: 11.0180,
  lng: 76.9600,
  x: 48, // SVG percentage
  y: 48
};
const TRANSPORTER_ORIGIN = {
  name: 'FoodBridge Pickup Partner (Elena R.)',
  lat: 11.0210,
  lng: 76.9630,
  x: 55,
  y: 40
};

export const CoimbatoreRescueMap: React.FC<CoimbatoreRescueMapProps> = ({
  mode = 'matching',
  selectedRecipient,
  heightClass = 'h-72 sm:h-96',
  showAllRecipients = true
}) => {
  const {
    recipients,
    activeMission,
    openMarkerDrawer,
    searchRadiusKm
  } = useApp();

  const [zoomLevel, setZoomLevel] = useState(1);
  const [mapEngine, setMapEngine] = useState<'google' | 'vector'>('vector');
  const googleMapRef = useRef<HTMLDivElement>(null);
  const apiKey = (import.meta as any).env?.VITE_GOOGLE_MAPS_API_KEY;

  // Active recipient: either passed in or default to top match (Hope Community Kitchen)
  const targetRecipient = selectedRecipient || recipients.find(r => r.id === 'recipient-a') || recipients[0];

  // Try loading Google Maps if API key is present
  useEffect(() => {
    if (!apiKey || apiKey === 'YOUR_KEY_HERE') {
      setMapEngine('vector');
      return;
    }

    // Google Maps Script loader
    const existingScript = document.getElementById('google-maps-script');
    if (!existingScript) {
      const script = document.createElement('script');
      script.id = 'google-maps-script';
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=geometry`;
      script.async = true;
      script.defer = true;
      script.onload = () => initGoogleMap();
      script.onerror = () => setMapEngine('vector');
      document.head.appendChild(script);
    } else if ((window as any).google?.maps) {
      initGoogleMap();
    }
  }, [apiKey]);

  const initGoogleMap = () => {
    if (!googleMapRef.current || !(window as any).google?.maps) return;
    try {
      const google = (window as any).google;
      const map = new google.maps.Map(googleMapRef.current, {
        center: COIMBATORE_CENTER,
        zoom: 14,
        disableDefaultUI: true,
        zoomControl: true,
        styles: [
          { featureType: 'poi', stylers: [{ visibility: 'off' }] },
          { featureType: 'transit', stylers: [{ visibility: 'simplified' }] }
        ]
      });

      // Add Donor Marker
      new google.maps.Marker({
        position: { lat: DONOR_LOCATION.lat, lng: DONOR_LOCATION.lng },
        map,
        title: DONOR_LOCATION.name,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 9,
          fillColor: '#0F766E',
          fillOpacity: 1,
          strokeWeight: 2,
          strokeColor: '#FFFFFF'
        }
      });

      // Add Target Recipient Marker
      if (targetRecipient) {
        new google.maps.Marker({
          position: { lat: targetRecipient.coordinates.lat, lng: targetRecipient.coordinates.lng },
          map,
          title: targetRecipient.name,
          icon: {
            path: google.maps.SymbolPath.CIRCLE,
            scale: 9,
            fillColor: '#14B8A6',
            fillOpacity: 1,
            strokeWeight: 2,
            strokeColor: '#FFFFFF'
          }
        });

        // Add Route Line
        new google.maps.Polyline({
          path: [
            { lat: DONOR_LOCATION.lat, lng: DONOR_LOCATION.lng },
            { lat: targetRecipient.coordinates.lat, lng: targetRecipient.coordinates.lng }
          ],
          geodesic: true,
          strokeColor: '#006B5F',
          strokeOpacity: 0.8,
          strokeWeight: 4,
          map
        });
      }

      setMapEngine('google');
    } catch {
      setMapEngine('vector');
    }
  };

  // Determine current transporter position on the route based on active mission status
  const isDelivered = activeMission?.status === 'delivered';
  const isInTransit = activeMission?.status === 'in_transit' || activeMission?.status === 'picked_up';

  let transporterCoords = { x: TRANSPORTER_ORIGIN.x, y: TRANSPORTER_ORIGIN.y };
  if (isDelivered && targetRecipient) {
    transporterCoords = { x: targetRecipient.coordinates.x || 68, y: targetRecipient.coordinates.y || 24 };
  } else if (isInTransit && targetRecipient) {
    // Midway between donor and recipient
    transporterCoords = {
      x: Math.round((DONOR_LOCATION.x + (targetRecipient.coordinates.x || 68)) / 2),
      y: Math.round((DONOR_LOCATION.y + (targetRecipient.coordinates.y || 24)) / 2)
    };
  }

  const handleMarkerClick = (type: 'donor' | 'transporter' | 'recipient', data?: any) => {
    openMarkerDrawer(type, data);
  };

  return (
    <div className={`relative w-full ${heightClass} bg-slate-950 rounded-2xl overflow-hidden shadow-inner border border-slate-800 select-none flex items-center justify-center`}>
      
      {/* Google Maps Container (if loaded) */}
      {mapEngine === 'google' && (
        <div ref={googleMapRef} className="absolute inset-0 w-full h-full" />
      )}

      {/* Vector / SVG Coimbatore Interactive Map Fallback */}
      {mapEngine === 'vector' && (
        <div className="absolute inset-0 w-full h-full overflow-hidden transition-transform duration-300" style={{ transform: `scale(${zoomLevel})` }}>
          
          {/* Ambient Map Base & Real Coimbatore Road Grid */}
          <svg className="absolute inset-0 w-full h-full opacity-60" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="coimbatore-grid" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#1e293b" strokeWidth="0.75" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#coimbatore-grid)" />

            {/* Coimbatore Arterial Roads: Avinashi Rd, Trichy Rd, Cross Cut Rd */}
            {/* Avinashi Road (Diagonal Southwest to Northeast) */}
            <path d="M-50 260 Q 200 180, 500 120 T 900 60" fill="none" stroke="#334155" strokeWidth="7" strokeLinecap="round" />
            <path d="M-50 260 Q 200 180, 500 120 T 900 60" fill="none" stroke="#475569" strokeWidth="1.5" strokeDasharray="6,4" />

            {/* Trichy Road (South East Arterial) */}
            <path d="M120 380 Q 280 240, 480 180 T 800 240" fill="none" stroke="#334155" strokeWidth="5" />

            {/* Cross Cut Road / Gandhipuram Connector */}
            <path d="M480 280 L 480 80" fill="none" stroke="#334155" strokeWidth="4.5" />

            {/* DB Road / RS Puram Ring */}
            <circle cx="28%" cy="70%" r="45" fill="none" stroke="#334155" strokeWidth="3" strokeDasharray="4,4" />

            {/* Active Route Polyline: Donor -> Transporter -> Target Recipient */}
            {targetRecipient && (
              <g>
                <path
                  d={`M ${DONOR_LOCATION.x}% ${DONOR_LOCATION.y}% Q ${(DONOR_LOCATION.x + (targetRecipient.coordinates.x || 68)) / 2}% ${Math.min(DONOR_LOCATION.y, targetRecipient.coordinates.y || 24) - 4}% ${targetRecipient.coordinates.x || 68}% ${targetRecipient.coordinates.y || 24}%`}
                  fill="none"
                  stroke="#14B8A6"
                  strokeWidth="4"
                  strokeLinecap="round"
                  className="animate-pulse"
                />
                <path
                  d={`M ${DONOR_LOCATION.x}% ${DONOR_LOCATION.y}% Q ${(DONOR_LOCATION.x + (targetRecipient.coordinates.x || 68)) / 2}% ${Math.min(DONOR_LOCATION.y, targetRecipient.coordinates.y || 24) - 4}% ${targetRecipient.coordinates.x || 68}% ${targetRecipient.coordinates.y || 24}%`}
                  fill="none"
                  stroke="#A3FAEF"
                  strokeWidth="2"
                  strokeDasharray="8,6"
                />
              </g>
            )}
          </svg>

          {/* Concentric Search Radius Guide around Donor */}
          <div 
            className="absolute rounded-full border border-teal-500/30 bg-teal-500/5 -translate-x-1/2 -translate-y-1/2 pointer-events-none transition-all duration-300"
            style={{
              left: `${DONOR_LOCATION.x}%`,
              top: `${DONOR_LOCATION.y}%`,
              width: `${searchRadiusKm * 70}px`,
              height: `${searchRadiusKm * 70}px`
            }}
          >
            <div className="w-full h-full rounded-full animate-ping opacity-15 bg-teal-400"></div>
          </div>

          {/* ========================================================= */}
          {/* 1. DONOR MARKER: FoodBridge Demo Kitchen                   */}
          {/* ========================================================= */}
          <div
            className="absolute -translate-x-1/2 -translate-y-1/2 z-30 cursor-pointer group flex flex-col items-center"
            style={{ left: `${DONOR_LOCATION.x}%`, top: `${DONOR_LOCATION.y}%` }}
            onClick={() => handleMarkerClick('donor', DONOR_LOCATION)}
            title="FoodBridge Demo Kitchen (Click to inspect)"
          >
            <div className="px-2 py-0.5 rounded-full bg-amber-500 text-white font-label-sm text-[10px] font-bold shadow-lg whitespace-nowrap mb-1 flex items-center gap-1 group-hover:scale-105 transition-transform">
              <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse"></span>
              <span>Demo Kitchen</span>
            </div>
            <div className="relative">
              <div className="w-9 h-9 rounded-full bg-tertiary text-white flex items-center justify-center shadow-xl ring-4 ring-amber-500/30 group-hover:ring-amber-500/60 transition-all">
                <span className="material-symbols-outlined text-[20px]">restaurant</span>
              </div>
              <span className="absolute -top-1 -right-1 flex h-3.5 w-3.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3.5 w-3.5 bg-amber-500"></span>
              </span>
            </div>
          </div>

          {/* ========================================================= */}
          {/* 2. TRANSPORTER MARKER: FoodBridge Pickup Partner          */}
          {/* ========================================================= */}
          <div
            className="absolute -translate-x-1/2 -translate-y-1/2 z-35 cursor-pointer group flex flex-col items-center transition-all duration-700 ease-out"
            style={{ left: `${transporterCoords.x}%`, top: `${transporterCoords.y}%` }}
            onClick={() => handleMarkerClick('transporter', { ...TRANSPORTER_ORIGIN, activeMission })}
            title="FoodBridge Pickup Partner (Click to inspect)"
          >
            <div className="px-2 py-0.5 rounded-full bg-primary text-white font-label-sm text-[10px] font-bold shadow-lg whitespace-nowrap mb-1 flex items-center gap-1 group-hover:scale-105 transition-transform">
              <span className="material-symbols-outlined text-[12px]">local_shipping</span>
              <span>Pickup Partner</span>
            </div>
            <div className="w-8 h-8 rounded-full bg-teal-700 text-white flex items-center justify-center shadow-xl ring-3 ring-teal-400/40 group-hover:ring-teal-400/70 transition-all">
              <span className="material-symbols-outlined text-[18px]">electric_moped</span>
            </div>
          </div>

          {/* ========================================================= */}
          {/* 3. RECEIVER MARKERS: Verified Demo Recipients A, B, C    */}
          {/* ========================================================= */}
          {showAllRecipients ? (
            recipients.map((rec) => {
              const isSelected = targetRecipient?.id === rec.id;
              const posX = rec.coordinates.x || 68;
              const posY = rec.coordinates.y || 24;

              return (
                <div
                  key={rec.id}
                  className="absolute -translate-x-1/2 -translate-y-1/2 z-25 cursor-pointer group flex flex-col items-center transition-all"
                  style={{ left: `${posX}%`, top: `${posY}%` }}
                  onClick={() => handleMarkerClick('recipient', rec)}
                  title={`${rec.displayCode} - ${rec.name} (Click to inspect)`}
                >
                  <div className={`px-2 py-0.5 rounded-full font-label-sm text-[10px] font-bold shadow-md whitespace-nowrap mb-1 flex items-center gap-1 transition-all ${
                    isSelected
                      ? 'bg-secondary text-white ring-2 ring-teal-300 scale-105'
                      : 'bg-slate-800 text-slate-200 hover:bg-slate-700'
                  }`}>
                    <span className="material-symbols-outlined text-[11px] text-teal-300">verified</span>
                    <span>{rec.displayCode}</span>
                    <span className="text-teal-300 font-bold ml-0.5">({rec.distanceKm}km)</span>
                  </div>

                  <div className="relative">
                    <div className={`rounded-full flex items-center justify-center shadow-md transition-all ${
                      isSelected
                        ? 'w-8 h-8 bg-secondary text-white ring-4 ring-secondary/40'
                        : 'w-7 h-7 bg-slate-800 text-slate-300 hover:bg-slate-700'
                    }`}>
                      <span className="material-symbols-outlined text-[16px]">volunteer_activism</span>
                    </div>

                    {isSelected && (
                      <span className="absolute -top-1 -right-1 flex h-3 w-3">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-3 w-3 bg-teal-400"></span>
                      </span>
                    )}
                  </div>
                </div>
              );
            })
          ) : (
            targetRecipient && (
              <div
                className="absolute -translate-x-1/2 -translate-y-1/2 z-25 cursor-pointer group flex flex-col items-center"
                style={{ left: `${targetRecipient.coordinates.x || 68}%`, top: `${targetRecipient.coordinates.y || 24}%` }}
                onClick={() => handleMarkerClick('recipient', targetRecipient)}
              >
                <div className="px-2 py-0.5 rounded-full bg-secondary text-white font-label-sm text-[10px] font-bold shadow-md whitespace-nowrap mb-1 flex items-center gap-1 ring-2 ring-teal-300">
                  <span className="material-symbols-outlined text-[11px]">verified</span>
                  <span>{targetRecipient.displayCode}</span>
                </div>
                <div className="w-8 h-8 rounded-full bg-secondary text-white flex items-center justify-center shadow-md ring-4 ring-secondary/40">
                  <span className="material-symbols-outlined text-[16px]">volunteer_activism</span>
                </div>
              </div>
            )
          )}

        </div>
      )}

      {/* Floating Operational HUD Overlay (Top-Left) */}
      <div className="absolute top-3 left-3 z-40 bg-slate-900/85 backdrop-blur-md rounded-xl p-2.5 border border-slate-700/70 shadow-lg text-white text-xs max-w-[200px] sm:max-w-xs">
        <div className="flex items-center gap-1.5 text-teal-400 font-bold uppercase tracking-wider text-[10px]">
          <span className="material-symbols-outlined text-[14px]">location_on</span>
          <span>COIMBATORE DEMO NETWORK</span>
        </div>
        <div className="text-[11px] text-slate-300 mt-1 truncate">
          {mode === 'mission' ? (
            <div className="space-y-0.5">
              <div className="flex items-center justify-between gap-2">
                <span className="text-slate-400">Mission ID:</span>
                <span className="font-mono font-bold text-teal-300">{activeMission?.id || 'FB-2026-0042'}</span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-slate-400">Route / ETA:</span>
                <span className="font-semibold text-white">1.8 km (~7 min)</span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-slate-400">Status:</span>
                <span className="font-bold text-amber-300 uppercase text-[10px]">
                  {activeMission?.status === 'delivered' ? 'DELIVERED' : isInTransit ? 'IN TRANSIT' : 'ASSIGNED'}
                </span>
              </div>
            </div>
          ) : (
            <div className="space-y-0.5">
              <div className="flex items-center justify-between gap-2">
                <span className="text-slate-400">Origin:</span>
                <span className="font-semibold text-amber-300 truncate">Demo Kitchen</span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-slate-400">Recommended:</span>
                <span className="font-bold text-teal-300 truncate">Recipient A (94%)</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Floating Map Legend (Bottom-Left) */}
      <div className="absolute bottom-3 left-3 z-40 bg-slate-900/85 backdrop-blur-md rounded-xl px-2.5 py-1.5 border border-slate-700/70 shadow-md text-white text-[10px] hidden sm:flex items-center gap-3">
        <div className="flex items-center gap-1">
          <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span>
          <span className="text-slate-300">Food Giver</span>
        </div>
        <div className="flex items-center gap-1">
          <span className="w-2.5 h-2.5 rounded-full bg-teal-500"></span>
          <span className="text-slate-300">Transporter</span>
        </div>
        <div className="flex items-center gap-1">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-400"></span>
          <span className="text-slate-300">Receiver</span>
        </div>
      </div>

      {/* Floating Map Controls (Top-Right) */}
      <div className="absolute top-3 right-3 z-40 flex flex-col gap-1.5">
        <button
          onClick={() => setZoomLevel(prev => Math.min(prev + 0.2, 1.8))}
          className="w-8 h-8 rounded-lg bg-slate-900/80 hover:bg-slate-800 text-white flex items-center justify-center border border-slate-700 shadow-md text-sm font-bold transition-all"
          title="Zoom In"
        >
          +
        </button>
        <button
          onClick={() => setZoomLevel(prev => Math.max(prev - 0.2, 0.8))}
          className="w-8 h-8 rounded-lg bg-slate-900/80 hover:bg-slate-800 text-white flex items-center justify-center border border-slate-700 shadow-md text-sm font-bold transition-all"
          title="Zoom Out"
        >
          −
        </button>
        <button
          onClick={() => setZoomLevel(1)}
          className="w-8 h-8 rounded-lg bg-slate-900/80 hover:bg-slate-800 text-white flex items-center justify-center border border-slate-700 shadow-md text-xs transition-all"
          title="Reset Zoom to Coimbatore"
        >
          <span className="material-symbols-outlined text-[16px]">my_location</span>
        </button>
      </div>

      {/* Tap Instruction Toast (Mobile) */}
      <div className="absolute bottom-3 right-3 z-40 bg-black/70 backdrop-blur-xs text-[10px] text-slate-300 px-2 py-1 rounded-md border border-slate-700">
        Tap any marker for details
      </div>
    </div>
  );
};
