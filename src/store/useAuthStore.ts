import { create } from "zustand";
import axiosInstance from "@/config/axios";
import toast from "react-hot-toast";
import type { AuthState } from "@/types/auth";
import { io } from "socket.io-client";

const BASE_URL =
  import.meta.env.MODE === "development"
    ? "http://localhost:3000"
    : "https://api.example.com";

export const useAuthStore = create<AuthState>((set, get) => ({
  authUser: null,
  isCheckingAuth: true,
  isSigningUp: false,

  isLoggingIn: false,
  socket: null,
  onlineUsers: [],
  checkAuth: async () => {
    try {
      const res = await axiosInstance.get("/auth/check");
      set({ authUser: res.data });
      get().connectSocket();
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

      get().connectSocket();
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

      get().connectSocket();
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
      get().disconnectSocket();
    } catch (e: unknown) {
      console.log("Error during logout: ", e);
      const error = e as { response?: { data?: { message?: string } } };
      toast.error(error?.response?.data?.message || "Logout failed");
    }
  },

  connectSocket: () => {
    const { authUser } = useAuthStore.getState();
    if (!authUser || get().socket?.connected) return;

    const socket = io(BASE_URL, {
      withCredentials: true,
    });

    socket.connect();

    set({ socket });

    socket.on("getOnlineUsers", (userIds) => {
      set({ onlineUsers: userIds });
    });
  },

  disconnectSocket: () => {
    if (get().socket?.connected) get().socket.disconnect();
  },
}));
