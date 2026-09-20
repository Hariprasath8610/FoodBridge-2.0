import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { CoimbatoreRescueMap } from '../common/CoimbatoreRescueMap';

export const MissionView: React.FC = () => {
  const {
    activeMission,
    pickupOtpInput,
    setPickupOtpInput,
    deliveryOtpInput,
    setDeliveryOtpInput,
    verifyPickupOtp,
    verifyDeliveryOtp,
    simulatePickupScan,
    simulateDeliveryHandoff,
    setActiveTab,
    selectedRecipient
  } = useApp();

  const [pickupOtpError, setPickupOtpError] = useState<string | null>(null);
  const [deliveryOtpError, setDeliveryOtpError] = useState<string | null>(null);
  const [isPickupSubmitting, setIsPickupSubmitting] = useState(false);
  const [isDeliverySubmitting, setIsDeliverySubmitting] = useState(false);

  if (!activeMission) {
    return (
      <div className="text-center py-20 bg-white rounded-2xl border border-slate-200 p-8 space-y-3">
        <span className="material-symbols-outlined text-slate-300 text-5xl">local_shipping</span>
        <h3 className="text-lg font-bold text-slate-700">No Active Rescue Mission</h3>
        <p className="text-xs text-slate-500">Please predict surplus and select a verified recipient first.</p>
        <button
          onClick={() => setActiveTab('predict')}
          className="mt-2 px-5 py-2.5 bg-primary text-white rounded-xl text-xs font-bold shadow-sm"
        >
          Go to Predict Surplus
        </button>
      </div>
    );
  }

  const isPickedUp = activeMission.status === 'in_transit' || activeMission.status === 'picked_up' || activeMission.status === 'delivered';
  const isDelivered = activeMission.status === 'delivered';

  const handleVerifyPickup = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsPickupSubmitting(true);
    setPickupOtpError(null);
    await new Promise(r => setTimeout(r, 500));
    const success = await verifyPickupOtp();
    if (!success) {
      setPickupOtpError('Invalid OTP. Use demo OTP: FB-4291');
    }
    setIsPickupSubmitting(false);
  };

  const handleVerifyDelivery = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsDeliverySubmitting(true);
    setDeliveryOtpError(null);
    await new Promise(r => setTimeout(r, 500));
    const success = await verifyDeliveryOtp();
    if (!success) {
      setDeliveryOtpError('Invalid OTP. Use demo OTP: FB-8834');
    }
    setIsDeliverySubmitting(false);
  };

  return (
    <div className="space-y-8 pb-16">
      
      {/* Intro Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-1">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-secondary-container/40 text-on-secondary-container">
            <span className="material-symbols-outlined text-[15px] text-secondary">local_shipping</span>
            <span className="font-label-sm text-xs uppercase tracking-wider font-bold">Active Mission Manifest</span>
          </div>
          <h1 className="font-headline-xl text-2xl sm:text-3xl font-bold text-on-surface tracking-tight flex items-center gap-2">
            <span>RESCUE MISSION</span>
            <span className="text-primary font-extrabold">{activeMission.id}</span>
          </h1>
          <p className="font-body-md text-slate-500 max-w-2xl text-xs sm:text-sm">
            Traceable smart dispatch chain with temperature verification and dual OTP handoffs.
          </p>
        </div>

        {/* Live Window Counter */}
        <div className="bg-white px-4 py-2 rounded-xl border border-slate-200/80 shadow-xs flex items-center gap-3 shrink-0">
          <div className="text-right">
            <span className="text-[10px] text-slate-400 uppercase font-semibold block">Rescue Window</span>
            <span className="font-headline-sm text-sm font-bold text-tertiary tabular-nums">7:45 – 9:15 PM</span>
          </div>
          <div className="w-8 h-8 rounded-lg bg-tertiary-container/30 text-tertiary flex items-center justify-center">
            <span className="material-symbols-outlined text-[18px]">timer</span>
          </div>
        </div>
      </div>

      {/* Mission Lifecycle Stepper */}
      <section className="bg-white rounded-2xl p-5 sm:p-6 border border-slate-200/80 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">timeline</span>
            <h2 className="font-headline-sm text-sm sm:text-base font-bold text-on-surface">
              Mission Traceability Timeline
            </h2>
          </div>
          <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${
            isDelivered
              ? 'bg-emerald-100 text-emerald-800'
              : isPickedUp
              ? 'bg-teal-100 text-teal-800 animate-pulse'
              : 'bg-amber-100 text-amber-800'
          }`}>
            {isDelivered ? 'Rescue Completed ✓' : isPickedUp ? 'In Transit to Recipient' : 'Pickup Assigned'}
          </span>
        </div>

        {/* Stepper Nodes */}
        <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-2.5 pt-2 text-xs">
          
          {/* 1. Prediction */}
          <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold">✓</span>
              <span className="text-[9px] text-slate-400">7:15 PM</span>
            </div>
            <div className="mt-2">
              <span className="font-bold text-on-surface block text-[11px]">1. Prediction</span>
              <span className="text-[10px] text-emerald-700 font-medium">84% Risk Alert</span>
            </div>
          </div>

          {/* 2. Recipient Matched */}
          <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold">✓</span>
              <span className="text-[9px] text-slate-400">7:22 PM</span>
            </div>
            <div className="mt-2">
              <span className="font-bold text-on-surface block text-[11px]">2. Matched</span>
              <span className="text-[10px] text-emerald-700 font-medium">Recipient A (94%)</span>
            </div>
          </div>

          {/* 3. Human Verification */}
          <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold">✓</span>
              <span className="text-[9px] text-slate-400">7:30 PM</span>
            </div>
            <div className="mt-2">
              <span className="font-bold text-on-surface block text-[11px]">3. Team Verify</span>
              <span className="text-[10px] text-emerald-700 font-medium">68°C Temp Pass</span>
            </div>
          </div>

          {/* 4. Authorization */}
          <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold">✓</span>
              <span className="text-[9px] text-slate-400">7:35 PM</span>
            </div>
            <div className="mt-2">
              <span className="font-bold text-on-surface block text-[11px]">4. Authorized</span>
              <span className="text-[10px] text-emerald-700 font-medium">FB-2026-0042</span>
            </div>
          </div>

          {/* 5. Pickup Assigned */}
          <div className={`p-2.5 rounded-xl border flex flex-col justify-between transition-all ${
            isPickedUp ? 'bg-slate-50 border-slate-200' : 'bg-primary/5 border-primary ring-2 ring-primary/20'
          }`}>
            <div className="flex items-center justify-between">
              <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                isPickedUp ? 'bg-emerald-600 text-white' : 'bg-primary text-white animate-pulse'
              }`}>
                {isPickedUp ? '✓' : '●'}
              </span>
              <span className="text-[9px] text-slate-400">7:38 PM</span>
            </div>
            <div className="mt-2">
              <span className="font-bold text-on-surface block text-[11px]">5. Assigned</span>
              <span className={`text-[10px] font-medium ${isPickedUp ? 'text-emerald-700' : 'text-primary'}`}>
                Elena R. (Van 12)
              </span>
            </div>
          </div>

          {/* 6. Food Picked Up */}
          <div className={`p-2.5 rounded-xl border flex flex-col justify-between transition-all ${
            isPickedUp ? 'bg-slate-50 border-slate-200' : 'bg-slate-50 border-slate-100 opacity-60'
          }`}>
            <div className="flex items-center justify-between">
              <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                isPickedUp ? 'bg-emerald-600 text-white' : 'bg-slate-300 text-slate-600'
              }`}>
                {isPickedUp ? '✓' : '○'}
              </span>
              <span className="text-[9px] text-slate-400">{activeMission.pickupVerifiedAt || 'Pending'}</span>
            </div>
            <div className="mt-2">
              <span className="font-bold text-on-surface block text-[11px]">6. Picked Up</span>
              <span className={`text-[10px] font-medium ${isPickedUp ? 'text-emerald-700' : 'text-slate-500'}`}>
                {isPickedUp ? 'OTP Verified ✓' : 'Awaiting OTP'}
              </span>
            </div>
          </div>

          {/* 7. In Transit */}
          <div className={`p-2.5 rounded-xl border flex flex-col justify-between transition-all ${
            isDelivered ? 'bg-slate-50 border-slate-200' : isPickedUp ? 'bg-teal-50 border-teal-300 ring-2 ring-teal-200' : 'bg-slate-50 border-slate-100 opacity-60'
          }`}>
            <div className="flex items-center justify-between">
              <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                isDelivered ? 'bg-emerald-600 text-white' : isPickedUp ? 'bg-teal-600 text-white animate-pulse' : 'bg-slate-300 text-slate-600'
              }`}>
                {isDelivered ? '✓' : isPickedUp ? '●' : '○'}
              </span>
              <span className="text-[9px] text-slate-400">1.8 km</span>
            </div>
            <div className="mt-2">
              <span className="font-bold text-on-surface block text-[11px]">7. In Transit</span>
              <span className={`text-[10px] font-medium ${isDelivered ? 'text-emerald-700' : isPickedUp ? 'text-teal-700' : 'text-slate-500'}`}>
                {isDelivered ? 'Arrived ✓' : isPickedUp ? 'Moving ~7m' : 'Pending'}
              </span>
            </div>
          </div>

          {/* 8. Delivered */}
          <div className={`p-2.5 rounded-xl border flex flex-col justify-between ${
            isDelivered ? 'bg-emerald-50 border-emerald-200 text-emerald-900' : 'bg-slate-50 border-slate-100 opacity-60'
          }`}>
            <div className="flex items-center justify-between">
              <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                isDelivered ? 'bg-emerald-600 text-white' : 'bg-slate-300 text-slate-600'
              }`}>
                {isDelivered ? '✓' : '○'}
              </span>
              <span className="text-[9px] text-slate-400">{activeMission.deliveryVerifiedAt || 'Final'}</span>
            </div>
            <div className="mt-2">
              <span className="font-bold block text-[11px]">8. Delivered</span>
              <span className={`text-[10px] font-medium ${isDelivered ? 'text-emerald-700 font-bold' : 'text-slate-500'}`}>
                {isDelivered ? 'Completed ✓' : 'Awaiting OTP'}
              </span>
            </div>
          </div>

        </div>
      </section>

      {/* Complete Movement Map & Route Corridor */}
      <section className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200/80 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div>
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[20px]">near_me</span>
              <h3 className="font-headline-sm text-base font-bold text-on-surface">
                Coimbatore Transit Movement Corridor
              </h3>
            </div>
            <p className="text-xs text-slate-500">
              🍱 Food Giver → 🚚 Transporter → 🏠 Receiver
            </p>
          </div>

          <div className="flex items-center gap-2 text-xs">
            <span className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 font-semibold">
              Route: 1.8 km (~7 min)
            </span>
            <span className="px-2.5 py-1 rounded-lg bg-teal-50 text-teal-800 font-semibold">
              Volume: {activeMission.quantityMeals} meals
            </span>
          </div>
        </div>

        {/* Embedded Coimbatore Rescue Network Map */}
        <CoimbatoreRescueMap
          mode="mission"
          selectedRecipient={selectedRecipient}
          heightClass="h-72 sm:h-96"
          showAllRecipients={false}
        />
      </section>

      {/* Verification Handoffs: Dual OTP Verification Panels */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
        
        {/* Panel 1: Pickup OTP Verification */}
        <div className={`rounded-2xl p-5 sm:p-6 border transition-all ${
          isPickedUp
            ? 'bg-slate-50 border-slate-200'
            : 'bg-white border-primary/40 ring-2 ring-primary/10 shadow-md'
        }`}>
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[20px]">qr_code_scanner</span>
              <h3 className="font-headline-sm text-base font-bold text-on-surface">Pickup OTP Verification</h3>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
              isPickedUp ? 'bg-emerald-100 text-emerald-800' : 'bg-primary/10 text-primary'
            }`}>
              {isPickedUp ? 'Verified ✓' : 'Handoff Ready'}
            </span>
          </div>

          <div className="mt-4 space-y-4 text-xs">
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 space-y-1">
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Donor Origin</span>
              <div className="font-bold text-on-surface">{activeMission.donorName}</div>
              <div className="text-slate-500">{activeMission.donorAddress}</div>
            </div>

            {isPickedUp ? (
              <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 space-y-1">
                <div className="flex items-center gap-1.5 font-bold">
                  <span className="material-symbols-outlined text-[18px]">check_circle</span>
                  <span>Pickup Verified Successfully</span>
                </div>
                <p className="text-[11px] text-emerald-700">
                  Cargo released to Elena R. at {activeMission.pickupVerifiedAt || '7:42 PM'}. Food is currently In Transit.
                </p>
              </div>
            ) : (
              <form onSubmit={handleVerifyPickup} className="space-y-3">
                <div className="space-y-1">
                  <label className="text-[11px] font-semibold text-slate-600 block">
                    Enter Pickup 6-Digit OTP / Code (Demo: FB-4291)
                  </label>
                  <input
                    type="text"
                    value={pickupOtpInput}
                    onChange={(e) => setPickupOtpInput(e.target.value)}
                    placeholder="FB-4291"
                    className="w-full h-11 px-3.5 bg-slate-50 border border-slate-200 rounded-xl font-mono text-base font-bold text-on-surface uppercase focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  {pickupOtpError && (
                    <span className="text-[11px] text-red-600 font-semibold">{pickupOtpError}</span>
                  )}
                </div>

                <div className="flex items-center gap-2">
                  <button
                    type="submit"
                    disabled={isPickupSubmitting}
                    className="flex-1 h-11 rounded-xl bg-primary hover:bg-primary-container text-white font-bold text-xs shadow-sm flex items-center justify-center gap-1.5 active:scale-98 transition-all"
                  >
                    <span>{isPickupSubmitting ? 'Verifying...' : 'VERIFY PICKUP OTP'}</span>
                    <span className="material-symbols-outlined text-[16px]">check</span>
                  </button>

                  <button
                    type="button"
                    onClick={simulatePickupScan}
                    className="h-11 px-3.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition-colors shrink-0"
                    title="Simulate 1-Click Pickup"
                  >
                    1-Click
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>

        {/* Panel 2: Delivery OTP Verification */}
        <div className={`rounded-2xl p-5 sm:p-6 border transition-all ${
          isDelivered
            ? 'bg-emerald-50/50 border-emerald-200'
            : isPickedUp
            ? 'bg-white border-secondary/50 ring-2 ring-secondary/15 shadow-md'
            : 'bg-slate-50/70 border-slate-200 opacity-60'
        }`}>
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-secondary text-[20px]">pin</span>
              <h3 className="font-headline-sm text-base font-bold text-on-surface">Delivery OTP Confirmation</h3>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
              isDelivered
                ? 'bg-emerald-100 text-emerald-800'
                : isPickedUp
                ? 'bg-secondary-container text-on-secondary-container'
                : 'bg-slate-200 text-slate-600'
            }`}>
              {isDelivered ? 'Delivered ✓' : isPickedUp ? 'Awaiting Arrival' : 'Locked'}
            </span>
          </div>

          <div className="mt-4 space-y-4 text-xs">
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 space-y-1">
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Destination Shelter</span>
              <div className="font-bold text-on-surface">{activeMission.recipientName}</div>
              <div className="text-slate-500">{activeMission.recipientAddress}</div>
            </div>

            {isDelivered ? (
              <div className="p-4 rounded-xl bg-emerald-100 border border-emerald-300 text-emerald-900 space-y-2">
                <div className="flex items-center gap-1.5 font-bold text-sm">
                  <span className="material-symbols-outlined text-[20px] text-emerald-700">task_alt</span>
                  <span>Rescue Mission Completed!</span>
                </div>
                <p className="text-[11px] text-emerald-800">
                  Receiver confirmed 72 hot vegetarian meals received in safe Cambro containers at {activeMission.deliveryVerifiedAt || '8:02 PM'}.
                </p>
                <button
                  onClick={() => setActiveTab('impact')}
                  className="mt-1 w-full h-10 rounded-xl bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-xs shadow-sm flex items-center justify-center gap-1.5"
                >
                  <span>VIEW IMPACT &amp; AI FEEDBACK</span>
                  <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
                </button>
              </div>
            ) : isPickedUp ? (
              <form onSubmit={handleVerifyDelivery} className="space-y-3">
                <div className="space-y-1">
                  <label className="text-[11px] font-semibold text-slate-600 block">
                    Enter Delivery 6-Digit OTP / Code (Demo: FB-8834)
                  </label>
                  <input
                    type="text"
                    value={deliveryOtpInput}
                    onChange={(e) => setDeliveryOtpInput(e.target.value)}
                    placeholder="FB-8834"
                    className="w-full h-11 px-3.5 bg-slate-50 border border-slate-200 rounded-xl font-mono text-base font-bold text-on-surface uppercase focus:outline-none focus:ring-2 focus:ring-secondary/20 focus:border-secondary"
                  />
                  {deliveryOtpError && (
                    <span className="text-[11px] text-red-600 font-semibold">{deliveryOtpError}</span>
                  )}
                </div>

                <div className="flex items-center gap-2">
                  <button
                    type="submit"
                    disabled={isDeliverySubmitting}
                    className="flex-1 h-11 rounded-xl bg-secondary hover:bg-teal-700 text-white font-bold text-xs shadow-sm flex items-center justify-center gap-1.5 active:scale-98 transition-all"
                  >
                    <span>{isDeliverySubmitting ? 'Verifying...' : 'VERIFY DELIVERY OTP'}</span>
                    <span className="material-symbols-outlined text-[16px]">verified</span>
                  </button>

                  <button
                    type="button"
                    onClick={simulateDeliveryHandoff}
                    className="h-11 px-3.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition-colors shrink-0"
                    title="Simulate 1-Click Delivery"
                  >
                    1-Click
                  </button>
                </div>
              </form>
            ) : (
              <div className="p-3.5 rounded-xl bg-slate-100 text-slate-500 text-[11px] flex items-center gap-2">
                <span className="material-symbols-outlined text-[16px]">lock</span>
                <span>Delivery OTP activates after transporter completes donor cargo pickup.</span>
              </div>
            )}
          </div>
        </div>

      </div>

    </div>
  );
};
