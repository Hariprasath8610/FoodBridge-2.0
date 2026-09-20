import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import type { WeatherCondition, FoodCategory } from '../../types';
import { RiskBadge } from '../common/RiskBadge';

export const PredictView: React.FC = () => {
  const {
    predictionInput,
    setPredictionInput,
    predictionResult,
    isRecalculating,
    recalculatePrediction,
    setActiveTab
  } = useApp();

  const [notification, setNotification] = useState<string | null>(null);

  const handleRecalculate = async (e: React.FormEvent) => {
    e.preventDefault();
    await recalculatePrediction();
    setNotification('✓ Prediction Updated');
    setTimeout(() => setNotification(null), 3000);
  };

  const attendanceRatio = Math.round(
    (predictionInput.currentAttendance / Math.max(1, predictionInput.expectedGuests)) * 100
  );

  return (
    <div className="space-y-8 pb-16">
      
      {/* Intro Header */}
      <div className="space-y-1">
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-secondary-container/40 text-on-secondary-container">
          <span className="material-symbols-outlined text-[15px] text-secondary">psychology</span>
          <span className="font-label-sm text-xs uppercase tracking-wider font-bold">Predictive Telemetry v4.2</span>
        </div>
        <h1 className="font-headline-xl text-2xl sm:text-3xl font-bold text-on-surface tracking-tight">
          Predict Surplus Before It Becomes Waste
        </h1>
        <p className="font-body-md text-slate-500 max-w-2xl">
          Tell us what you're preparing. FoodBridge correlates real-time check-ins, transit delays, and weather to predict remaining meals with deterministic accuracy.
        </p>
      </div>

      {notification && (
        <div className="p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl text-xs font-semibold flex items-center gap-2 animate-fade-in">
          <span className="material-symbols-outlined text-[18px]">check_circle</span>
          <span>{notification}</span>
        </div>
      )}

      {/* Main Grid: Form Inputs & AI Intelligence Panel */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        
        {/* Left Column: Event & Kitchen Input Form (7 cols) */}
        <div className="lg:col-span-7 bg-white rounded-2xl p-6 sm:p-8 border border-slate-200/80 shadow-sm space-y-6">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-surface-container flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[20px]">restaurant_menu</span>
              </div>
              <h2 className="font-headline-sm text-lg font-bold text-on-surface">Event &amp; Kitchen Details</h2>
            </div>
            <span className="px-2.5 py-0.5 rounded-full bg-surface-container text-primary font-label-sm text-xs font-semibold">
              Live Calibration
            </span>
          </div>

          <form onSubmit={handleRecalculate} className="space-y-5">
            
            {/* Event Type & Food Category */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="font-label-sm text-xs text-slate-500 font-medium">Event Type</label>
                <select
                  value={predictionInput.eventType}
                  onChange={(e) => setPredictionInput(prev => ({ ...prev, eventType: e.target.value }))}
                  className="w-full h-11 px-3 bg-slate-50 border border-slate-200 rounded-xl font-body-md text-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                >
                  <option value="Wedding Banquet">Wedding Banquet (90% baseline)</option>
                  <option value="College Fest">College Fest (88% baseline)</option>
                  <option value="Hostel Dinner">Hostel Dinner (92% baseline)</option>
                  <option value="Hotel Gala">Hotel Gala (90% baseline)</option>
                  <option value="Restaurant">Restaurant Catering (87% baseline)</option>
                  <option value="Corporate Summit">Corporate Summit (89% baseline)</option>
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="font-label-sm text-xs text-slate-500 font-medium">Food Category</label>
                <select
                  value={predictionInput.foodCategory}
                  onChange={(e) => setPredictionInput(prev => ({ ...prev, foodCategory: e.target.value as FoodCategory }))}
                  className="w-full h-11 px-3 bg-slate-50 border border-slate-200 rounded-xl font-body-md text-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                >
                  <option value="Vegetarian">Vegetarian Banquet</option>
                  <option value="Non-Vegetarian">Non-Vegetarian Banquet</option>
                  <option value="Mixed">Mixed Catering</option>
                  <option value="Vegan">Pure Vegan Spread</option>
                </select>
              </div>
            </div>

            {/* Expected Guests, Planned Meals, Current Attendance */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              
              <div className="space-y-1.5">
                <label className="font-label-sm text-xs text-slate-500 font-medium">Expected Guests</label>
                <div className="relative">
                  <input
                    type="number"
                    min="10"
                    max="5000"
                    value={predictionInput.expectedGuests}
                    onChange={(e) => setPredictionInput(prev => ({ ...prev, expectedGuests: Number(e.target.value) }))}
                    className="w-full h-11 pl-9 pr-3 bg-slate-50 border border-slate-200 rounded-xl font-body-md text-sm font-semibold text-on-surface tabular-nums focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  <span className="material-symbols-outlined text-slate-400 text-[18px] absolute left-2.5 top-3">
                    group
                  </span>
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="font-label-sm text-xs text-slate-500 font-medium">Planned Meals</label>
                <div className="relative">
                  <input
                    type="number"
                    min="10"
                    max="5000"
                    value={predictionInput.plannedMeals}
                    onChange={(e) => setPredictionInput(prev => ({ ...prev, plannedMeals: Number(e.target.value) }))}
                    className="w-full h-11 pl-9 pr-3 bg-slate-50 border border-slate-200 rounded-xl font-body-md text-sm font-semibold text-on-surface tabular-nums focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  <span className="material-symbols-outlined text-slate-400 text-[18px] absolute left-2.5 top-3">
                    skillet
                  </span>
                </div>
              </div>

              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="font-label-sm text-xs text-slate-500 font-medium">Current Attendance</label>
                  <span className="text-[11px] font-bold text-secondary">{attendanceRatio}% checked in</span>
                </div>
                <div className="relative">
                  <input
                    type="number"
                    min="0"
                    max="5000"
                    value={predictionInput.currentAttendance}
                    onChange={(e) => setPredictionInput(prev => ({ ...prev, currentAttendance: Number(e.target.value) }))}
                    className="w-full h-11 pl-9 pr-3 bg-slate-50 border border-slate-200 rounded-xl font-body-md text-sm font-semibold text-on-surface tabular-nums focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  <span className="material-symbols-outlined text-secondary text-[18px] absolute left-2.5 top-3">
                    how_to_reg
                  </span>
                </div>
              </div>

            </div>

            {/* Serving Window & Dispatch Origin */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="font-label-sm text-xs text-slate-500 font-medium">Serving Window</label>
                <div className="relative">
                  <input
                    type="text"
                    value={predictionInput.servingTime}
                    onChange={(e) => setPredictionInput(prev => ({ ...prev, servingTime: e.target.value }))}
                    className="w-full h-11 pl-9 pr-3 bg-slate-50 border border-slate-200 rounded-xl font-body-md text-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  <span className="material-symbols-outlined text-primary text-[18px] absolute left-2.5 top-3">
                    schedule
                  </span>
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="font-label-sm text-xs text-slate-500 font-medium">Dispatch Origin / Venue</label>
                <div className="relative">
                  <input
                    type="text"
                    value={predictionInput.location}
                    onChange={(e) => setPredictionInput(prev => ({ ...prev, location: e.target.value }))}
                    className="w-full h-11 pl-9 pr-3 bg-slate-50 border border-slate-200 rounded-xl font-body-md text-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary truncate"
                  />
                  <span className="material-symbols-outlined text-primary text-[18px] absolute left-2.5 top-3">
                    pin_drop
                  </span>
                </div>
              </div>
            </div>

            {/* Weather Simulation Section */}
            <div className="p-4 rounded-xl bg-slate-50 border border-slate-200/80 space-y-3">
              <div className="flex items-center justify-between">
                <span className="font-label-sm text-xs uppercase tracking-wider font-bold text-slate-600 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px] text-tertiary">thunderstorm</span>
                  Weather Simulation Factor
                </span>
                <span className="text-[11px] font-bold text-tertiary bg-tertiary-container/20 px-2 py-0.5 rounded-full">
                  DEMO WEATHER DATA
                </span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs text-slate-500">Condition</label>
                  <select
                    value={predictionInput.weatherCondition}
                    onChange={(e) => setPredictionInput(prev => ({ ...prev, weatherCondition: e.target.value as WeatherCondition }))}
                    className="w-full h-10 px-3 bg-white border border-slate-200 rounded-lg text-xs font-semibold text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
                  >
                    <option value="Heavy Rain">Heavy Rain (-10% late arrival factor)</option>
                    <option value="Moderate Rain">Moderate Rain (-6% factor)</option>
                    <option value="Light Rain">Light Rain (-3% factor)</option>
                    <option value="Overcast">Overcast (-2% factor)</option>
                    <option value="Clear">Clear Skies (Standard baseline)</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <div className="flex justify-between text-xs text-slate-500">
                    <span>Rain Probability</span>
                    <span className="font-bold text-tertiary">{predictionInput.rainProbability}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={predictionInput.rainProbability}
                    onChange={(e) => setPredictionInput(prev => ({ ...prev, rainProbability: Number(e.target.value) }))}
                    className="w-full accent-primary mt-2"
                  />
                </div>
              </div>
            </div>

            {/* Recalculate AI Button */}
            <button
              type="submit"
              disabled={isRecalculating}
              className="w-full h-12 bg-primary hover:bg-primary-container text-white rounded-xl font-label-md text-sm font-bold flex items-center justify-center gap-2 shadow-md shadow-primary/20 active:scale-[0.99] transition-all disabled:opacity-75"
            >
              {isRecalculating ? (
                <>
                  <span className="material-symbols-outlined text-[20px] animate-spin">autorenew</span>
                  <span>Analyzing Event Data...</span>
                </>
              ) : (
                <>
                  <span className="material-symbols-outlined text-[20px]">calculate</span>
                  <span>Recalculate AI Surplus Prediction</span>
                </>
              )}
            </button>

          </form>
        </div>

        {/* Right Column: AI Surplus Intelligence Panel & Explainable AI (5 cols) */}
        <div className="lg:col-span-5 space-y-6">
          
          {/* Continuous Processing State Indicator */}
          <div className="bg-slate-50 rounded-2xl p-5 border border-slate-200/80 space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className={`material-symbols-outlined text-primary text-[18px] ${isRecalculating ? 'animate-spin' : ''}`}>
                  autorenew
                </span>
                <span className="font-label-md text-xs font-bold text-on-surface uppercase tracking-wide">
                  Continuous Engine Synthesis
                </span>
              </div>
              <span className="font-label-sm text-xs text-secondary font-bold">
                {isRecalculating ? 'Synthesizing...' : 'Calibrated'}
              </span>
            </div>

            <div className="space-y-1.5 text-xs text-slate-600">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                <span>Real-time check-in stream ({predictionInput.currentAttendance} verified)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                <span>Storm velocity alert: {predictionInput.weatherCondition} ({predictionInput.rainProbability}%)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                <span>Correlated with 30+ regional {predictionInput.eventType} profiles</span>
              </div>
              <div className="flex items-center gap-2 text-primary font-semibold">
                <span className="material-symbols-outlined text-[16px]">insights</span>
                <span>Surplus confidence calibrated to {predictionResult.surplusProbability}%</span>
              </div>
            </div>

            {/* Micro Progress */}
            <div className="w-full bg-slate-200 h-1.5 rounded-full overflow-hidden">
              <div 
                className="bg-primary h-full rounded-full transition-all duration-500" 
                style={{ width: `${isRecalculating ? 40 : 100}%` }}
              ></div>
            </div>
          </div>

          {/* AI Result Card (Obsidian Dark Surface #0F172A) */}
          <div className="bg-brand-dark rounded-2xl p-6 text-white shadow-xl space-y-6 relative overflow-hidden border border-white/10">
            {/* Ambient Glow */}
            <div className="absolute -top-16 -right-16 w-40 h-40 rounded-full bg-brand-teal/30 blur-3xl pointer-events-none"></div>

            {/* Card Header */}
            <div className="flex items-center justify-between relative z-10">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-brand-mint text-[22px]">smart_toy</span>
                <span className="font-label-sm text-xs font-bold tracking-widest text-slate-300 uppercase">
                  AI Surplus Intelligence
                </span>
              </div>
              <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-white/10 text-brand-mint text-xs font-semibold">
                <span className="w-2 h-2 rounded-full bg-brand-mint animate-pulse"></span>
                <span>Deterministic v4.2</span>
              </div>
            </div>

            {/* Metrics Grid */}
            <div className="grid grid-cols-2 gap-3 relative z-10">
              
              {/* Expected Intake */}
              <div className="bg-white/5 rounded-xl p-4 border border-white/5 flex flex-col justify-between">
                <span className="font-label-sm text-xs text-slate-400 uppercase tracking-wider">Expected Intake</span>
                <div className="my-2">
                  <span className="font-headline-xl text-3xl font-extrabold tracking-tight text-white tabular-nums">
                    {predictionResult.expectedConsumptionMin}–{predictionResult.expectedConsumptionMax}
                  </span>
                </div>
                <span className="text-xs text-slate-400">Meals consumed by guests</span>
              </div>

              {/* Predicted Surplus */}
              <div className="bg-primary/30 rounded-xl p-4 border border-brand-teal/40 flex flex-col justify-between">
                <div className="flex items-center justify-between">
                  <span className="font-label-sm text-xs text-brand-mint uppercase tracking-wider font-bold">
                    Predicted Surplus
                  </span>
                  <span className="material-symbols-outlined text-brand-mint text-[18px]">verified</span>
                </div>
                <div className="my-2">
                  <span className="font-headline-xl text-3xl font-extrabold tracking-tight text-brand-mint tabular-nums">
                    {predictionResult.surplusMin}–{predictionResult.surplusMax}
                  </span>
                </div>
                <span className="text-xs text-slate-200">Rescueable hot meals</span>
              </div>

            </div>

            {/* Risk & Probability Bar */}
            <div className="bg-white/5 rounded-xl p-4 space-y-3 relative z-10 border border-white/5">
              <div className="flex items-center justify-between">
                <RiskBadge level={predictionResult.riskLevel} />
                <div className="text-right">
                  <span className="text-xs text-slate-400">Surplus Probability:</span>
                  <span className="font-headline-sm text-lg font-bold text-brand-mint ml-1 tabular-nums">
                    {predictionResult.surplusProbability}%
                  </span>
                </div>
              </div>

              {/* Risk Gauge Bar */}
              <div className="space-y-1.5">
                <div className="grid grid-cols-3 gap-1.5 h-2 w-full">
                  <div className={`rounded-full ${predictionResult.surplusProbability < 40 ? 'bg-brand-success' : 'bg-white/20'}`}></div>
                  <div className={`rounded-full ${predictionResult.surplusProbability >= 40 && predictionResult.surplusProbability < 75 ? 'bg-brand-warning' : 'bg-white/20'}`}></div>
                  <div className={`rounded-full ${predictionResult.surplusProbability >= 75 ? 'bg-brand-risk' : 'bg-white/20'}`}></div>
                </div>
                <div className="flex justify-between font-label-sm text-[11px] text-slate-400 px-0.5">
                  <span>Low Risk</span>
                  <span>Moderate</span>
                  <span className="text-brand-risk font-semibold">High Exposure ★</span>
                </div>
              </div>
            </div>

            {/* Action CTA: Move to Recipient Matching */}
            <div className="pt-2">
              <button
                onClick={() => setActiveTab('matching')}
                className="w-full h-11 rounded-xl bg-brand-mint hover:bg-white text-brand-dark font-label-md text-sm font-bold flex items-center justify-center gap-2 shadow-lg shadow-brand-mint/20 transition-all active:scale-95"
              >
                <span>Find Compatible Recipients</span>
                <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
              </button>
            </div>

          </div>

          {/* Explainable AI Factors */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-4">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[20px]">explore</span>
              <h3 className="font-headline-sm text-base font-bold text-on-surface">
                Why is surplus predicted?
              </h3>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/60 space-y-1">
                <div className="font-semibold text-slate-700 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px] text-tertiary">thunderstorm</span>
                  <span>Weather Impact</span>
                </div>
                <p className="text-slate-500 leading-relaxed">
                  {predictionResult.factors.weatherImpact}
                </p>
              </div>

              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/60 space-y-1">
                <div className="font-semibold text-slate-700 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px] text-secondary">trending_up</span>
                  <span>Attendance Trajectory</span>
                </div>
                <p className="text-slate-500 leading-relaxed">
                  {predictionResult.factors.attendanceTrajectory}
                </p>
              </div>

              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/60 space-y-1">
                <div className="font-semibold text-slate-700 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px] text-primary">analytics</span>
                  <span>Historical Consumption Pattern</span>
                </div>
                <p className="text-slate-500 leading-relaxed">
                  {predictionResult.factors.historicalPattern}
                </p>
              </div>
            </div>
          </div>

        </div>

      </div>

    </div>
  );
};
