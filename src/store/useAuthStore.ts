import { create } from "zustand";
import axiosInstance from "@/config/axios.ts";
import toast from "react-hot-toast";

interface AuthUser {
  name: string;
  _id: number;
  age: number;
}

interface AuthState {
  authUser: AuthUser | null;
  isCheckingAuth: boolean;
  isSigningUp: boolean;
  isLoggingIn: boolean;
  checkAuth: () => Promise<void>;
  signUp: (data) => Promise<void>;
  login: (data) => Promise<void>;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  authUser: null,
  isCheckingAuth: true,
  isSigningUp: false,
  isLoggingIn: false,

  checkAuth: async () => {
    try {
      const res = await axiosInstance.get("/auth/check");
      set({ authUser: res.data });
    } catch (e) {
      console.log("Auth check failed", e);
      set({ authUser: null });
    } finally {
      set({ isCheckingAuth: false });
    }
  },

  signUp: async (data) => {
    set({ isSigningUp: true });
    try {
      const res = await axiosInstance.post("/auth/sign-up", data);
      set({ authUser: res.data });

      toast.success("Account created successfully");
    } catch (e) {
      console.log("Error during sign up: ", e);
      toast.error(e.response.data.message);
    } finally {
      set({ isSigningUp: false });
    }
  },

  login: async (data) => {
    set({ isLoggingIn: true });
    try {
      const res = await axiosInstance.post("/auth/login", data);
      set({ authUser: res.data });

      toast.success("Logged in successfully");
    } catch (e) {
      console.log("Error during login: ", e);
      toast.error(e.response.data.message);
    } finally {
      set({ isLoggingIn: false });
    }
  },

  logout: async () => {
    try {
      await axiosInstance.post("/auth/logout");
      toast.success("Logged out successfully");
      set({ authUser: null });
    } catch (e) {
      console.log("Error during logout: ", e);
      toast.error(e.response.data.message);
    }
  },
}));
