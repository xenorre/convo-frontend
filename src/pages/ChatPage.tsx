import ChatsLayout from "@/ChatsLayout";
import { useAuthStore } from "@/store/useAuthStore";

function ChatPage() {
  const { logout } = useAuthStore();

  return (
    <ChatsLayout>
      <button onClick={logout}>Logout</button>
    </ChatsLayout>
  );
}

export default ChatPage;
