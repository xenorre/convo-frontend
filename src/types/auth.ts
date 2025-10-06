export interface AuthUser {
  fullName: string;
  _id: number;
  email: string;
  profilePic: string;
}

export interface AuthState {
  authUser: AuthUser | null;
  isCheckingAuth: boolean;
  isSigningUp: boolean;

  isLoggingIn: boolean;
  checkAuth: () => Promise<void>;
  signUp: (data: unknown) => Promise<void>;

  login: (data: unknown) => Promise<void>;
  logout: () => void;
}
