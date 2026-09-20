import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import type { UserRole } from '../../types';

export const Header: React.FC = () => {
  const {
    activeTab,
    setActiveTab,
    currentRole,
    setCurrentRole,
    runOneClickDemo,
    isDemoRunning,
    resetAll
  } = useApp();

  const [isRoleDropdownOpen, setIsRoleDropdownOpen] = useState(false);

  const roles: { id: UserRole; label: string; icon: string; tag: string }[] = [
    { id: 'coordinator', label: 'FoodBridge Team', icon: 'verified_user', tag: 'Coordinator' },
    { id: 'food_giver', label: 'Food Giver', icon: 'restaurant', tag: 'Donor' },
    { id: 'transporter', label: 'Transporter', icon: 'local_shipping', tag: 'Pickup Partner' },
    { id: 'receiver', label: 'Receiver', icon: 'volunteer_activism', tag: 'Community Shelter' }
  ];

  const currentRoleObj = roles.find(r => r.id === currentRole) || roles[0];

  return (
    <header className="fixed top-0 w-full z-50 pt-safe bg-surface/92 backdrop-blur-xl border-b border-surface-container-high shadow-[0_1px_8px_rgba(0,0,0,0.03)]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="h-16 flex items-center justify-between gap-3">
          
          {/* Logo & Platform Identity */}
          <div 
            className="flex items-center gap-2.5 cursor-pointer select-none shrink-0"
            onClick={() => setActiveTab('home')}
          >
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-primary to-primary-container flex items-center justify-center text-white shadow-sm shadow-primary/20">
              <span className="material-symbols-outlined text-[22px]">soup_kitchen</span>
            </div>
            <div className="flex flex-col">
              <div className="flex items-center gap-1.5">
                <span className="font-headline-sm text-base text-on-surface font-bold tracking-tight">FoodBridge</span>
                <span className="text-[9px] uppercase font-bold tracking-wider px-1.5 py-0.2 rounded bg-secondary-container/50 text-on-secondary-container">
                  Coimbatore Demo
                </span>
              </div>
              <span className="font-label-sm text-[10px] text-on-surface-variant hidden sm:block">
                Predict surplus before it becomes waste
              </span>
            </div>
          </div>

          {/* Desktop Navigation Links */}
          <nav className="hidden lg:flex items-center gap-1 bg-surface-container-low/70 p-1 rounded-xl border border-surface-container text-xs">
            <button
              onClick={() => setActiveTab('home')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-all ${
                activeTab === 'home'
                  ? 'bg-white text-primary font-bold shadow-xs'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
              }`}
            >
              Overview
            </button>
            <button
              onClick={() => setActiveTab('predict')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-all flex items-center gap-1.5 ${
                activeTab === 'predict'
                  ? 'bg-white text-primary font-bold shadow-xs'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
              }`}
            >
              <span className="w-1.5 h-1.5 rounded-full bg-secondary"></span>
              Predict Surplus
            </button>
            <button
              onClick={() => setActiveTab('matching')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-all ${
                activeTab === 'matching'
                  ? 'bg-white text-primary font-bold shadow-xs'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
              }`}
            >
              Recipient Matching
            </button>
            <button
              onClick={() => setActiveTab('mission')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-all flex items-center gap-1 ${
                activeTab === 'mission'
                  ? 'bg-white text-primary font-bold shadow-xs'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
              }`}
            >
              Rescue Mission
              <span className="text-[10px] bg-primary/10 text-primary px-1.5 py-0.2 rounded-full font-bold">0042</span>
            </button>
            <button
              onClick={() => setActiveTab('impact')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-all ${
                activeTab === 'impact'
                  ? 'bg-white text-primary font-bold shadow-xs'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'
              }`}
            >
              Impact &amp; Feedback
            </button>
          </nav>

          {/* Right Area: Role Selector & Action CTAs */}
          <div className="flex items-center gap-2">
            
            {/* 4-Role Switcher Dropdown */}
            <div className="relative">
              <button
                onClick={() => setIsRoleDropdownOpen(prev => !prev)}
                className="h-8.5 px-2.5 rounded-full bg-surface-container hover:bg-surface-container-high border border-surface-container-highest text-on-surface flex items-center gap-1.5 transition-all text-xs"
                title="Switch Operational Role"
              >
                <span className="material-symbols-outlined text-[16px] text-primary">
                  {currentRoleObj.icon}
                </span>
                <span className="font-semibold hidden sm:inline">{currentRoleObj.label}</span>
                <span className="text-[10px] px-1.5 py-0.2 rounded-full bg-primary/10 text-primary font-bold">
                  {currentRoleObj.tag}
                </span>
                <span className="material-symbols-outlined text-[14px] text-slate-400">arrow_drop_down</span>
              </button>

              {/* Role Dropdown Menu */}
              {isRoleDropdownOpen && (
                <div className="absolute right-0 mt-1.5 w-60 bg-white rounded-2xl shadow-xl border border-slate-200/90 py-1.5 z-50 animate-fade-in text-xs">
                  <div className="px-3 py-1.5 border-b border-slate-100 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                    Select Active Role
                  </div>
                  {roles.map(r => (
                    <button
                      key={r.id}
                      onClick={() => {
                        setCurrentRole(r.id);
                        setIsRoleDropdownOpen(false);
                      }}
                      className={`w-full px-3 py-2 text-left flex items-center justify-between transition-colors ${
                        currentRole === r.id ? 'bg-primary/10 text-primary font-bold' : 'text-slate-700 hover:bg-slate-50'
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className="material-symbols-outlined text-[18px]">
                          {r.icon}
                        </span>
                        <div>
                          <div className="font-semibold text-xs">{r.label}</div>
                          <div className="text-[10px] text-slate-400 font-normal">{r.tag}</div>
                        </div>
                      </div>
                      {currentRole === r.id && (
                        <span className="material-symbols-outlined text-[16px] text-primary">check</span>
                      )}
                    </button>
                  ))}
                  <div className="p-2 border-t border-slate-100 bg-slate-50 text-[10px] text-slate-500 font-medium text-center">
                    “AI recommends. FoodBridge team verifies.”
                  </div>
                </div>
              )}
            </div>

            {/* 1-Click Demo CTA */}
            <button
              onClick={runOneClickDemo}
              disabled={isDemoRunning}
              className={`h-8.5 px-3 rounded-full text-xs font-bold flex items-center gap-1 shadow-sm transition-all ${
                isDemoRunning
                  ? 'bg-secondary text-white ring-2 ring-secondary/30 animate-pulse'
                  : 'bg-primary hover:bg-primary-container text-white active:scale-95'
              }`}
              title="Automated walkthrough of the Wedding rescue scenario"
            >
              <span className="material-symbols-outlined text-[16px]">
                {isDemoRunning ? 'motion_photos_on' : 'play_circle'}
              </span>
              <span className="hidden sm:inline">{isDemoRunning ? 'Running Demo...' : '1-Click Demo'}</span>
              <span className="sm:hidden">{isDemoRunning ? 'Demo...' : 'Demo'}</span>
            </button>

            {/* Reset Scenario Button */}
            <button
              onClick={resetAll}
              className="h-8.5 w-8.5 rounded-full bg-surface-container-low text-on-surface-variant hover:text-on-surface hover:bg-surface-container flex items-center justify-center transition-colors shrink-0"
              title="Reset Demo Scenario to Initial State"
            >
              <span className="material-symbols-outlined text-[17px]">restart_alt</span>
            </button>
          </div>
        </div>

        {/* Live Telemetry Sub-bar */}
        <div className="py-1.5 border-t border-surface-container/60 flex items-center justify-between text-[11px] font-label-sm text-on-surface-variant overflow-x-auto no-scrollbar gap-4">
          <div className="flex items-center gap-2.5 shrink-0">
            <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-secondary-container/30 text-on-secondary-container font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-secondary animate-pulse"></span>
              <span>AI Engine Online</span>
            </div>
            <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-surface-container-low font-medium">
              <span className="material-symbols-outlined text-[13px] text-primary">cloud_done</span>
              <span>COIMBATORE: 75% Rain Probability</span>
            </div>
            <div className="hidden sm:flex items-center gap-1 px-2 py-0.5 rounded-full bg-surface-container-low font-medium">
              <span className="material-symbols-outlined text-[13px] text-secondary">verified</span>
              <span>AI Recommends • Humans Verify</span>
            </div>
          </div>

          <div className="hidden md:flex items-center gap-2 text-on-surface-variant shrink-0">
            <span>Demo Area: <strong className="text-on-surface font-semibold">Coimbatore, Tamil Nadu</strong></span>
          </div>
        </div>

      </div>
    </header>
  );
};
