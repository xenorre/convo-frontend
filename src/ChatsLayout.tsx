import ActiveTabSwitch from "./components/ActiveTabSwitch";
import BorderAnimatedContainer from "./components/BorderAnimatedContainer";
import ChatContainer from "./components/ChatContainer";
import ChatsList from "./components/ChatsList";
import ContactsList from "./components/ContactsList";
import NoConversationPlaceholder from "./components/NoConversationPlaceholder";
import ProfileHeader from "./components/ProfileHeader";
import { useChatStore } from "./store/useChatStore";

function ChatsLayout({ children }: { children: React.ReactNode }) {
  const { activeTab, selectedUser } = useChatStore();
  return (
    <div className="relative w-full max-w-6xl lg:h-[700px] h-[650px]">
      <BorderAnimatedContainer>
        <div className="w-80 bg-slate-800/50 backdrop-blur-sm flex flex-col">
          <ProfileHeader />
          <ActiveTabSwitch />

          <div className="flex-1 overflow-y-auto p-4 space-y-2">
            {activeTab === "chats" ? <ChatsList /> : <ContactsList />}
          </div>
          {children}
        </div>

        <div className="flex-1 flex flex-col bg-slate-900/50 backdrop-blur-sm">
          {selectedUser ? <ChatContainer /> : <NoConversationPlaceholder />}
        </div>
      </BorderAnimatedContainer>
    </div>
  );
}

export default ChatsLayout;
