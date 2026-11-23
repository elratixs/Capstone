export interface AccessTokenPayload {
  sub: string;
  clientId: string;
  clientCode: string;
  commercialTier: string;
  roles: string[];
  permissions: string[];
  locale: string;
  patientId?: string;
}

export interface AuthenticatedUser extends AccessTokenPayload {
  name: string;
  email: string;
}
