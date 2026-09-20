import React from 'react';
import { useApp } from '../../context/AppContext';

export const MarkerDetailDrawer: React.FC = () => {
  const {
    isMarkerDrawerOpen,
    setIsMarkerDrawerOpen,
    selectedMarkerDetail,
    setSelectedRecipient,
    setIsVerificationModalOpen,
    setActiveTab,
    activeMission
  } = useApp();

  if (!isMarkerDrawerOpen || !selectedMarkerDetail) return null;

  const { type, data } = selectedMarkerDetail;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center sm:justify-end bg-slate-950/50 backdrop-blur-xs transition-opacity animate-fade-in">
      {/* Backdrop click to close */}
      <div 
        className="absolute inset-0 cursor-pointer"
        onClick={() => setIsMarkerDrawerOpen(false)}
      />

      {/* Sheet Container: Mobile Bottom Sheet (full width, rounded top) / Desktop Side Drawer (max-w-md, right slide) */}
      <div className="relative z-10 w-full sm:max-w-md bg-white rounded-t-3xl sm:rounded-l-3xl sm:rounded-tr-none shadow-2xl border-t sm:border-t-0 sm:border-l border-slate-200/80 max-h-[88vh] sm:h-full flex flex-col overflow-hidden animate-slide-up sm:animate-slide-left">
        
        {/* Mobile Pull Bar */}
        <div className="w-12 h-1.5 bg-slate-200 rounded-full mx-auto my-3 sm:hidden shrink-0" />

        {/* Drawer Header */}
        <div className="p-5 sm:p-6 bg-slate-50 border-b border-slate-200/70 flex items-start justify-between gap-3 shrink-0">
          <div className="flex items-center gap-3 min-w-0">
            <div className={`w-11 h-11 rounded-2xl flex items-center justify-center text-white shrink-0 shadow-sm ${
              type === 'donor' 
                ? 'bg-gradient-to-br from-tertiary to-amber-700'
                : type === 'transporter'
                ? 'bg-gradient-to-br from-primary to-primary-container'
                : 'bg-gradient-to-br from-secondary to-teal-700'
            }`}>
              <span className="material-symbols-outlined text-[24px]">
                {type === 'donor' ? 'restaurant' : type === 'transporter' ? 'local_shipping' : 'volunteer_activism'}
              </span>
            </div>
            <div className="min-w-0">
              <span className="font-label-sm text-[11px] uppercase tracking-wider font-bold text-slate-400 block">
                {type === 'donor' ? 'FOOD GIVER' : type === 'transporter' ? 'TRANSPORTER' : 'RECEIVER'}
              </span>
              <h2 className="font-headline-sm text-base sm:text-lg font-bold text-on-surface truncate">
                {type === 'donor' 
                  ? 'FoodBridge Demo Kitchen' 
                  : type === 'transporter' 
                  ? 'FoodBridge Pickup Partner' 
                  : (data?.displayCode || data?.name || 'Verified Demo Recipient')}
              </h2>
            </div>
          </div>

          <button
            onClick={() => setIsMarkerDrawerOpen(false)}
            className="w-8 h-8 rounded-full bg-slate-200/70 hover:bg-slate-300 text-slate-600 flex items-center justify-center transition-colors shrink-0"
            title="Close Drawer"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Drawer Scrollable Content */}
        <div className="p-5 sm:p-6 overflow-y-auto space-y-5 text-on-surface">

          {/* 1. FOOD GIVER DETAIL */}
          {type === 'donor' && (
            <div className="space-y-4 text-xs">
              <div className="flex items-center justify-between p-3 rounded-xl bg-amber-500/10 border border-amber-500/30">
                <span className="font-bold text-amber-900 text-xs">Event: Wedding Demo Kitchen</span>
                <span className="px-2 py-0.5 rounded-full bg-red-600 text-white font-bold text-[10px] uppercase tracking-wider animate-pulse">
                  HIGH SURPLUS RISK
                </span>
              </div>

              <div className="grid grid-cols-2 gap-2.5">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Planned Meals</span>
                  <span className="font-headline-sm text-base font-bold text-on-surface">500 meals</span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Expected Guests</span>
                  <span className="font-headline-sm text-base font-bold text-on-surface">500</span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Current Attendance</span>
                  <span className="font-headline-sm text-base font-bold text-primary">430 check-ins</span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Food Type</span>
                  <span className="font-headline-sm text-base font-bold text-secondary">Vegetarian</span>
                </div>
              </div>

              <div className="p-4 rounded-xl bg-slate-900 text-white space-y-2">
                <div className="flex items-center justify-between text-[11px] text-slate-300">
                  <span>Expected Consumption:</span>
                  <span className="font-bold text-teal-300 text-sm">425 – 440</span>
                </div>
                <div className="flex items-center justify-between text-[11px] text-slate-300">
                  <span>Potential Surplus:</span>
                  <span className="font-bold text-amber-400 text-sm">60 – 75 meals</span>
                </div>
                <div className="flex items-center justify-between text-[11px] text-slate-300 border-t border-slate-800 pt-2">
                  <span>Weather Impact:</span>
                  <span className="font-semibold text-slate-200">75% rain probability (Heavy Rain)</span>
                </div>
              </div>

              <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-100 space-y-1.5 text-[11px]">
                <div className="flex items-center justify-between">
                  <span className="text-slate-500">Serving Time:</span>
                  <span className="font-semibold text-on-surface">7:30 PM</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-500">Rescue Window:</span>
                  <span className="font-bold text-tertiary">7:45 – 9:15 PM</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-500">Location:</span>
                  <span className="text-on-surface truncate">Race Course / Avinashi Rd, Coimbatore</span>
                </div>
              </div>

              {/* Primary Action */}
              <button
                onClick={() => {
                  setIsMarkerDrawerOpen(false);
                  setActiveTab('predict');
                }}
                className="w-full h-12 rounded-xl bg-primary hover:bg-primary-container text-white font-bold text-sm shadow-md shadow-primary/20 flex items-center justify-center gap-2 active:scale-98 transition-all"
              >
                <span>CREATE RESCUE MISSION</span>
                <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
              </button>
            </div>
          )}

          {/* 2. RECEIVER DETAIL */}
          {type === 'recipient' && data && (
            <div className="space-y-4 text-xs">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-sm text-on-surface">{data.name}</h3>
                  <span className="text-[11px] text-slate-500">{data.address}</span>
                </div>
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 font-bold text-[10px]">
                  <span className="material-symbols-outlined text-[12px]">verified</span>
                  <span>✓ Verified</span>
                </span>
              </div>

              <div className="grid grid-cols-2 gap-2.5">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Food Requirement</span>
                  <span className="font-headline-sm text-base font-bold text-primary">{data.needMeals} meals required</span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Food Type</span>
                  <span className="font-headline-sm text-base font-bold text-secondary">
                    {data.isVegetarianCompatible ? 'Vegetarian' : 'Mixed / All'}
                  </span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Current Availability</span>
                  <span className="font-bold text-emerald-700 text-xs">
                    {data.isAvailable ? 'Available now' : 'Closing soon'}
                  </span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Distance & ETA</span>
                  <span className="font-bold text-on-surface text-xs">
                    {data.distanceKm} km away (~{data.estimatedTravelMins || 7} min)
                  </span>
                </div>
              </div>

              {/* Match Compatibility */}
              <div className="p-4 rounded-xl bg-teal-900 text-white flex items-center justify-between">
                <div>
                  <span className="text-[10px] uppercase font-bold tracking-wider text-teal-300 block">
                    MATCH COMPATIBILITY
                  </span>
                  <span className="text-2xl font-black text-white tabular-nums">
                    {data.compatibilityScore || 94}%
                  </span>
                </div>
                <div className="w-12 h-12 rounded-full border-4 border-teal-400/30 border-t-teal-300 flex items-center justify-center font-bold text-xs text-teal-200">
                  {data.compatibilityScore || 94}%
                </div>
              </div>

              {/* Why Recommended */}
              <div className="bg-slate-50 p-4 rounded-xl border border-slate-200/80 space-y-2">
                <span className="font-bold text-xs text-on-surface uppercase tracking-wider block">
                  WHY RECOMMENDED?
                </span>
                <ul className="space-y-1.5 text-[11px] text-slate-600">
                  {data.whyRecommended && data.whyRecommended.length > 0 ? (
                    data.whyRecommended.map((reason: string, idx: number) => (
                      <li key={idx} className="flex items-start gap-1.5">
                        <span className="text-secondary font-bold">•</span>
                        <span>{reason}</span>
                      </li>
                    ))
                  ) : (
                    <>
                      <li className="flex items-start gap-1.5">
                        <span className="text-secondary font-bold">•</span>
                        <span>Quantity closely matches surplus batch</span>
                      </li>
                      <li className="flex items-start gap-1.5">
                        <span className="text-secondary font-bold">•</span>
                        <span>Nearby transit corridor ({data.distanceKm} km)</span>
                      </li>
                      <li className="flex items-start gap-1.5">
                        <span className="text-secondary font-bold">•</span>
                        <span>Available during rescue window (7:45–9:15 PM)</span>
                      </li>
                      <li className="flex items-start gap-1.5">
                        <span className="text-secondary font-bold">•</span>
                        <span>Food type strictly compatible (Vegetarian)</span>
                      </li>
                    </>
                  )}
                </ul>
              </div>

              {/* CTAs */}
              <div className="space-y-2 pt-2">
                <button
                  onClick={() => {
                    setSelectedRecipient(data);
                    setIsMarkerDrawerOpen(false);
                    setIsVerificationModalOpen(true);
                  }}
                  className="w-full h-11 rounded-xl bg-primary hover:bg-primary-container text-white font-bold text-xs shadow-sm flex items-center justify-center gap-2 active:scale-98 transition-all"
                >
                  <span className="material-symbols-outlined text-[16px]">how_to_reg</span>
                  <span>SELECT RECEIVER</span>
                </button>

                <button
                  onClick={() => {
                    setIsMarkerDrawerOpen(false);
                    setActiveTab('matching');
                  }}
                  className="w-full h-10 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center justify-center gap-1.5 transition-colors"
                >
                  <span className="material-symbols-outlined text-[16px]">map</span>
                  <span>VIEW ON MAP</span>
                </button>
              </div>
            </div>
          )}

          {/* 3. TRANSPORTER DETAIL */}
          {type === 'transporter' && (
            <div className="space-y-4 text-xs">
              <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-sm text-on-surface">FoodBridge Pickup Partner</h3>
                  <span className="text-[11px] text-slate-500">Elena R. • Electric Cargo Van #12</span>
                </div>
                <span className="px-2 py-0.5 rounded-full bg-teal-100 text-teal-800 font-bold text-[10px] uppercase">
                  {activeMission?.status === 'picked_up' || activeMission?.status === 'in_transit'
                    ? 'En Route / In Transit'
                    : activeMission?.status === 'delivered'
                    ? 'Delivered'
                    : 'Assigned'}
                </span>
              </div>

              <div className="grid grid-cols-2 gap-2.5">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Distance to Donor</span>
                  <span className="font-headline-sm text-base font-bold text-primary">0.4 km away</span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Estimated Arrival</span>
                  <span className="font-headline-sm text-base font-bold text-secondary">~4 mins</span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Assigned Rescue Mission</span>
                  <span className="font-bold text-on-surface text-xs">
                    {activeMission?.id || 'FB-2026-0042'}
                  </span>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Food Quantity</span>
                  <span className="font-bold text-on-surface text-xs">
                    {activeMission?.quantityMeals || 72} meals
                  </span>
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-slate-100 border border-slate-200/80 space-y-2">
                <span className="font-bold text-xs text-on-surface block">Verification Protocol</span>
                <div className="flex items-center justify-between text-[11px]">
                  <span className="text-slate-500">Pickup verification:</span>
                  <span className="font-mono font-bold text-primary">OTP (FB-4291) / QR Code</span>
                </div>
                <div className="flex items-center justify-between text-[11px]">
                  <span className="text-slate-500">Delivery verification:</span>
                  <span className="font-mono font-bold text-secondary">OTP (FB-8834) / QR Code</span>
                </div>
              </div>

              {/* Primary CTA */}
              <button
                onClick={() => {
                  setIsMarkerDrawerOpen(false);
                  setActiveTab('mission');
                }}
                className="w-full h-11 rounded-xl bg-primary hover:bg-primary-container text-white font-bold text-xs shadow-sm flex items-center justify-center gap-2 active:scale-98 transition-all"
              >
                <span>VIEW RESCUE MISSION</span>
                <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
              </button>
            </div>
          )}

        </div>
      </div>
    </div>
  );
};
