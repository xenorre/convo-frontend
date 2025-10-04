import { Route, Routes } from "react-router";
import ChatPage from "./pages/ChatPage";
import Login from "./pages/Login";
import SignUp from "./pages/SignUp";
import RootLayout from "./RootLayout";

function App() {
  return (
    <Routes>
      <Route path="/" element={<RootLayout />}>
        <Route index element={<ChatPage />} />
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<SignUp />} />
      </Route>
    </Routes>
  );
}

export default App;
