import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';

export const ImpactView: React.FC = () => {
  const { latestImpact, runOneClickDemo, isDemoRunning } = useApp();
  const [feedbackConfirmed, setFeedbackConfirmed] = useState(false);

  const impact = latestImpact || {
    missionId: 'FB-2026-0042',
    predictedMeals: 70,
    actualMeals: 72,
    variancePercentage: 2.8,
    mealsRescued: 72,
    peopleServed: 72,
    foodWasteKgAvoided: 36.0,
    co2eAvoidedKg: 90.0,
    feedbackStored: true,
    recordedAt: '8:42 PM'
  };

  const storedDataset = [
    {
      id: 'FB-LOG-042',
      event: 'Wedding Banquet',
      weather: 'Heavy Rain (75%)',
      predicted: 70,
      actual: 72,
      variance: '+2.8%',
      lossFactor: 'Transit Delays',
      status: 'Indexed for Batch Retraining'
    },
    {
      id: 'FB-LOG-041',
      event: 'College Fest',
      weather: 'Clear (10%)',
      predicted: 120,
      actual: 116,
      variance: '-3.3%',
      lossFactor: 'Buffet Overrun',
      status: 'Indexed for Batch Retraining'
    },
    {
      id: 'FB-LOG-040',
      event: 'Hotel Gala',
      weather: 'Moderate Rain (50%)',
      predicted: 85,
      actual: 87,
      variance: '+2.3%',
      lossFactor: 'Cold Weather',
      status: 'Indexed for Batch Retraining'
    }
  ];

  return (
    <div className="space-y-8 pb-16">
      
      {/* Intro Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-1">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-secondary-container/40 text-on-secondary-container">
            <span className="material-symbols-outlined text-[15px] text-secondary">insights</span>
            <span className="font-label-sm text-xs uppercase tracking-wider font-bold">Social Impact &amp; ML Telemetry</span>
          </div>
          <h1 className="font-headline-xl text-2xl sm:text-3xl font-bold text-on-surface tracking-tight">
            Verified Rescue Impact &amp; Feedback Dataset
          </h1>
          <p className="font-body-md text-slate-500 max-w-2xl">
            Realized social outcomes from Mission {impact.missionId} and ground-truth validation for continuous model tuning.
          </p>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          <span className="px-3 py-1 rounded-full bg-tertiary-container/30 text-tertiary text-xs font-bold uppercase tracking-wider">
            DEMO DATA
          </span>
          <button
            onClick={runOneClickDemo}
            disabled={isDemoRunning}
            className="h-9 px-4 rounded-xl bg-primary text-white text-xs font-bold flex items-center gap-1.5 hover:bg-primary-container transition-colors"
          >
            <span className="material-symbols-outlined text-[16px]">replay</span>
            <span>Re-run Demo</span>
          </button>
        </div>
      </div>

      {/* 1. Hero Metric Impact Tiles */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        
        {/* Meals Rescued */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500">
            <span className="font-label-sm text-xs font-bold uppercase tracking-wider">Meals Rescued</span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center">
              <span className="material-symbols-outlined text-[20px]">task_alt</span>
            </div>
          </div>
          <div className="mt-4">
            <div className="font-data-display text-4xl font-extrabold text-on-surface tabular-nums">
              {impact.mealsRescued}
            </div>
            <span className="text-xs text-emerald-700 font-semibold mt-1 block">
              100% hot portions verified
            </span>
          </div>
        </div>

        {/* People Served */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500">
            <span className="font-label-sm text-xs font-bold uppercase tracking-wider">People Served</span>
            <div className="w-9 h-9 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
              <span className="material-symbols-outlined text-[20px]">diversity_3</span>
            </div>
          </div>
          <div className="mt-4">
            <div className="font-data-display text-4xl font-extrabold text-on-surface tabular-nums">
              {impact.peopleServed}
            </div>
            <span className="text-xs text-slate-500 mt-1 block">
              Hope Community Kitchen diners
            </span>
          </div>
        </div>

        {/* Waste Avoided */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500">
            <span className="font-label-sm text-xs font-bold uppercase tracking-wider">Estimated Waste Avoided</span>
            <div className="w-9 h-9 rounded-xl bg-tertiary-container/30 text-tertiary flex items-center justify-center">
              <span className="material-symbols-outlined text-[20px]">eco</span>
            </div>
          </div>
          <div className="mt-4">
            <div className="font-data-display text-4xl font-extrabold text-on-surface tabular-nums">
              {impact.foodWasteKgAvoided} kg
            </div>
            <span className="text-xs text-slate-500 mt-1 block">
              Direct landfill diversion
            </span>
          </div>
        </div>

        {/* Estimated CO2e Avoided */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-500">
            <span className="font-label-sm text-xs font-bold uppercase tracking-wider">Estimated CO2e Saved</span>
            <div className="w-9 h-9 rounded-xl bg-secondary-container/40 text-secondary flex items-center justify-center">
              <span className="material-symbols-outlined text-[20px]">co2</span>
            </div>
          </div>
          <div className="mt-4">
            <div className="font-data-display text-4xl font-extrabold text-on-surface tabular-nums">
              ~{impact.co2eAvoidedKg.toFixed(0)} kg
            </div>
            <span className="text-xs text-secondary font-semibold mt-1 block">
              Based on EPA carbon factors
            </span>
          </div>
        </div>

      </div>

      {/* 2. Predicted vs Actual AI Feedback Engine Card */}
      <section className="bg-brand-dark rounded-2xl p-6 sm:p-8 text-white shadow-xl border border-white/10 space-y-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-72 h-72 bg-brand-teal/20 rounded-full blur-3xl pointer-events-none"></div>

        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 relative z-10 border-b border-white/10 pb-4">
          <div className="space-y-0.5">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-brand-mint text-[22px]">model_training</span>
              <h2 className="font-headline-sm text-lg font-bold">Predicted vs Actual Feedback Loop</h2>
            </div>
            <p className="text-xs text-slate-300">
              Closed-loop telemetry: Ground truth is stored in the training dataset for future model improvement.
            </p>
          </div>

          <span className="px-2.5 py-1 rounded-full bg-brand-mint/20 text-brand-mint font-label-sm text-xs font-bold border border-brand-mint/30 self-start sm:self-auto">
            Variance: +{impact.variancePercentage}% (High Calibration)
          </span>
        </div>

        {/* Visual Variance Comparison Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 relative z-10">
          
          <div className="bg-white/5 p-4 rounded-xl border border-white/5 space-y-1">
            <span className="text-xs text-slate-400 uppercase font-semibold">Predicted Surplus</span>
            <div className="font-headline-xl text-3xl font-extrabold text-slate-200 tabular-nums">
              {impact.predictedMeals} Meals
            </div>
            <span className="text-[11px] text-slate-400">Deterministic model output</span>
          </div>

          <div className="bg-brand-teal/20 p-4 rounded-xl border border-brand-mint/30 space-y-1">
            <span className="text-xs text-brand-mint uppercase font-bold">Actual Verified Intake</span>
            <div className="font-headline-xl text-3xl font-extrabold text-brand-mint tabular-nums">
              {impact.actualMeals} Meals
            </div>
            <span className="text-[11px] text-slate-200">Physically counted by shelter team</span>
          </div>

          <div className="bg-white/5 p-4 rounded-xl border border-white/5 space-y-1">
            <span className="text-xs text-slate-400 uppercase font-semibold">Prediction Accuracy</span>
            <div className="font-headline-xl text-3xl font-extrabold text-emerald-400 tabular-nums">
              97.2%
            </div>
            <span className="text-[11px] text-slate-400">Within acceptable ±5% operational margin</span>
          </div>

        </div>

        {/* Feedback Storage Confirmation Callout */}
        <div className="p-4 rounded-xl bg-white/5 border border-white/10 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 relative z-10">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-brand-mint/20 text-brand-mint flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-[20px]">database</span>
            </div>
            <div>
              <div className="text-sm font-bold text-slate-100 flex items-center gap-2">
                <span>Completed rescues create feedback data that can be used for future model improvement.</span>
                <span className="w-2 h-2 rounded-full bg-brand-mint"></span>
              </div>
              <p className="text-xs text-slate-400">
                Ground truth recorded: Predicted 70 meals vs Actual 72 meals (2.8% variance). Offline training pipeline indexes event covariates without risky real-time continuous retraining.
              </p>
            </div>
          </div>

          <button
            onClick={() => setFeedbackConfirmed(true)}
            disabled={feedbackConfirmed}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              feedbackConfirmed
                ? 'bg-emerald-500/20 text-emerald-300 cursor-default'
                : 'bg-brand-mint text-brand-dark hover:bg-white'
            }`}
          >
            {feedbackConfirmed ? '✓ Feedback Synced' : 'Sync Feedback Dataset'}
          </button>
        </div>

      </section>

      {/* 3. Stored Feedback Dataset Table */}
      <section className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-[20px]">table_chart</span>
            <h3 className="font-headline-sm text-base font-bold text-on-surface">
              Offline Model Training Dataset (Historical Calibration Logs)
            </h3>
          </div>
          <span className="text-xs text-slate-500">
            Architecture: Offline batch training pipeline
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead className="text-[11px] uppercase text-slate-400 bg-slate-50 border-b border-slate-100">
              <tr>
                <th className="px-4 py-3 font-semibold">Log ID</th>
                <th className="px-4 py-3 font-semibold">Event Type</th>
                <th className="px-4 py-3 font-semibold">Weather Covariate</th>
                <th className="px-4 py-3 font-semibold text-right">Predicted</th>
                <th className="px-4 py-3 font-semibold text-right">Actual</th>
                <th className="px-4 py-3 font-semibold text-right">Variance</th>
                <th className="px-4 py-3 font-semibold">Batch Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {storedDataset.map((row) => (
                <tr key={row.id} className="hover:bg-slate-50/70 transition-colors">
                  <td className="px-4 py-3 font-mono font-bold text-primary">{row.id}</td>
                  <td className="px-4 py-3 font-semibold text-slate-700">{row.event}</td>
                  <td className="px-4 py-3 text-slate-500">{row.weather}</td>
                  <td className="px-4 py-3 text-right font-medium text-slate-600 tabular-nums">{row.predicted}</td>
                  <td className="px-4 py-3 text-right font-bold text-on-surface tabular-nums">{row.actual}</td>
                  <td className="px-4 py-3 text-right font-bold text-emerald-700 tabular-nums">{row.variance}</td>
                  <td className="px-4 py-3">
                    <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 font-medium text-[10px]">
                      {row.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <p className="text-[11px] text-slate-400 italic pt-2">
          * Note: FoodBridge does not perform risky automated live retraining. Ground-truth deviations are stored in structured telemetry datasets for supervised batch evaluation.
        </p>
      </section>

    </div>
  );
};
