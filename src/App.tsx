import { Route, Routes } from "react-router";
import ChatPage from "@/pages/ChatPage";
import Login from "@/pages/Login";
import SignUp from "@/pages/SignUp";
import RootLayout from "@/RootLayout";
import { Toaster } from "react-hot-toast";
import { ProtectedRoute, PublicRoute } from "@/components/ProtectedRoute";
import { useEffect } from "react";
import { useAuthStore } from "./store/useAuthStore";
import PageLoader from "./components/PageLoader";

function App() {
  const { checkAuth, isCheckingAuth } = useAuthStore();
  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  if (isCheckingAuth) return <PageLoader />;

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
          <Route
            path="settings"
            element={
              <ProtectedRoute>
                <div>Settings Page</div>
              </ProtectedRoute>
            }
          />
        </Route>
      </Routes>
      <Toaster />
    </>
  );
}

export default App;
