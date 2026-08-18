import { CheckCircle2 } from 'lucide-react';

export function FarmStatusBanner({ status }: { status?: string }) {
  const normalizedStatus = (status || 'Active').trim().toLowerCase();
  
  if (normalizedStatus !== 'completed' && normalizedStatus !== 'closed' && normalizedStatus !== 'archived') {
    return null;
  }
  
  const statusLabels: Record<string, string> = {
    'completed': 'Farm Completed',
    'closed': 'Farm Closed',
    'archived': 'Farm Archived'
  };

  return (
    <div className="rounded-xl p-4 mb-6 border border-green-500/30 bg-green-500/10 backdrop-blur-md relative overflow-hidden">
      <div className="absolute top-0 right-0 p-4 opacity-10">
        <CheckCircle2 className="w-24 h-24" />
      </div>
      <div className="relative z-10">
        <div className="flex items-center gap-2 mb-2">
          <CheckCircle2 className="w-5 h-5 text-green-400" />
          <h3 className="text-lg font-semibold text-green-400">
            {statusLabels[normalizedStatus] || 'Farm Inactive'}
          </h3>
        </div>
        <p className="text-sm text-green-400/80 mb-2">
          This farm has been marked as {normalizedStatus}. Editing has been disabled to preserve historical records.
        </p>
        <div className="text-xs text-green-400/70 font-medium">
          You can still:
          <ul className="list-disc list-inside mt-1 ml-1 opacity-80">
            <li>View History</li>
            <li>Generate Reports</li>
            <li>Download PDFs</li>
            <li>Review Sales</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
