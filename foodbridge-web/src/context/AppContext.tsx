import React, { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import type {
  PredictionInput,
  PredictionResult,
  Recipient,
  RescueMission,
  ImpactRecord,
  OperationsStats,
  UserRole,
  MarkerType,
  MarkerDetail,
  MovementState
} from '../types';
import { DEFAULT_PREDICTION_INPUT, calculateSurplusPrediction } from '../services/predictionService';
import { scoreRecipients } from '../services/matchingService';
import { api } from '../services/api';
import confetti from 'canvas-confetti';

export type ActiveTab = 'home' | 'predict' | 'matching' | 'mission' | 'impact';

interface AppContextType {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  currentRole: UserRole;
  setCurrentRole: (role: UserRole) => void;
  predictionInput: PredictionInput;
  setPredictionInput: React.Dispatch<React.SetStateAction<PredictionInput>>;
  predictionResult: PredictionResult;
  isRecalculating: boolean;
  recalculatePrediction: (overrideInput?: PredictionInput) => Promise<void>;
  recipients: Recipient[];
  selectedRecipient: Recipient | null;
  setSelectedRecipient: (r: Recipient | null) => void;
  searchRadiusKm: number;
  setSearchRadiusKm: (radius: number) => void;
  filterCategory: 'all' | 'score' | 'distance' | 'veg';
  setFilterCategory: (filter: 'all' | 'score' | 'distance' | 'veg') => void;
  isVerificationModalOpen: boolean;
  setIsVerificationModalOpen: (open: boolean) => void;
  isMarkerDrawerOpen: boolean;
  setIsMarkerDrawerOpen: (open: boolean) => void;
  selectedMarkerDetail: MarkerDetail | null;
  setSelectedMarkerDetail: (detail: MarkerDetail | null) => void;
  openMarkerDrawer: (type: MarkerType, data?: any) => void;
  activeMission: RescueMission | null;
  movementState: MovementState;
  setMovementState: (state: MovementState) => void;
  approveRescueMission: () => Promise<void>;
  pickupOtpInput: string;
  setPickupOtpInput: (otp: string) => void;
  deliveryOtpInput: string;
  setDeliveryOtpInput: (otp: string) => void;
  verifyPickupOtp: (code?: string) => Promise<boolean>;
  verifyDeliveryOtp: (code?: string) => Promise<boolean>;
  simulatePickupScan: () => Promise<void>;
  simulateDeliveryHandoff: () => Promise<void>;
  latestImpact: ImpactRecord | null;
  stats: OperationsStats;
  isDemoRunning: boolean;
  demoStep: number;
  demoStepMessage: string;
  runOneClickDemo: () => void;
  pauseOneClickDemo: () => void;
  resumeOneClickDemo: () => void;
  stopOneClickDemo: () => void;
  nextDemoStep: () => void;
  resetAll: () => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [activeTab, setActiveTab] = useState<ActiveTab>('home');
  const [currentRole, setCurrentRole] = useState<UserRole>('coordinator');
  const [predictionInput, setPredictionInput] = useState<PredictionInput>(DEFAULT_PREDICTION_INPUT);
  const [predictionResult, setPredictionResult] = useState<PredictionResult>(() => calculateSurplusPrediction(DEFAULT_PREDICTION_INPUT));
  const [isRecalculating, setIsRecalculating] = useState<boolean>(false);

  const [searchRadiusKm, setSearchRadiusKm] = useState<number>(3.0);
  const [filterCategory, setFilterCategory] = useState<'all' | 'score' | 'distance' | 'veg'>('all');
  const [recipients, setRecipients] = useState<Recipient[]>(() => scoreRecipients(70, 'Vegetarian', 3.0));
  const [selectedRecipient, setSelectedRecipient] = useState<Recipient | null>(() => {
    const list = scoreRecipients(70, 'Vegetarian', 3.0);
    return list.find(r => r.id === 'recipient-a') || list[0] || null;
  });

  const [isVerificationModalOpen, setIsVerificationModalOpen] = useState<boolean>(false);
  const [isMarkerDrawerOpen, setIsMarkerDrawerOpen] = useState<boolean>(false);
  const [selectedMarkerDetail, setSelectedMarkerDetail] = useState<MarkerDetail | null>(null);

  const [movementState, setMovementState] = useState<MovementState>('at_donor');
  const [pickupOtpInput, setPickupOtpInput] = useState<string>('FB-4291');
  const [deliveryOtpInput, setDeliveryOtpInput] = useState<string>('FB-8834');

  const [activeMission, setActiveMission] = useState<RescueMission | null>({
    id: 'FB-2026-0042',
    donorName: 'FoodBridge Demo Kitchen (Grand Palace Pavilion)',
    donorAddress: 'Race Course / Avinashi Road, Coimbatore',
    donorContact: 'Chef Marcus (Bay 2 Loading)',
    recipientId: 'recipient-a',
    recipientName: 'Hope Community Kitchen (Verified Demo Recipient A)',
    recipientAddress: 'Cross Cut Road, Gandhipuram, Coimbatore',
    recipientContact: 'Sarah Jenkins (East Intake Ramp)',
    quantityMeals: 72,
    foodCategory: 'Vegetarian Banquet',
    containmentUnits: '3 Cambro Thermal Units (Insulated at 68°C)',
    targetWindow: '7:45 PM – 9:15 PM',
    distanceKm: 1.8,
    status: 'pickup_assigned',
    pickupOtp: 'FB-4291',
    deliveryOtp: 'FB-8834',
    transporterName: 'FoodBridge Pickup Partner (Elena R.)',
    transporterPhone: '+91 94422 10101',
    transporterVehicle: 'Electric Cargo Van #12',
    createdAt: new Date().toISOString()
  });

  const [latestImpact, setLatestImpact] = useState<ImpactRecord | null>({
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
  });

  const [stats, setStats] = useState<OperationsStats>({
    predictedSurplusMeals: 3698,
    rescuedMeals: 1929,
    peopleServed: 1800,
    foodWasteKgAvoided: 868.1,
    co2eAvoidedKg: 2170.25,
    activeMissionsCount: 3,
    rescueSuccessRate: 96.9,
    verifiedPartnersCount: 42
  });

  useEffect(() => {
    api.getStats().then(s => setStats(s)).catch(() => {});
  }, []);

  // Demo Automation State
  const [isDemoRunning, setIsDemoRunning] = useState<boolean>(false);
  const [demoStep, setDemoStep] = useState<number>(0);
  const [demoStepMessage, setDemoStepMessage] = useState<string>('');

  // Update recipients when prediction or radius changes
  useEffect(() => {
    const surplusTarget = predictionResult ? Math.round((predictionResult.surplusMin + predictionResult.surplusMax) / 2) : 70;
    const scored = scoreRecipients(surplusTarget, predictionInput.foodCategory, searchRadiusKm);
    
    let filtered = scored;
    if (filterCategory === 'veg') {
      filtered = scored.filter(r => r.isVegetarianCompatible);
    } else if (filterCategory === 'distance') {
      filtered = scored.filter(r => r.distanceKm <= 2.5);
    } else if (filterCategory === 'score') {
      filtered = [...scored].sort((a, b) => b.compatibilityScore - a.compatibilityScore);
    }

    setRecipients(filtered);
    if (!selectedRecipient || !filtered.some(r => r.id === selectedRecipient.id)) {
      setSelectedRecipient(filtered[0] || null);
    }
  }, [predictionResult, predictionInput.foodCategory, searchRadiusKm, filterCategory]);

  const openMarkerDrawer = (type: MarkerType, data?: any) => {
    let title = '';
    let subtitle = '';

    if (type === 'donor') {
      title = 'FoodBridge Demo Kitchen';
      subtitle = 'Grand Palace Pavilion, Race Course, Coimbatore';
    } else if (type === 'transporter') {
      title = 'FoodBridge Pickup Partner';
      subtitle = 'Elena R. • Electric Cargo Van #12';
    } else {
      title = data?.displayCode || data?.name || 'Verified Demo Recipient';
      subtitle = data?.address || 'Coimbatore Transit Network';
    }

    setSelectedMarkerDetail({ type, title, subtitle, data });
    setIsMarkerDrawerOpen(true);
  };

  const recalculatePrediction = async (overrideInput?: PredictionInput) => {
    setIsRecalculating(true);
    const targetInput = overrideInput || predictionInput;
    
    // Simulate realistic AI synthesis processing delay
    await new Promise(res => setTimeout(res, 850));

    const result = await api.predictSurplus(targetInput);
    setPredictionResult(result);
    setIsRecalculating(false);
  };

  const approveRescueMission = async () => {
    if (!selectedRecipient) return;
    const surplusTarget = predictionResult ? Math.round((predictionResult.surplusMin + predictionResult.surplusMax) / 2) : 70;
    
    const mission = await api.createMission({
      id: 'FB-2026-0042',
      donorName: predictionInput.location,
      recipientId: selectedRecipient.id,
      recipientName: `${selectedRecipient.name} (${selectedRecipient.displayCode})`,
      recipientAddress: selectedRecipient.address,
      recipientContact: selectedRecipient.contactPerson,
      quantityMeals: surplusTarget || 72,
      foodCategory: predictionInput.foodCategory,
      distanceKm: selectedRecipient.distanceKm,
      status: 'pickup_assigned'
    });

    setActiveMission(mission);
    setMovementState('at_donor');
    setIsVerificationModalOpen(false);
    setActiveTab('mission');
  };

  const verifyPickupOtp = async (code?: string): Promise<boolean> => {
    const input = (code || pickupOtpInput).trim().toUpperCase();
    const valid = input === 'FB-4291' || input === '4291' || input === '429108';
    
    if (valid) {
      if (activeMission) {
        setActiveMission({
          ...activeMission,
          status: 'in_transit',
          pickupVerifiedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        });
      }
      setMovementState('in_transit');
      return true;
    }
    return false;
  };

  const verifyDeliveryOtp = async (code?: string): Promise<boolean> => {
    const input = (code || deliveryOtpInput).trim().toUpperCase();
    const valid = input === 'FB-8834' || input === '8834' || input === '883412';
    
    if (valid) {
      if (activeMission) {
        setActiveMission({
          ...activeMission,
          status: 'delivered',
          deliveryVerifiedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        });
      }
      setMovementState('delivered');

      const impactRec: ImpactRecord = {
        missionId: 'FB-2026-0042',
        predictedMeals: 70,
        actualMeals: 72,
        variancePercentage: 2.8,
        mealsRescued: 72,
        peopleServed: 72,
        foodWasteKgAvoided: 36.0,
        co2eAvoidedKg: 90.0,
        feedbackStored: true,
        recordedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      setLatestImpact(impactRec);

      // Record to backend API if available
      api.recordFeedback('FB-2026-0042', 72).catch(() => {});

      // Trigger celebration confetti
      try {
        confetti({
          particleCount: 90,
          spread: 80,
          origin: { y: 0.6 },
          colors: ['#0F766E', '#14B8A6', '#10B981', '#F59E0B']
        });
      } catch {
        // safe fallback
      }

      return true;
    }
    return false;
  };

  const simulatePickupScan = async () => {
    await verifyPickupOtp('FB-4291');
  };

  const simulateDeliveryHandoff = async () => {
    await verifyDeliveryOtp('FB-8834');
    setTimeout(() => {
      setActiveTab('impact');
    }, 1400);
  };

  const resetAll = () => {
    setPredictionInput(DEFAULT_PREDICTION_INPUT);
    const result = calculateSurplusPrediction(DEFAULT_PREDICTION_INPUT);
    setPredictionResult(result);
    setSearchRadiusKm(3.0);
    setFilterCategory('all');
    setCurrentRole('coordinator');
    const recs = scoreRecipients(70, 'Vegetarian', 3.0);
    setRecipients(recs);
    setSelectedRecipient(recs.find(r => r.id === 'recipient-a') || recs[0]);
    setActiveMission({
      id: 'FB-2026-0042',
      donorName: 'FoodBridge Demo Kitchen (Grand Palace Pavilion)',
      donorAddress: 'Race Course / Avinashi Road, Coimbatore',
      donorContact: 'Chef Marcus (Bay 2 Loading)',
      recipientId: 'recipient-a',
      recipientName: 'Hope Community Kitchen (Verified Demo Recipient A)',
      recipientAddress: 'Cross Cut Road, Gandhipuram, Coimbatore',
      recipientContact: 'Sarah Jenkins (East Intake Ramp)',
      quantityMeals: 72,
      foodCategory: 'Vegetarian Banquet',
      containmentUnits: '3 Cambro Thermal Units (Insulated at 68°C)',
      targetWindow: '7:45 PM – 9:15 PM',
      distanceKm: 1.8,
      status: 'pickup_assigned',
      pickupOtp: 'FB-4291',
      deliveryOtp: 'FB-8834',
      transporterName: 'FoodBridge Pickup Partner (Elena R.)',
      transporterPhone: '+91 94422 10101',
      transporterVehicle: 'Electric Cargo Van #12',
      createdAt: new Date().toISOString()
    });
    setLatestImpact({
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
    });
    setMovementState('at_donor');
    setIsDemoRunning(false);
    setDemoStep(0);
    setDemoStepMessage('');
    api.resetDemo();
  };

  // -----------------------------------------------------------------
  // 1-Click Automated Hackathon Demo Runner
  // -----------------------------------------------------------------
  const runOneClickDemo = () => {
    setIsDemoRunning(true);
    setDemoStep(1);
    setDemoStepMessage('1/8: Initializing Wedding Demo Kitchen in Coimbatore (500 guests, 430 attendance, 75% rain)...');
    
    // Step 1: Initialize inputs and go to predict
    setCurrentRole('food_giver');
    setActiveTab('predict');
    setPredictionInput(DEFAULT_PREDICTION_INPUT);

    // Step 2: Recalculate AI Prediction
    setTimeout(async () => {
      setDemoStep(2);
      setDemoStepMessage('2/8: Synthesizing deterministic ML prediction: High Surplus Risk (60–75 meals, 84% prob)...');
      await recalculatePrediction(DEFAULT_PREDICTION_INPUT);

      // Step 3: Transition to Recipient Matching
      setTimeout(() => {
        setDemoStep(3);
        setDemoStepMessage('3/8: Matching against verified Coimbatore recipients: Hope Kitchen recommended (94% score)...');
        setActiveTab('matching');

        // Step 4: FoodBridge Team Human Verification
        setTimeout(() => {
          setDemoStep(4);
          setCurrentRole('coordinator');
          setDemoStepMessage('4/8: FoodBridge Team verifies: Core temp 68°C certified, Cambro containers sealed...');
          setIsVerificationModalOpen(true);

          // Step 5: Authorize Rescue Mission
          setTimeout(async () => {
            setDemoStep(5);
            setDemoStepMessage('5/8: Authorizing Rescue Mission FB-2026-0042. Assigning FoodBridge Pickup Partner...');
            await approveRescueMission();
            setIsVerificationModalOpen(false);
            setActiveTab('mission');
            setCurrentRole('transporter');

            // Step 6: Pickup OTP Verification
            setTimeout(async () => {
              setDemoStep(6);
              setDemoStepMessage('6/8: Transporter arrives at Demo Kitchen. Verifying Pickup OTP FB-4291 -> Status: IN TRANSIT...');
              await verifyPickupOtp('FB-4291');

              // Step 7: Delivery OTP Verification & Confirmation
              setTimeout(async () => {
                setDemoStep(7);
                setCurrentRole('receiver');
                setDemoStepMessage('7/8: Transporter arrives at Hope Kitchen. Verifying Delivery OTP FB-8834 -> Status: DELIVERED...');
                await verifyDeliveryOtp('FB-8834');

                // Step 8: Impact & Feedback Learning Loop
                setTimeout(() => {
                  setDemoStep(8);
                  setCurrentRole('coordinator');
                  setDemoStepMessage('8/8: Rescue completed! 72 meals rescued, 2.8% prediction variance recorded for continuous AI learning.');
                  setActiveTab('impact');
                  setIsDemoRunning(false);
                }, 3000);

              }, 3200);

            }, 3000);

          }, 2800);

        }, 3200);

      }, 3000);

    }, 1800);
  };

  const pauseOneClickDemo = () => setIsDemoRunning(false);
  const resumeOneClickDemo = () => setIsDemoRunning(true);
  const stopOneClickDemo = () => {
    setIsDemoRunning(false);
    setDemoStep(0);
    setDemoStepMessage('');
  };
  const nextDemoStep = () => {};

  return (
    <AppContext.Provider
      value={{
        activeTab,
        setActiveTab,
        currentRole,
        setCurrentRole,
        predictionInput,
        setPredictionInput,
        predictionResult,
        isRecalculating,
        recalculatePrediction,
        recipients,
        selectedRecipient,
        setSelectedRecipient,
        searchRadiusKm,
        setSearchRadiusKm,
        filterCategory,
        setFilterCategory,
        isVerificationModalOpen,
        setIsVerificationModalOpen,
        isMarkerDrawerOpen,
        setIsMarkerDrawerOpen,
        selectedMarkerDetail,
        setSelectedMarkerDetail,
        openMarkerDrawer,
        activeMission,
        movementState,
        setMovementState,
        approveRescueMission,
        pickupOtpInput,
        setPickupOtpInput,
        deliveryOtpInput,
        setDeliveryOtpInput,
        verifyPickupOtp,
        verifyDeliveryOtp,
        simulatePickupScan,
        simulateDeliveryHandoff,
        latestImpact,
        stats,
        isDemoRunning,
        demoStep,
        demoStepMessage,
        runOneClickDemo,
        pauseOneClickDemo,
        resumeOneClickDemo,
        stopOneClickDemo,
        nextDemoStep,
        resetAll
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within an AppProvider');
  return context;
};
