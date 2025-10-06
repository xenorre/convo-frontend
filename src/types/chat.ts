import type { AuthUser } from "./auth";
import type { Message } from "./message";

export interface ChatStore {
  allContacts: AuthUser[];
  chats: AuthUser[];
  messages: Message[];
  activeTab: "chats" | "contacts";
  selectedUser: AuthUser | null;
  isUsersLoading: boolean;
  isMessagesLoading: boolean;
  setActiveTab: (tab: "chats" | "contacts") => void;
  setSelectedUser: (user: AuthUser | null) => void;
  getAllContacts: () => Promise<void>;
  getMyChatPartners: () => Promise<void>;
  getMessagesByUserId: (userId: string) => Promise<void>;
  sendMessage: (messageData: {
    text?: string;
    image?: string | null;
  }) => Promise<void>;
  subscribeToMessages: () => void;
  unsubscribeFromMessage: () => void;
}
