import React from 'react';
import { useApp } from '../../context/AppContext';

export const DemoBanner: React.FC = () => {
  const {
    isDemoRunning,
    demoStep,
    demoStepMessage,
    pauseOneClickDemo,
    resumeOneClickDemo,
    stopOneClickDemo,
    nextDemoStep
  } = useApp();

  if (demoStep === 0 && !isDemoRunning) return null;

  return (
    <div className="fixed bottom-20 md:bottom-6 left-1/2 -translate-x-1/2 z-50 w-11/12 max-w-2xl bg-brand-dark text-white rounded-2xl shadow-2xl p-4 border border-white/10 backdrop-blur-xl animate-bounce-short">
      <div className="flex flex-col gap-2.5">
        
        {/* Header row */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="flex h-2.5 w-2.5 relative">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-brand-mint opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-brand-mint"></span>
            </span>
            <span className="font-label-sm text-xs uppercase tracking-widest text-brand-mint font-bold">
              Autonomous Hackathon Demo Mode • Step {demoStep} of 8
            </span>
          </div>

          <div className="flex items-center gap-1.5">
            {isDemoRunning ? (
              <button
                onClick={pauseOneClickDemo}
                className="px-2.5 py-1 rounded-lg bg-white/10 hover:bg-white/20 text-xs font-semibold flex items-center gap-1 transition-colors"
                title="Pause automated playback"
              >
                <span className="material-symbols-outlined text-[14px]">pause</span>
                <span>Pause</span>
              </button>
            ) : (
              <button
                onClick={resumeOneClickDemo}
                className="px-2.5 py-1 rounded-lg bg-brand-teal hover:bg-brand-mint text-white text-xs font-semibold flex items-center gap-1 transition-colors"
                title="Resume playback"
              >
                <span className="material-symbols-outlined text-[14px]">play_arrow</span>
                <span>Resume</span>
              </button>
            )}

            <button
              onClick={nextDemoStep}
              className="px-2.5 py-1 rounded-lg bg-white/10 hover:bg-white/20 text-xs font-semibold flex items-center gap-1 transition-colors"
              title="Skip to next step"
            >
              <span>Next</span>
              <span className="material-symbols-outlined text-[14px]">skip_next</span>
            </button>

            <button
              onClick={stopOneClickDemo}
              className="w-7 h-7 rounded-lg bg-white/10 hover:bg-error/30 text-white flex items-center justify-center transition-colors"
              title="Exit demo mode"
            >
              <span className="material-symbols-outlined text-[16px]">close</span>
            </button>
          </div>
        </div>

        {/* Narrative Description */}
        <div className="text-sm font-medium text-slate-200 flex items-start gap-2">
          <span className="material-symbols-outlined text-[18px] text-brand-mint shrink-0 mt-0.5">
            tips_and_updates
          </span>
          <span className="leading-snug">{demoStepMessage}</span>
        </div>

        {/* Progress Bar */}
        <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden">
          <div
            className="bg-brand-mint h-full transition-all duration-300"
            style={{ width: `${(demoStep / 8) * 100}%` }}
          ></div>
        </div>

      </div>
    </div>
  );
};
