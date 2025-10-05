import { Link } from "react-router";
import { useState } from "react";
import { useAuthStore } from "@/store/useAuthStore";
import { LoaderCircle, LockIcon, MailIcon, UserIcon } from "lucide-react";

function SignUpForm() {
  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    password: "",
  });
  const { signUp, isSigningUp } = useAuthStore();

  const handleSubmit = (e) => {
    e.preventDefault();

    signUp(formData);
  };
  return (
    <>
      <div className="space-y-3 mb-10">
        <h1 className="text-3xl font-semibold text-white tracking-tight">
          Create Account
        </h1>
        <p className="text-slate-400">Sign up to get started with ChatFlow</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="auth-input-label">Full Name</label>
          <div className="relative">
            <UserIcon className="auth-input-icon" />
            <input
              type="text"
              value={formData.fullName}
              onChange={(e) =>
                setFormData({ ...formData, fullName: e.target.value })
              }
              className="input"
              placeholder="John Doe"
            />
          </div>
        </div>

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
          disabled={isSigningUp}
        >
          {isSigningUp ? (
            <LoaderCircle className="animate-spin" />
          ) : (
            "Create Account"
          )}
        </button>
      </form>

      <div className="mt-6 text-center">
        <Link to="/login" className="auth-link">
          Already have an account? Log in
        </Link>
      </div>
    </>
  );
}

export default SignUpForm;
