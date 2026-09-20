import React from 'react';
import { useApp } from '../../context/AppContext';
import type { Recipient } from '../../types';
import { CoimbatoreRescueMap } from '../common/CoimbatoreRescueMap';

export const MatchingView: React.FC = () => {
  const {
    recipients,
    selectedRecipient,
    setSelectedRecipient,
    searchRadiusKm,
    setSearchRadiusKm,
    filterCategory,
    setFilterCategory,
    setIsVerificationModalOpen,
    openMarkerDrawer,
    predictionResult
  } = useApp();

  const surplusTarget = predictionResult
    ? Math.round((predictionResult.surplusMin + predictionResult.surplusMax) / 2)
    : 70;

  const handleSelectRecipient = (recipient: Recipient) => {
    setSelectedRecipient(recipient);
    setIsVerificationModalOpen(true);
  };

  const topMatch = recipients.find(r => r.id === 'recipient-a') || recipients[0];

  return (
    <div className="space-y-8 pb-16">
      
      {/* Intro Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-1">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-secondary-container/40 text-on-secondary-container">
            <span className="material-symbols-outlined text-[15px] text-secondary">hub</span>
            <span className="font-label-sm text-xs uppercase tracking-wider font-bold">Algorithmic Allocation Engine</span>
          </div>
          <h1 className="font-headline-xl text-2xl sm:text-3xl font-bold text-on-surface tracking-tight">
            Find the Right Recipient
          </h1>
          <p className="font-body-md text-slate-500 max-w-2xl text-xs sm:text-sm">
            FoodBridge matches available surplus food with verified nearby demand in real time.
          </p>
        </div>

        {/* Active Surplus Batch Pill */}
        <div className="bg-white px-4 py-2 rounded-xl border border-slate-200/80 shadow-xs flex items-center gap-3 shrink-0">
          <div className="text-right">
            <span className="text-[10px] text-slate-400 block font-semibold uppercase">Surplus Batch</span>
            <span className="font-headline-sm text-sm sm:text-base font-bold text-primary tabular-nums">~{surplusTarget} Vegetarian Meals</span>
          </div>
          <div className="w-9 h-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
            <span className="material-symbols-outlined text-[20px]">restaurant</span>
          </div>
        </div>
      </div>

      {/* Core Principle Banner: AI RECOMMENDS. HUMANS VERIFY. */}
      <div className="p-3.5 sm:p-4 rounded-2xl bg-teal-50 border border-teal-200/80 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-xs shadow-xs">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-teal-600 text-white flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-[18px]">verified_user</span>
          </div>
          <div>
            <span className="font-bold text-teal-900 block sm:inline">AI RECOMMENDS. HUMANS VERIFY.</span>
            <span className="text-teal-700 sm:ml-2 block sm:inline">
              Recommended based on quantity, distance, timing, food compatibility and verification status.
            </span>
          </div>
        </div>
        <span className="px-2.5 py-0.5 rounded-full bg-teal-100 text-teal-800 font-bold text-[10px] uppercase tracking-wider shrink-0">
          Human Verification Mandatory
        </span>
      </div>

      {/* Interactive Coimbatore Rescue Network Map */}
      <section className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200/80 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">radar</span>
            <h2 className="font-headline-sm text-base font-bold text-on-surface">
              Coimbatore Rescue Network Map
            </h2>
            <span className="px-2 py-0.5 rounded-full bg-secondary-container/40 text-on-secondary-container text-[10px] font-bold">
              Live Radius
            </span>
          </div>

          <div className="flex items-center gap-3">
            <label className="text-xs text-slate-500 font-medium">Search Radius:</label>
            <input
              type="range"
              min="1.0"
              max="6.0"
              step="0.5"
              value={searchRadiusKm}
              onChange={(e) => setSearchRadiusKm(parseFloat(e.target.value))}
              className="w-24 sm:w-32 accent-primary"
            />
            <span className="text-xs font-bold text-primary bg-primary/10 px-2 py-0.5 rounded-full tabular-nums">
              {searchRadiusKm.toFixed(1)} km
            </span>
          </div>
        </div>

        {/* Embedded Map Component */}
        <CoimbatoreRescueMap
          mode="matching"
          selectedRecipient={selectedRecipient}
          heightClass="h-72 sm:h-96"
          showAllRecipients={true}
        />
      </section>

      {/* Recommended Match Highlight Card (Primary Hackathon Match: Recipient A) */}
      {topMatch && (
        <section className="bg-gradient-to-br from-teal-900 via-slate-900 to-teal-950 text-white rounded-2xl p-6 sm:p-8 shadow-xl relative overflow-hidden">
          <div className="absolute top-0 right-0 w-80 h-80 bg-teal-500/10 rounded-full blur-3xl pointer-events-none"></div>

          <div className="relative z-10 space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-teal-500/20 border border-teal-400/30 text-teal-300 text-xs font-bold uppercase tracking-wider">
                <span className="material-symbols-outlined text-[15px]">auto_awesome</span>
                <span>Recommended Match</span>
              </div>
              <div className="text-[11px] text-slate-300">
                “Recommended based on quantity, distance, timing, food compatibility and verification status.”
              </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
              
              {/* Left Info (8 cols) */}
              <div className="lg:col-span-8 space-y-4">
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-headline-lg text-xl sm:text-2xl font-extrabold text-white">
                      {topMatch.name}
                    </h3>
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-400/30 text-[10px] font-bold">
                      <span className="material-symbols-outlined text-[12px]">verified</span>
                      <span>Verified Demo Recipient</span>
                    </span>
                  </div>
                  <p className="text-xs text-slate-300 mt-1 flex items-center gap-1">
                    <span className="material-symbols-outlined text-[14px] text-teal-400">pin_drop</span>
                    <span>{topMatch.address}</span>
                  </p>
                </div>

                {/* Key Metrics Bento */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                  <div className="bg-white/10 backdrop-blur-sm p-3 rounded-xl border border-white/10">
                    <span className="text-[10px] text-slate-300 uppercase block font-semibold">Requirement</span>
                    <strong className="text-sm font-bold text-white">{topMatch.needMeals} meals</strong>
                  </div>
                  <div className="bg-white/10 backdrop-blur-sm p-3 rounded-xl border border-white/10">
                    <span className="text-[10px] text-slate-300 uppercase block font-semibold">Distance</span>
                    <strong className="text-sm font-bold text-teal-300">{topMatch.distanceKm} km</strong>
                  </div>
                  <div className="bg-white/10 backdrop-blur-sm p-3 rounded-xl border border-white/10">
                    <span className="text-[10px] text-slate-300 uppercase block font-semibold">Est. Transit</span>
                    <strong className="text-sm font-bold text-teal-300">~{topMatch.estimatedTravelMins} min</strong>
                  </div>
                  <div className="bg-white/10 backdrop-blur-sm p-3 rounded-xl border border-white/10">
                    <span className="text-[10px] text-slate-300 uppercase block font-semibold">Food Type</span>
                    <strong className="text-sm font-bold text-white">Vegetarian</strong>
                  </div>
                </div>

                {/* Why Recommended Bullets */}
                <div className="bg-white/5 rounded-xl p-3.5 border border-white/10 space-y-1.5 text-xs text-slate-200">
                  <span className="font-bold text-[11px] uppercase tracking-wider text-teal-300 block">
                    WHY RECOMMENDED?
                  </span>
                  <ul className="grid grid-cols-1 sm:grid-cols-2 gap-1.5 text-[11px]">
                    {topMatch.whyRecommended.map((r, i) => (
                      <li key={i} className="flex items-start gap-1.5">
                        <span className="text-teal-400 font-bold">•</span>
                        <span>{r}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>

              {/* Right Score & Action (4 cols) */}
              <div className="lg:col-span-4 flex flex-col items-center justify-center p-5 rounded-2xl bg-white/10 border border-white/15 text-center space-y-4">
                <div>
                  <span className="text-[10px] uppercase font-bold text-teal-300 tracking-wider block">
                    MATCH COMPATIBILITY
                  </span>
                  <div className="text-4xl sm:text-5xl font-black text-white tabular-nums tracking-tight mt-1">
                    {topMatch.compatibilityScore}%
                  </div>
                  <span className="text-[11px] text-teal-200 block mt-1">Highest ranking match</span>
                </div>

                <div className="w-full space-y-2">
                  <button
                    onClick={() => handleSelectRecipient(topMatch)}
                    className="w-full h-11 rounded-xl bg-teal-400 hover:bg-teal-300 text-slate-950 font-bold text-xs shadow-lg shadow-teal-500/20 flex items-center justify-center gap-2 active:scale-95 transition-all"
                  >
                    <span className="material-symbols-outlined text-[18px]">verified</span>
                    <span>SELECT RECEIVER</span>
                  </button>

                  <button
                    onClick={() => openMarkerDrawer('recipient', topMatch)}
                    className="w-full h-9 rounded-xl bg-white/10 hover:bg-white/20 text-white font-medium text-xs flex items-center justify-center gap-1.5 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[16px]">info</span>
                    <span>VIEW DETAILS &amp; MAP</span>
                  </button>
                </div>
              </div>

            </div>
          </div>
        </section>
      )}

      {/* Alternative Verified Demo Recipients List */}
      <section className="space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div>
            <h3 className="font-headline-sm text-base font-bold text-on-surface">
              All Nearby Verified Demo Recipients
            </h3>
            <p className="text-xs text-slate-500">
              Ranked dynamically by proximity, quantity fit, dietary profile, and operational intake status.
            </p>
          </div>

          {/* Filter Chips */}
          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar">
            {(['all', 'score', 'distance', 'veg'] as const).map(f => (
              <button
                key={f}
                onClick={() => setFilterCategory(f)}
                className={`px-3 py-1 rounded-full text-xs font-semibold capitalize transition-all ${
                  filterCategory === f
                    ? 'bg-primary text-white shadow-xs'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                {f === 'veg' ? 'Vegetarian Only' : f}
              </button>
            ))}
          </div>
        </div>

        {/* Recipients Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {recipients.map(r => {
            const isTop = r.id === topMatch?.id;

            return (
              <div
                key={r.id}
                className={`bg-white rounded-2xl p-5 border transition-all flex flex-col justify-between ${
                  isTop
                    ? 'border-primary/40 ring-2 ring-primary/15 shadow-sm'
                    : 'border-slate-200/80 hover:border-slate-300 shadow-xs'
                }`}
              >
                <div className="space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <div className="flex items-center gap-1.5">
                        <span className="font-bold text-sm text-on-surface">{r.displayCode}</span>
                        {r.isVerified && (
                          <span className="material-symbols-outlined text-teal-600 text-[16px]" title="Verified Recipient">
                            verified
                          </span>
                        )}
                      </div>
                      <h4 className="font-semibold text-xs text-slate-700 truncate">{r.name}</h4>
                      <p className="text-[11px] text-slate-400 mt-0.5 truncate">{r.address}</p>
                    </div>

                    <div className="text-right shrink-0">
                      <span className="font-headline-sm text-lg font-black text-primary tabular-nums block">
                        {r.compatibilityScore}%
                      </span>
                      <span className="text-[9px] text-slate-400 uppercase font-bold">Match</span>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-[11px]">
                    <div className="bg-slate-50 p-2 rounded-lg border border-slate-100">
                      <span className="text-[10px] text-slate-400 block font-semibold">Requirement</span>
                      <strong className="text-on-surface">{r.needMeals} meals</strong>
                    </div>
                    <div className="bg-slate-50 p-2 rounded-lg border border-slate-100">
                      <span className="text-[10px] text-slate-400 block font-semibold">Transit Distance</span>
                      <strong className="text-teal-700">{r.distanceKm} km (~{r.estimatedTravelMins}m)</strong>
                    </div>
                  </div>

                  <div className="text-[11px] space-y-1 text-slate-600">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-400">Dietary Profile:</span>
                      <span className="font-semibold text-slate-700">
                        {r.isVegetarianCompatible ? 'Vegetarian' : 'Mixed / All'}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-400">Intake Window:</span>
                      <span className="font-medium text-emerald-700">{r.intakeWindow}</span>
                    </div>
                  </div>
                </div>

                <div className="pt-4 flex items-center gap-2">
                  <button
                    onClick={() => handleSelectRecipient(r)}
                    className="flex-1 h-9 rounded-xl bg-primary hover:bg-primary-container text-white font-bold text-xs shadow-xs flex items-center justify-center gap-1 active:scale-95 transition-all"
                  >
                    <span>SELECT RECEIVER</span>
                  </button>

                  <button
                    onClick={() => openMarkerDrawer('recipient', r)}
                    className="h-9 px-3 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition-colors flex items-center justify-center"
                    title="View on Map"
                  >
                    <span className="material-symbols-outlined text-[16px]">visibility</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </section>

    </div>
  );
};
