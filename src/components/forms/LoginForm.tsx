import { useAuthStore } from "@/store/useAuthStore";
import { useState } from "react";
import { Link } from "react-router";
import { LoaderCircle, LockIcon, MailIcon } from "lucide-react";

function LoginForm() {
  const [formData, setFormData] = useState({
    email: "",
    password: "",
  });
  const { login, isLoggingIn } = useAuthStore();

  const handleSubmit = (e) => {
    e.preventDefault();

    login(formData);
  };
  return (
    <>
      {" "}
      <div className="space-y-3 mb-10">
        <h1 className="text-3xl font-semibold text-white tracking-tight">
          Welcome Back
        </h1>
        <p className="text-slate-400">Login to access your account</p>
      </div>
      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="auth-input-label">Email</label>
          <div className="relative">
            <MailIcon className="auth-input-icon" />
            <input
              type="text"
              value={formData.email}
              onChange={(e) =>
                setFormData({ ...formData, email: e.target.value })
              }
              className="input"
              placeholder="johndoe@example.com"
            />
          </div>
        </div>

        <div>
          <label className="auth-input-label">Password</label>
          <div className="relative">
            <LockIcon className="auth-input-icon" />
            <input
              type="password"
              value={formData.password}
              onChange={(e) =>
                setFormData({ ...formData, password: e.target.value })
              }
              className="input"
              placeholder="••••••••"
            />
          </div>
        </div>

        <button
          className="auth-btn"
          type="submit"
          onClick={handleSubmit}
          disabled={isLoggingIn}
        >
          {isLoggingIn ? <LoaderCircle className="animate-spin" /> : "Sign In"}
        </button>
      </form>
      <div className="mt-6 text-center">
        <Link to="/sign-up" className="auth-link">
          Don't have an account? Sign Up
        </Link>
      </div>
    </>
  );
}

export default LoginForm;
