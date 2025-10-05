import { Route, Routes } from "react-router";
import ChatPage from "@/pages/ChatPage";
import Login from "@/pages/Login";
import SignUp from "@/pages/SignUp";
import RootLayout from "@/RootLayout";
import { Toaster } from "react-hot-toast";
import { ProtectedRoute, PublicRoute } from "@/components/ProtectedRoute";
import { useAuthInit } from "@/hooks/useAuthInit";

function App() {
  const { authUser } = useAuthInit();

  console.log(authUser);

  return (
    <>
      <Routes>
        <Route path="/" element={<RootLayout />}>
          <Route
            index
            element={
              <ProtectedRoute>
                <ChatPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/login"
            element={
              <PublicRoute>
                <Login />
              </PublicRoute>
            }
          />
          <Route
            path="/sign-up"
            element={
              <PublicRoute>
                <SignUp />
              </PublicRoute>
            }
          />
        </Route>
      </Routes>
      <Toaster />
    </>
  );
}

export default App;
