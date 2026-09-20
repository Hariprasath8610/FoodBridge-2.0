import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';

export const HumanVerificationModal: React.FC = () => {
  const {
    isVerificationModalOpen,
    setIsVerificationModalOpen,
    selectedRecipient,
    predictionInput,
    predictionResult,
    approveRescueMission
  } = useApp();

  const [tempChecked, setTempChecked] = useState(true);
  const [containmentChecked, setContainmentChecked] = useState(true);
  const [allergenChecked, setAllergenChecked] = useState(true);
  const [safetyChecked, setSafetyChecked] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isVerificationModalOpen || !selectedRecipient) return null;

  const surplusTarget = predictionResult
    ? Math.round((predictionResult.surplusMin + predictionResult.surplusMax) / 2)
    : 70;

  const handleApprove = async () => {
    setIsSubmitting(true);
    await new Promise(r => setTimeout(r, 600));
    await approveRescueMission();
    setIsSubmitting(false);
  };

  const allAcksChecked = tempChecked && containmentChecked && allergenChecked && safetyChecked;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-fade-in">
      <div className="bg-white rounded-2xl w-full max-w-xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh]">
        
        {/* Modal Header */}
        <div className="p-5 sm:p-6 bg-slate-50 border-b border-slate-200/80 flex items-start justify-between gap-3">
          <div className="space-y-1">
            <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-secondary-container text-on-secondary-container text-xs font-bold uppercase tracking-wider">
              <span className="material-symbols-outlined text-[15px]">verified_user</span>
              <span>Human-in-the-Loop Protocol</span>
            </div>
            <h2 className="font-headline-lg text-xl font-bold text-on-surface">
              Human Verification &amp; Dispatch Approval
            </h2>
            <p className="text-xs text-slate-500">
              AI recommends this match. Human verification is required before rescue dispatch.
            </p>
          </div>

          <button
            onClick={() => setIsVerificationModalOpen(false)}
            className="w-8 h-8 rounded-full bg-slate-200/60 hover:bg-slate-200 text-slate-500 flex items-center justify-center transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-5 sm:p-6 overflow-y-auto space-y-5 text-xs text-slate-600">
          
          {/* Key Allocation Summary Bento */}
          <div className="p-4 rounded-xl bg-primary/5 border border-primary/20 grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div>
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Cargo Volume</span>
              <strong className="text-sm font-bold text-primary">{surplusTarget} Hot Meals</strong>
            </div>
            <div>
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Food Category</span>
              <strong className="text-sm font-bold text-on-surface">{predictionInput.foodCategory}</strong>
            </div>
            <div>
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Target Window</span>
              <strong className="text-sm font-bold text-on-surface">7:45 – 8:30 PM</strong>
            </div>
            <div>
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Distance</span>
              <strong className="text-sm font-bold text-emerald-700">{selectedRecipient.distanceKm} km transit</strong>
            </div>
          </div>

          {/* Recipient Verification */}
          <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/60 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary-container/40 text-secondary flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-[20px]">soup_kitchen</span>
              </div>
              <div>
                <h4 className="font-bold text-sm text-on-surface">{selectedRecipient.name}</h4>
                <p className="text-[11px] text-slate-500">{selectedRecipient.address}</p>
              </div>
            </div>
            <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
              Verified Partner
            </span>
          </div>

          {/* Food Safety Acknowledgement Checklist */}
          <div className="space-y-3 pt-1">
            <span className="font-label-sm text-xs font-bold text-slate-800 uppercase tracking-wider block">
              Mandatory Food Safety Checkpoints
            </span>

            <label className="flex items-start gap-3 p-2.5 rounded-lg border border-slate-200 hover:bg-slate-50 cursor-pointer transition-colors">
              <input
                type="checkbox"
                checked={tempChecked}
                onChange={(e) => setTempChecked(e.target.checked)}
                className="w-4 h-4 mt-0.5 accent-primary rounded cursor-pointer"
              />
              <span className="leading-snug">
                <strong className="text-on-surface block">Thermal Integrity Audit:</strong>
                Food held above 60°C (140°F) or safely chilled. Inspected within 30 minutes of kitchen serving window.
              </span>
            </label>

            <label className="flex items-start gap-3 p-2.5 rounded-lg border border-slate-200 hover:bg-slate-50 cursor-pointer transition-colors">
              <input
                type="checkbox"
                checked={containmentChecked}
                onChange={(e) => setContainmentChecked(e.target.checked)}
                className="w-4 h-4 mt-0.5 accent-primary rounded cursor-pointer"
              />
              <span className="leading-snug">
                <strong className="text-on-surface block">Insulated Containment:</strong>
                Packed into 3 thermal Cambro units with sealed tamper-evident biological containment tags.
              </span>
            </label>

            <label className="flex items-start gap-3 p-2.5 rounded-lg border border-slate-200 hover:bg-slate-50 cursor-pointer transition-colors">
              <input
                type="checkbox"
                checked={allergenChecked}
                onChange={(e) => setAllergenChecked(e.target.checked)}
                className="w-4 h-4 mt-0.5 accent-primary rounded cursor-pointer"
              />
              <span className="leading-snug">
                <strong className="text-on-surface block">Dietary Segregation:</strong>
                Vegetarian ingredients confirmed. No cross-contamination with potential non-vegetarian menu lines.
              </span>
            </label>

            <label className="flex items-start gap-3 p-2.5 rounded-lg border border-slate-200 hover:bg-slate-50 cursor-pointer transition-colors">
              <input
                type="checkbox"
                checked={safetyChecked}
                onChange={(e) => setSafetyChecked(e.target.checked)}
                className="w-4 h-4 mt-0.5 accent-primary rounded cursor-pointer"
              />
              <span className="leading-snug">
                <strong className="text-on-surface block">Responsible Food Rescue Affirmation:</strong>
                I certify as donor kitchen representative that these surplus portions are unconsumed, fresh, and approved for transit.
              </span>
            </label>
          </div>

          <p className="text-[11px] text-slate-400 italic">
            * Estimated impact: ~36 kg food waste avoided and ~70 community members nourished.
          </p>

        </div>

        {/* Modal Footer */}
        <div className="p-4 sm:p-5 bg-slate-50 border-t border-slate-200/80 flex items-center justify-between gap-3">
          <button
            onClick={() => setIsVerificationModalOpen(false)}
            className="px-4 py-2 rounded-xl bg-white border border-slate-200 text-slate-600 hover:bg-slate-100 font-semibold text-xs transition-colors"
          >
            Cancel
          </button>

          <button
            onClick={handleApprove}
            disabled={!allAcksChecked || isSubmitting}
            className="h-11 px-6 bg-primary hover:bg-primary-container text-white rounded-xl font-label-md text-xs sm:text-sm font-bold flex items-center gap-2 shadow-md shadow-primary/20 disabled:opacity-50 transition-all active:scale-95"
          >
            {isSubmitting ? (
              <>
                <span className="material-symbols-outlined text-[18px] animate-spin">autorenew</span>
                <span>Generating Rescue Mission...</span>
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-[18px]">verified</span>
                <span>Approve Rescue Mission</span>
              </>
            )}
          </button>
        </div>

      </div>
    </div>
  );
};
