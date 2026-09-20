import React from 'react';
import { useApp } from '../../context/AppContext';

export const HomeView: React.FC = () => {
  const { setActiveTab, runOneClickDemo, stats, currentRole, activeMission } = useApp();

  return (
    <div className="space-y-8 pb-16">
      
      {/* 0. Operations Overview Bar & Urgent Active Rescue Alert (Stitch Reference) */}
      <div className="space-y-3">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="font-headline-lg text-xl sm:text-2xl font-bold text-on-surface tracking-tight">
              Good afternoon, {currentRole === 'coordinator' ? 'Operations' : currentRole === 'food_giver' ? 'Donor Kitchen' : currentRole === 'transporter' ? 'Logistics Partner' : 'Community Shelter'}
            </h2>
            <p className="text-xs sm:text-sm text-on-surface-variant">
              Live intelligence for today's Coimbatore food rescue network.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveTab('predict')}
              className="px-3.5 py-2 bg-primary hover:bg-primary-container text-white rounded-xl text-xs font-bold shadow-sm flex items-center gap-1.5 transition-all"
            >
              <span className="material-symbols-outlined text-[16px]">add_circle</span>
              <span>+ New Prediction</span>
            </button>
          </div>
        </div>

        {/* Urgent Active Rescue Alert Banner */}
        <div className="relative overflow-hidden bg-error-container text-on-error-container rounded-2xl p-4 sm:p-5 shadow-sm border border-red-200">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-error text-white flex items-center justify-center shrink-0 animate-bounce">
                <span className="material-symbols-outlined text-[22px]">notification_important</span>
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-label-sm text-[10px] uppercase font-extrabold tracking-wider text-error">
                    HIGH RESCUE PRIORITY
                  </span>
                  <span className="w-2 h-2 rounded-full bg-error animate-ping"></span>
                </div>
                <h3 className="font-headline-sm text-sm sm:text-base font-bold text-on-error-container mt-0.5">
                  Mission #{activeMission?.id || 'FB-2026-0042'}: 72 Meals Ready in Coimbatore
                </h3>
                <p className="text-xs text-on-error-container/90 mt-0.5">
                  Grand Palace Demo Kitchen (Race Course) → Hope Community Kitchen (Gandhipuram, 1.8 km)
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 shrink-0">
              <button
                onClick={() => setActiveTab('mission')}
                className="px-4 py-2 bg-error hover:bg-red-700 text-white rounded-xl font-semibold text-xs shadow-sm flex items-center gap-1.5 active:scale-95 transition-all"
              >
                <span>Open Mission</span>
                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* 1. Hero Section */}
      <section className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-primary via-primary-container to-brand-dark text-white p-8 sm:p-12 lg:p-16 shadow-xl">
        {/* Background Ambient Glows */}
        <div className="absolute top-0 right-0 w-96 h-96 bg-brand-mint/20 rounded-full blur-3xl pointer-events-none -mr-20 -mt-20"></div>
        <div className="absolute bottom-0 left-1/3 w-72 h-72 bg-brand-warning/10 rounded-full blur-2xl pointer-events-none"></div>

        <div className="relative z-10 max-w-4xl space-y-6">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white/10 backdrop-blur-md border border-white/15 text-brand-mint text-xs font-semibold uppercase tracking-wider">
            <span className="material-symbols-outlined text-[16px]">psychology</span>
            <span>Predictive Food Rescue • 18h Hackathon Edition</span>
          </div>

          <h1 className="font-display-hero text-3xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight leading-tight">
            From Surplus to Smiles.
          </h1>

          <p className="text-lg sm:text-xl text-slate-200 max-w-2xl font-normal leading-relaxed">
            FoodBridge connects surplus food with people who need it. AI predicts potential food surplus before it becomes waste, then helps coordinate verified rescue.
          </p>

          <div className="pt-2 flex flex-wrap items-center gap-4">
            <button
              onClick={() => setActiveTab('predict')}
              className="h-12 px-7 rounded-xl bg-brand-mint hover:bg-white text-brand-dark font-label-md text-base font-bold shadow-lg shadow-brand-mint/20 flex items-center gap-2.5 transition-all active:scale-95"
            >
              <span>Predict New Surplus</span>
              <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
            </button>

            <button
              onClick={runOneClickDemo}
              className="h-12 px-6 rounded-xl bg-white/10 hover:bg-white/20 text-white font-label-md text-base font-semibold border border-white/20 backdrop-blur-sm flex items-center gap-2 transition-all active:scale-95"
            >
              <span className="material-symbols-outlined text-[20px] text-brand-mint">play_circle</span>
              <span>Run 1-Click Demo</span>
            </button>
          </div>

          <div className="pt-4 flex items-center gap-6 text-xs text-slate-300">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px] text-brand-mint">verified</span>
              <span>Human-in-the-Loop Verification</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px] text-brand-mint">speed</span>
              <span>Deterministic ML Modeling</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px] text-brand-mint">qr_code_2</span>
              <span>Dual QR/OTP Chain of Custody</span>
            </div>
          </div>
        </div>
      </section>

      {/* 2. Visual Bridge Concept Diagram */}
      <section className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/80 shadow-sm">
        <div className="text-center max-w-xl mx-auto mb-8">
          <span className="font-label-sm text-xs text-primary font-bold uppercase tracking-wider">
            Operational Architecture
          </span>
          <h2 className="font-headline-lg text-xl sm:text-2xl font-bold text-on-surface mt-1">
            The FoodBridge Connection Chain
          </h2>
          <p className="text-sm text-slate-500 mt-1">
            Transforming volatile banquet surplus into dignified warm meals in under 60 minutes.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 relative">
          
          {/* Node 1: Surplus Food */}
          <div className="bg-slate-50 rounded-xl p-5 border border-slate-200/60 flex flex-col items-center text-center relative group hover:border-primary/40 transition-colors">
            <div className="w-12 h-12 rounded-2xl bg-tertiary/10 text-tertiary flex items-center justify-center mb-3">
              <span className="material-symbols-outlined text-[26px]">skillet</span>
            </div>
            <span className="font-label-sm text-[11px] uppercase tracking-wider text-slate-400 font-bold">Origin</span>
            <h3 className="font-headline-sm text-base font-bold text-on-surface mt-0.5">Surplus Food</h3>
            <p className="text-xs text-slate-500 mt-1">
              Banquets, weddings, hotels, catering hubs preparing for large gatherings.
            </p>
            <span className="mt-3 px-2 py-0.5 rounded-full bg-tertiary-container/30 text-tertiary text-[10px] font-bold">
              Potential Waste Hazard
            </span>
          </div>

          {/* Node 2: FoodBridge AI */}
          <div className="bg-primary/5 rounded-xl p-5 border-2 border-primary/30 flex flex-col items-center text-center relative group shadow-xs">
            <div className="w-12 h-12 rounded-2xl bg-primary text-white flex items-center justify-center mb-3 shadow-sm shadow-primary/20">
              <span className="material-symbols-outlined text-[26px]">psychology</span>
            </div>
            <span className="font-label-sm text-[11px] uppercase tracking-wider text-primary font-bold">Core Platform</span>
            <h3 className="font-headline-sm text-base font-bold text-primary mt-0.5">FoodBridge AI</h3>
            <p className="text-xs text-slate-600 mt-1">
              Predicts surplus early using attendance velocity, weather, and historical intake patterns.
            </p>
            <span className="mt-3 px-2 py-0.5 rounded-full bg-secondary-container text-on-secondary-container text-[10px] font-bold">
              Predict &amp; Match Engine
            </span>
          </div>

          {/* Node 3: Verified Recipients */}
          <div className="bg-slate-50 rounded-xl p-5 border border-slate-200/60 flex flex-col items-center text-center relative group hover:border-primary/40 transition-colors">
            <div className="w-12 h-12 rounded-2xl bg-secondary-container/40 text-secondary flex items-center justify-center mb-3">
              <span className="material-symbols-outlined text-[26px]">verified_user</span>
            </div>
            <span className="font-label-sm text-[11px] uppercase tracking-wider text-slate-400 font-bold">Destination</span>
            <h3 className="font-headline-sm text-base font-bold text-on-surface mt-0.5">Verified Recipients</h3>
            <p className="text-xs text-slate-500 mt-1">
              Community kitchens, shelters, and food banks with audited hygiene certifications.
            </p>
            <span className="mt-3 px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 text-[10px] font-bold">
              100% Vetted Non-Profits
            </span>
          </div>

          {/* Node 4: People Served */}
          <div className="bg-slate-50 rounded-xl p-5 border border-slate-200/60 flex flex-col items-center text-center relative group hover:border-primary/40 transition-colors">
            <div className="w-12 h-12 rounded-2xl bg-brand-success/10 text-brand-success flex items-center justify-center mb-3">
              <span className="material-symbols-outlined text-[26px]">diversity_3</span>
            </div>
            <span className="font-label-sm text-[11px] uppercase tracking-wider text-slate-400 font-bold">Outcome</span>
            <h3 className="font-headline-sm text-base font-bold text-on-surface mt-0.5">People Served</h3>
            <p className="text-xs text-slate-500 mt-1">
              Families, seniors, and unhoused neighbors receiving hot, nutritious meals.
            </p>
            <span className="mt-3 px-2 py-0.5 rounded-full bg-brand-success/20 text-emerald-800 text-[10px] font-bold">
              Dignified Nourishment
            </span>
          </div>

        </div>
      </section>

      {/* 3. Demo Impact Statistics (Clearly labeled DEMO DATA) */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">analytics</span>
            <h2 className="font-headline-lg text-xl font-bold text-on-surface">Platform Impact Telemetry</h2>
          </div>
          <span className="px-2.5 py-0.5 rounded-full bg-tertiary-container/30 text-tertiary font-label-sm text-xs font-bold uppercase tracking-wider">
            DEMO DATA
          </span>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Card 1: Meals Predicted */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
            <div className="flex items-center justify-between text-slate-500">
              <span className="font-label-sm text-xs font-semibold uppercase tracking-wider">Meals Predicted</span>
              <div className="w-8 h-8 rounded-lg bg-surface-container flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[18px]">psychology</span>
              </div>
            </div>
            <div className="mt-3">
              <div className="font-data-display text-3xl font-extrabold text-on-surface tabular-nums">
                {stats.predictedSurplusMeals.toLocaleString()}
              </div>
              <div className="flex items-center gap-1 mt-1 text-xs text-secondary font-medium">
                <span className="material-symbols-outlined text-[14px]">trending_up</span>
                <span>Early Surplus Detection</span>
              </div>
            </div>
          </div>

          {/* Card 2: Meals Rescued */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
            <div className="flex items-center justify-between text-slate-500">
              <span className="font-label-sm text-xs font-semibold uppercase tracking-wider">Meals Rescued</span>
              <div className="w-8 h-8 rounded-lg bg-secondary-container/40 flex items-center justify-center text-secondary">
                <span className="material-symbols-outlined text-[18px]">task_alt</span>
              </div>
            </div>
            <div className="mt-3">
              <div className="font-data-display text-3xl font-extrabold text-on-surface tabular-nums">
                {stats.rescuedMeals.toLocaleString()}
              </div>
              <div className="flex items-center gap-1 mt-1 text-xs text-brand-success font-medium">
                <span className="material-symbols-outlined text-[14px]">verified</span>
                <span>{stats.rescueSuccessRate}% rescue success rate</span>
              </div>
            </div>
          </div>

          {/* Card 3: People Served */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
            <div className="flex items-center justify-between text-slate-500">
              <span className="font-label-sm text-xs font-semibold uppercase tracking-wider">People Served</span>
              <div className="w-8 h-8 rounded-lg bg-surface-container flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[18px]">groups</span>
              </div>
            </div>
            <div className="mt-3">
              <div className="font-data-display text-3xl font-extrabold text-on-surface tabular-nums">
                {stats.peopleServed.toLocaleString()}
              </div>
              <div className="flex items-center gap-1 mt-1 text-xs text-slate-500 font-medium">
                <span className="material-symbols-outlined text-[14px]">storefront</span>
                <span>{stats.verifiedPartnersCount} verified partners</span>
              </div>
            </div>
          </div>

          {/* Card 4: Waste & CO2e Avoided */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
            <div className="flex items-center justify-between text-slate-500">
              <span className="font-label-sm text-xs font-semibold uppercase tracking-wider">Waste Avoided</span>
              <div className="w-8 h-8 rounded-lg bg-tertiary-container/30 flex items-center justify-center text-tertiary">
                <span className="material-symbols-outlined text-[18px]">eco</span>
              </div>
            </div>
            <div className="mt-3">
              <div className="font-data-display text-3xl font-extrabold text-on-surface tabular-nums">
                {stats.foodWasteKgAvoided} kg
              </div>
              <div className="flex items-center gap-1 mt-1 text-xs text-tertiary font-medium">
                <span className="material-symbols-outlined text-[14px]">co2</span>
                <span>~{stats.co2eAvoidedKg.toFixed(0)} kg CO2e saved</span>
              </div>
            </div>
          </div>

        </div>
      </section>

      {/* 4. "How FoodBridge Works" Stepper */}
      <section className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/80 shadow-sm space-y-6">
        <div>
          <span className="font-label-sm text-xs text-primary font-bold uppercase tracking-wider">
            Canonical Workflow
          </span>
          <h2 className="font-headline-lg text-xl sm:text-2xl font-bold text-on-surface mt-1">
            How FoodBridge Works
          </h2>
          <p className="text-sm text-slate-500 mt-1">
            Predict → Match → Verify → Rescue → Impact
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-5 gap-4 pt-2">
          
          <div className="flex flex-col items-center text-center p-4 rounded-xl bg-slate-50 border border-slate-200/60">
            <div className="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center font-bold text-sm mb-2 shadow-xs">
              1
            </div>
            <h4 className="font-headline-sm text-sm font-bold text-on-surface">Predict</h4>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              ML computes intake based on guests, weather &amp; real-time attendance.
            </p>
          </div>

          <div className="flex flex-col items-center text-center p-4 rounded-xl bg-slate-50 border border-slate-200/60">
            <div className="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center font-bold text-sm mb-2 shadow-xs">
              2
            </div>
            <h4 className="font-headline-sm text-sm font-bold text-on-surface">Match</h4>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              Algorithm scores verified recipients by need, diet compatibility &amp; transit distance.
            </p>
          </div>

          <div className="flex flex-col items-center text-center p-4 rounded-xl bg-slate-50 border border-slate-200/60">
            <div className="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center font-bold text-sm mb-2 shadow-xs">
              3
            </div>
            <h4 className="font-headline-sm text-sm font-bold text-on-surface">Verify</h4>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              Human kitchen director confirms food quantity and temperature compliance before dispatch.
            </p>
          </div>

          <div className="flex flex-col items-center text-center p-4 rounded-xl bg-slate-50 border border-slate-200/60">
            <div className="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center font-bold text-sm mb-2 shadow-xs">
              4
            </div>
            <h4 className="font-headline-sm text-sm font-bold text-on-surface">Rescue</h4>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              End-to-end QR code and OTP verification at pickup and delivery handoff.
            </p>
          </div>

          <div className="flex flex-col items-center text-center p-4 rounded-xl bg-slate-50 border border-slate-200/60">
            <div className="w-10 h-10 rounded-full bg-brand-success text-white flex items-center justify-center font-bold text-sm mb-2 shadow-xs">
              5
            </div>
            <h4 className="font-headline-sm text-sm font-bold text-on-surface">Impact</h4>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              Actual vs predicted variance logged to feedback dataset for continuous model tuning.
            </p>
          </div>

        </div>

        {/* Core Philosophy Banner */}
        <div className="bg-brand-dark text-white p-6 rounded-xl flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="space-y-1 text-center sm:text-left">
            <div className="text-xs uppercase tracking-widest text-brand-mint font-bold">
              Core Platform Philosophy
            </div>
            <div className="text-lg font-bold">
              AI + Human Verification = Responsible Food Rescue
            </div>
            <div className="text-xs text-slate-300">
              AI recommends. Humans verify. FoodBridge coordinates.
            </div>
          </div>
          <button
            onClick={() => setActiveTab('predict')}
            className="h-10 px-5 rounded-lg bg-brand-teal hover:bg-brand-mint text-white font-semibold text-xs whitespace-nowrap transition-colors flex items-center gap-1.5"
          >
            <span>Launch Prediction Studio</span>
            <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
          </button>
        </div>
      </section>

    </div>
  );
};
