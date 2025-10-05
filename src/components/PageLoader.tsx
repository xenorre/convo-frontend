import { LoaderCircle } from "lucide-react";

function PageLoader() {
  return (
    <div className="flex items-center justify-center h-screen">
      <LoaderCircle className="animate-spin size-10" />
    </div>
  );
}

export default PageLoader;
