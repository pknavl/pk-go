export interface UsagePlanPreset {
  name: string;
  monthlyQuota: number;
  burstLimit: number;
  rateLimit: number;
}

export function testingUsagePlanPreset(): UsagePlanPreset {
  return {
    name: "testing",
    monthlyQuota: 1000,
    burstLimit: 10,
    rateLimit: 5
  };
}
