import axiosInstance from "@/config/axios";
import toast from "react-hot-toast";
import { create } from "zustand";

interface ChatStore {
  allContacts: Array<unknown>;
  chats: Array<unknown>;
  messages: Array<unknown>;
  activeTab: "chats" | "contacts";
  selectedUser: unknown | null;
  isUsersLoading: boolean;
  isMessagesLoading: boolean;
  isSoundEnabled: boolean;
  toggleSound: () => void;
  setActiveTab: (tab: "chats" | "contacts") => void;
  setSelectedUser: (user: unknown | null) => void;
  getAllContacts: () => Promise<void>;
  getMyChatPartners: () => Promise<void>;
}

export const useChatStore = create<ChatStore>((set, get) => ({
  allContacts: [],
  chats: [],
  messages: [],
  activeTab: "chats",
  selectedUser: null,
  isUsersLoading: false,
  isMessagesLoading: false,
  isSoundEnabled: localStorage.getItem("soundEnabled") === "true",

  toggleSound: () => {
    localStorage.setItem("soundEnabled", (!get().isSoundEnabled).toString());
    set({ isSoundEnabled: !get().isSoundEnabled });
  },

  setActiveTab: (tab) => set({ activeTab: tab }),
  setSelectedUser: (selectedUser) => set({ selectedUser }),

  getAllContacts: async () => {
    set({ isUsersLoading: true });
    try {
      const res = await axiosInstance.get("/messages/contacts");
      set({ allContacts: res.data });
    } catch (e) {
      console.log("Error fetching contacts: ", e);
      toast.error("Failed to load contacts");
    } finally {
      set({ isUsersLoading: false });
    }
  },

  getMyChatPartners: async () => {
    set({ isUsersLoading: true });
    try {
      const res = await axiosInstance.get("/messages/chats");
      set({ chats: res.data });
    } catch (e) {
      console.log("Error fetching chat partners: ", e);
      toast.error("Failed to load chat partners");
    } finally {
      set({ isUsersLoading: false });
    }
  },
}));
