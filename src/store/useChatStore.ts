import axiosInstance from "@/config/axios";
import type { ChatStore } from "@/types/chat";
import toast from "react-hot-toast";
import { create } from "zustand";
import { useAuthStore } from "./useAuthStore";

export const useChatStore = create<ChatStore>((set, get) => ({
  allContacts: [],
  chats: [],
  messages: [],
  activeTab: "chats",
  selectedUser: null,
  isUsersLoading: false,
  isMessagesLoading: false,

  setActiveTab: (tab) => set({ activeTab: tab }),
  setSelectedUser: (selectedUser) => {
    set({ selectedUser });
  },

  getAllContacts: async () => {
    set({ isUsersLoading: true });
    try {
      const res = await axiosInstance.get("/messages/contacts");
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

  getMessagesByUserId: async (userId) => {
    set({ isMessagesLoading: true });
    try {
      const res = await axiosInstance.get(`/messages/${userId}`);
      // Extract messages array from API response
      const messagesData = res.data?.messages || [];
      const messages = Array.isArray(messagesData) ? messagesData : [];
      set({ messages });
    } catch (e) {
      console.log("Error fetching messages: ", e);
      toast.error("Failed to load messages");
      // Set empty array on error to prevent map errors
      set({ messages: [] });
    } finally {
      set({ isMessagesLoading: false });
    }
  },

  sendMessage: async (messageData) => {
    const { selectedUser, messages } = get();
    const { authUser } = useAuthStore.getState();

    if (!selectedUser || !authUser) {
      toast.error("No user selected");
      return;
    }

    const tempId = `temp-${Date.now()}`;

    // Optimistic message
    const optimisticMessage = {
      _id: tempId,
      senderId: authUser._id,
      receiverId: selectedUser._id,
      text: messageData.text || "",
      image: messageData.image || undefined,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    // Add optimistic message immediately
    set({ messages: [...messages, optimisticMessage] });

    try {
      let res;

      if (messageData.image) {
        // Convert base64 to File object for FormData
        const formData = new FormData();

        if (messageData.text) {
          formData.append("text", messageData.text);
        }

        // Convert base64 to blob
        const response = await fetch(messageData.image);
        const blob = await response.blob();

        // Create file from blob
        const file = new File([blob], "image.jpg", {
          type: blob.type || "image/jpeg",
        });
        formData.append("messageFile", file);

        res = await axiosInstance.post(
          `/messages/send/${selectedUser._id}`,
          formData,
          {
            headers: {
              "Content-Type": "multipart/form-data",
            },
          }
        );
      } else {
        // Text only - use JSON
        res = await axiosInstance.post(`/messages/send/${selectedUser._id}`, {
          text: messageData.text,
        });
      }

      // Handle different API response structures
      const messageFromAPI = res.data.message || res.data;

      // Replace optimistic message with real message from API
      set((state) => ({
        messages: state.messages.map((msg) =>
          msg._id === tempId ? messageFromAPI : msg
        ),
      }));
    } catch (e) {
      console.log("Error sending message: ", e);
      toast.error("Failed to send message");

      // Remove optimistic message on error
      set((state) => ({
        messages: state.messages.filter((msg) => msg._id !== tempId),
      }));
    }
  },
}));
