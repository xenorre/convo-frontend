import { create } from "zustand";
import axiosInstance from "@/config/axios";
import toast from "react-hot-toast";
import type { AuthState } from "@/types/auth";

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
    } catch (e: unknown) {
      console.log("Error during sign up: ", e);
      const error = e as { response?: { data?: { message?: string } } };
      toast.error(error?.response?.data?.message || "Sign up failed");
    } finally {
      set({ isSigningUp: false });
    }
  },

  login: async (data) => {
    set({ isLoggingIn: true });
    try {
      const res = await axiosInstance.post("/auth/login", data);

      // Check if response has user property or not
      const userData = res.data.user || res.data;
      set({ authUser: userData });

      toast.success("Logged in successfully");
    } catch (e: unknown) {
      console.log("Error during login: ", e);
      const error = e as { response?: { data?: { message?: string } } };
      toast.error(error?.response?.data?.message || "Login failed");
    } finally {
      set({ isLoggingIn: false });
    }
  },

  logout: async () => {
    try {
      await axiosInstance.post("/auth/logout");
      toast.success("Logged out successfully");
      set({ authUser: null });
    } catch (e: unknown) {
      console.log("Error during logout: ", e);
      const error = e as { response?: { data?: { message?: string } } };
      toast.error(error?.response?.data?.message || "Logout failed");
    }
  },
}));
