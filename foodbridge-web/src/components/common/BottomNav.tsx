import React from 'react';
import { useApp } from '../../context/AppContext';
import type { ActiveTab } from '../../context/AppContext';

export const BottomNav: React.FC = () => {
  const { activeTab, setActiveTab } = useApp();

  const navItems: { id: ActiveTab; label: string; icon: string; badge?: string }[] = [
    { id: 'home', label: 'Home', icon: 'home' },
    { id: 'predict', label: 'Predict', icon: 'psychology' },
    { id: 'matching', label: 'Match', icon: 'hub' },
    { id: 'mission', label: 'Rescue', icon: 'local_shipping', badge: '0042' },
    { id: 'impact', label: 'Impact', icon: 'insights' }
  ];

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-surface/95 backdrop-blur-xl border-t border-surface-container-high pb-safe shadow-[0_-2px_10px_rgba(0,0,0,0.05)]">
      <div className="grid grid-cols-5 h-16 items-center px-2">
        {navItems.map((item) => {
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`flex flex-col items-center justify-center py-1 relative transition-colors ${
                isActive ? 'text-primary font-semibold' : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              <div className="relative">
                <span className={`material-symbols-outlined text-[22px] ${isActive ? 'fill-1' : ''}`}>
                  {item.icon}
                </span>
                {item.badge && (
                  <span className="absolute -top-1 -right-2 px-1 py-0.2 rounded-full bg-primary text-white text-[9px] font-bold">
                    {item.badge}
                  </span>
                )}
              </div>
              <span className="text-[11px] font-label-sm tracking-tight mt-0.5">
                {item.label}
              </span>
              {isActive && (
                <span className="w-1 h-1 rounded-full bg-primary absolute bottom-1"></span>
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
};
