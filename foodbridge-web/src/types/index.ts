export type EventType = 'wedding' | 'college' | 'hostel' | 'hotel' | 'restaurant' | 'corporate';

export type FoodCategory = 'Vegetarian' | 'Non-Vegetarian' | 'Mixed' | 'Vegan';

export type WeatherCondition = 'Clear' | 'Light Rain' | 'Moderate Rain' | 'Heavy Rain' | 'Overcast';

export type RiskLevel = 'LOW' | 'MEDIUM' | 'HIGH';

export type UserRole = 'food_giver' | 'coordinator' | 'transporter' | 'receiver';

export type MovementState = 'to_donor' | 'at_donor' | 'in_transit' | 'at_receiver' | 'delivered';

export interface Coordinates {
  lat: number;
  lng: number;
  x?: number; // relative SVG percentage 0-100
  y?: number;
}

export interface PredictionInput {
  eventType: string;
  expectedGuests: number;
  plannedMeals: number;
  currentAttendance: number;
  foodCategory: string;
  servingTime: string;
  location: string;
  weatherCondition: WeatherCondition;
  rainProbability: number;
}

export interface ExplainableFactors {
  weatherImpact: string;
  attendanceTrajectory: string;
  historicalPattern: string;
  details: string[];
}

export interface PredictionResult {
  expectedConsumptionMin: number;
  expectedConsumptionMax: number;
  surplusMin: number;
  surplusMax: number;
  surplusProbability: number;
  confidence: number;
  riskLevel: RiskLevel;
  factors: ExplainableFactors;
  calculatedAt: string;
}

export interface RecipientFactorBreakdown {
  quantityFit: number;       // 0 - 100
  distanceProximity: number;  // 0 - 100
  timeWindow: number;         // 0 - 100
  foodCompatibility: number;  // 0 - 100
  verificationRating: number; // 0 - 100
}

export interface Recipient {
  id: string;
  name: string;
  displayCode: string; // e.g. "Verified Demo Recipient A"
  organizationType: string;
  needMeals: number;
  distanceKm: number;
  estimatedTravelMins: number;
  rescueWindow: string;
  foodCategoryAccepted: string[];
  isVegetarianCompatible: boolean;
  address: string;
  contactPerson: string;
  intakeWindow: string;
  isAvailable: boolean;
  isVerified: boolean;
  compatibilityScore: number;
  whyRecommended: string[];
  factorBreakdown: RecipientFactorBreakdown;
  coordinates: Coordinates;
  recommendedRank?: number;
}

export type MissionStatus = 
  | 'predicted'
  | 'matched'
  | 'human_verified'
  | 'pickup_assigned'
  | 'picked_up'
  | 'in_transit'
  | 'delivered'
  | 'completed';

export interface RescueMission {
  id: string;
  donorName: string;
  donorAddress: string;
  donorContact: string;
  recipientId: string;
  recipientName: string;
  recipientAddress: string;
  recipientContact: string;
  quantityMeals: number;
  foodCategory: string;
  containmentUnits: string;
  targetWindow: string;
  distanceKm: number;
  status: MissionStatus;
  pickupOtp: string;
  deliveryOtp: string;
  pickupVerifiedAt?: string;
  deliveryVerifiedAt?: string;
  transporterName: string;
  transporterPhone: string;
  transporterVehicle: string;
  impactMetrics?: ImpactRecord;
  createdAt: string;
}

export interface ImpactRecord {
  missionId?: string;
  mealsRescued: number;
  peopleServed: number;
  foodWasteKgAvoided: number;
  co2eAvoidedKg: number;
  predictedMeals: number;
  actualMeals: number;
  variancePercentage: number;
  feedbackStored: boolean;
  recordedAt: string;
}

export interface OperationsStats {
  predictedSurplusMeals: number;
  rescuedMeals: number;
  peopleServed: number;
  foodWasteKgAvoided: number;
  co2eAvoidedKg: number;
  activeMissionsCount: number;
  rescueSuccessRate: number;
  verifiedPartnersCount: number;
}

export type MarkerType = 'donor' | 'transporter' | 'recipient';

export interface MarkerDetail {
  type: MarkerType;
  title: string;
  subtitle: string;
  data: any;
}
