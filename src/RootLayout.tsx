import { Outlet } from "react-router";

function RootLayout() {
  return (
    <div className="min-h-screen bg-slate-900 relative flex items-center justify-center p-4 overflow-hidden">
      <div className="absolute inset-0 bg-[linear-gradient(to_right, #4f4f4f2e_1px, transparent_1px), linear-gradient(to_bottom, #4f4f4f2e_1px, transparent_1px)] bg-[size:14px_24px] -z-10 pointer-events-none" />
      <div className="absolute top-0 -left-4 size-96 bg-pink-500 opacity-20 blur-[100px] -z-0 pointer-events-none" />
      <div className="absolute bottom-0 -right-4 size-96 bg-cyan-500 opacity-20 blur-[100px] -z-0 pointer-events-none" />
      <Outlet />
    </div>
  );
}

export default RootLayout;
