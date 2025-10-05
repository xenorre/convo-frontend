import axiosInstance from "@/config/axios";
import toast from "react-hot-toast";
import { create } from "zustand";
import type { AuthUser } from "./useAuthStore";

interface ChatStore {
  allContacts: AuthUser[];
  chats: AuthUser[];
  messages: Array<unknown>;
  activeTab: "chats" | "contacts";
  selectedUser: unknown | null;
  isUsersLoading: boolean;
  isMessagesLoading: boolean;
  setActiveTab: (tab: "chats" | "contacts") => void;
  setSelectedUser: (user: unknown | null) => void;
  getAllContacts: () => Promise<void>;
  getMyChatPartners: () => Promise<void>;
}

export const useChatStore = create<ChatStore>((set) => ({
  allContacts: [],
  chats: [],
  messages: [],
  activeTab: "chats",
  selectedUser: null,
  isUsersLoading: false,
  isMessagesLoading: false,

  setActiveTab: (tab) => set({ activeTab: tab }),
  setSelectedUser: (selectedUser) => set({ selectedUser }),

  getAllContacts: async () => {
    set({ isUsersLoading: true });
    try {
      const res = await axiosInstance.get("/messages/contacts");
      console.log("Fetched contacts: ", res.data);
      // Extract users array from API response
      const users = res.data?.users || [];
      const allContacts = Array.isArray(users) ? users : [];
      set({ allContacts });
    } catch (e) {
      console.log("Error fetching contacts: ", e);
      toast.error("Failed to load contacts");
      // Set empty array on error to prevent map errors
      set({ allContacts: [] });
    } finally {
      set({ isUsersLoading: false });
    }
  },

  getMyChatPartners: async () => {
    set({ isUsersLoading: true });
    try {
      const res = await axiosInstance.get("/messages/chats");
      console.log("Fetched chats: ", res.data);
      // Extract chats array from API response
      const chatsData = res.data?.chats || [];
      const chats = Array.isArray(chatsData) ? chatsData : [];
      set({ chats });
    } catch (e) {
      console.log("Error fetching chat partners: ", e);
      toast.error("Failed to load chat partners");
      // Set empty array on error to prevent map errors
      set({ chats: [] });
    } finally {
      set({ isUsersLoading: false });
    }
  },
}));
