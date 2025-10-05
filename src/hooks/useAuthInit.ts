import { useEffect } from "react";
import { useAuthStore } from "@/store/useAuthStore";

export const useAuthInit = () => {
  const { checkAuth, authUser, isCheckingAuth } = useAuthStore();

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  return {
    authUser,
    isCheckingAuth,
    isAuthenticated: !!authUser,
  };
};
