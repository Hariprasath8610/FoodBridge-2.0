import React from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { Header } from './components/common/Header';
import { BottomNav } from './components/common/BottomNav';
import { DemoBanner } from './components/demo/DemoBanner';
import { HomeView } from './components/home/HomeView';
import { PredictView } from './components/predict/PredictView';
import { MatchingView } from './components/matching/MatchingView';
import { MissionView } from './components/mission/MissionView';
import { ImpactView } from './components/impact/ImpactView';
import { HumanVerificationModal } from './components/verify/HumanVerificationModal';
import { MarkerDetailDrawer } from './components/common/MarkerDetailDrawer';

const AppContent: React.FC = () => {
  const { activeTab } = useApp();

  return (
    <div className="min-h-screen flex flex-col bg-background font-body-md text-on-surface antialiased selection:bg-brand-teal selection:text-white">
      {/* Top Header */}
      <Header />

      {/* Main Content Area */}
      <main className="flex-1 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-28 md:pt-28 pb-20 md:pb-12">
        {activeTab === 'home' && <HomeView />}
        {activeTab === 'predict' && <PredictView />}
        {activeTab === 'matching' && <MatchingView />}
        {activeTab === 'mission' && <MissionView />}
        {activeTab === 'impact' && <ImpactView />}
      </main>

      {/* Global Human Verification Modal */}
      <HumanVerificationModal />

      {/* Global Interactive Marker Detail Drawer (Bottom Sheet on mobile, Drawer on desktop) */}
      <MarkerDetailDrawer />

      {/* 1-Click Demo HUD Banner */}
      <DemoBanner />

      {/* Responsive Mobile Navigation */}
      <BottomNav />
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
};

export default App;
