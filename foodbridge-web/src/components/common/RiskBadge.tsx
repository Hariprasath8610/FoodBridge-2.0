import React from 'react';
import type { RiskLevel } from '../../types';

interface RiskBadgeProps {
  level: RiskLevel;
  className?: string;
}

export const RiskBadge: React.FC<RiskBadgeProps> = ({ level, className = '' }) => {
  if (level === 'HIGH') {
    return (
      <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-error/20 text-brand-risk font-label-sm text-label-sm font-bold border border-error/30 ${className}`}>
        <span className="w-2 h-2 rounded-full bg-brand-risk animate-pulse"></span>
        <span className="material-symbols-outlined text-[14px]">warning</span>
        HIGH SURPLUS RISK
      </span>
    );
  }

  if (level === 'MEDIUM') {
    return (
      <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-tertiary-container/30 text-tertiary font-label-sm text-label-sm font-semibold border border-tertiary/20 ${className}`}>
        <span className="w-1.5 h-1.5 rounded-full bg-brand-warning"></span>
        <span className="material-symbols-outlined text-[14px]">info</span>
        MODERATE SURPLUS RISK
      </span>
    );
  }

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-secondary-container/40 text-on-secondary-container font-label-sm text-label-sm font-semibold border border-secondary/20 ${className}`}>
      <span className="w-1.5 h-1.5 rounded-full bg-brand-success"></span>
      <span className="material-symbols-outlined text-[14px]">check_circle</span>
      LOW RISK
    </span>
  );
};
