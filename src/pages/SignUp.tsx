import { useState } from "react";
import { useAuthStore } from "@/store/useAuthStore";
import BorderAnimatedContainer from "@/components/BorderAnimatedContainer";
import {
  Check,
  LoaderCircle,
  LockIcon,
  MailIcon,
  MessageCircle,
  UserIcon,
} from "lucide-react";
import { Link } from "react-router";

function SignUp() {
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
    <div className="w-full flex items-center justify-center p-4 bg-slate-900">
      <div className="relative w-full max-w-6xl lg:h-[700px] h-[650px]">
        <BorderAnimatedContainer>
          <div className="w-full flex flex-col md:flex-row">
            <div className="w-full lg:w-1/2 p-8 flex items-center justify-center md:border-r border-slate-600/30">
              <div className="max-w-md w-full">
                <div className="flex items-center gap-3 mb-12">
                  <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                    <MessageCircle className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-2xl font-bold text-white">Convo</span>
                </div>

                <div className="space-y-3 mb-10">
                  <h1 className="text-3xl font-semibold text-white tracking-tight">
                    Create Account
                  </h1>
                  <p className="text-slate-400">
                    Sign up to get started with ChatFlow
                  </p>
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
              </div>
            </div>
            <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-[600px] h-[600px] rounded-full blur-[150px]" />

              {/* Content */}
              <div className="relative z-10 flex flex-col justify-center w-full px-20 py-20">
                <div className="space-y-6 mb-16">
                  <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-blue-500/10 border border-blue-500/20">
                    <div className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-pulse" />
                    <span className="text-xs font-medium text-blue-300 tracking-wide">
                      TRUSTED BY 50,000+ USERS
                    </span>
                  </div>

                  <h2 className="text-4xl font-semibold text-white leading-tight tracking-tight max-w-lg">
                    Connect with your team, anywhere
                  </h2>

                  <p className="text-lg text-slate-400 leading-relaxed max-w-md">
                    Experience seamless communication with enterprise-grade
                    security and reliability.
                  </p>
                </div>

                <div className="space-y-4 mb-16">
                  <div className="flex items-start gap-3 group">
                    <div className="w-5 h-5 rounded-full bg-blue-500/10 flex items-center justify-center mt-0.5 group-hover:bg-blue-500/20 transition-colors">
                      <Check className="w-3 h-3 text-blue-400" />
                    </div>
                    <div>
                      <h3 className="text-white font-medium mb-1">
                        End-to-end encryption
                      </h3>
                      <p className="text-sm text-slate-400">
                        Your conversations stay private and secure
                      </p>
                    </div>
                  </div>

                  <div className="flex items-start gap-3 group">
                    <div className="w-5 h-5 rounded-full bg-blue-500/10 flex items-center justify-center mt-0.5 group-hover:bg-blue-500/20 transition-colors">
                      <Check className="w-3 h-3 text-blue-400" />
                    </div>
                    <div>
                      <h3 className="text-white font-medium mb-1">
                        Real-time collaboration
                      </h3>
                      <p className="text-sm text-slate-400">
                        Work together seamlessly across teams
                      </p>
                    </div>
                  </div>

                  <div className="flex items-start gap-3 group">
                    <div className="w-5 h-5 rounded-full bg-blue-500/10 flex items-center justify-center mt-0.5 group-hover:bg-blue-500/20 transition-colors">
                      <Check className="w-3 h-3 text-blue-400" />
                    </div>
                    <div>
                      <h3 className="text-white font-medium mb-1">
                        99.9% uptime guarantee
                      </h3>
                      <p className="text-sm text-slate-400">
                        Always available when you need it
                      </p>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-12 pt-8 border-t border-slate-800">
                  <div>
                    <div className="text-3xl font-semibold text-white mb-1">
                      50K+
                    </div>
                    <div className="text-sm text-slate-400">Active users</div>
                  </div>

                  <div>
                    <div className="text-3xl font-semibold text-white mb-1">
                      99.9%
                    </div>
                    <div className="text-sm text-slate-400">Uptime</div>
                  </div>

                  <div>
                    <div className="text-3xl font-semibold text-white mb-1">
                      4.9★
                    </div>
                    <div className="text-sm text-slate-400">User rating</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </BorderAnimatedContainer>
      </div>
    </div>
  );
}

export default SignUp;
