'use client';

import { useMemo } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts';
import { formatDate } from '@/lib/utils';
import type { WeeklyEntry } from '@/types/models';

export function EntriesChart({ entries }: { entries: WeeklyEntry[] }) {
  const chartData = useMemo(() => {
    // Sort entries by date ascending
    const sorted = [...entries].sort((a, b) => {
      const dateA = a.entryDate ? new Date(a.entryDate).getTime() : 0;
      const dateB = b.entryDate ? new Date(b.entryDate).getTime() : 0;
      return dateA - dateB;
    });

    return sorted.map((entry) => ({
      date: entry.entryDate ? formatDate(entry.entryDate) : 'Unknown',
      mortality: entry.mortalityCount,
      weight: entry.averageWeightKg,
      feed: entry.feedConsumedKg,
      water: entry.waterConsumedLitres,
    }));
  }, [entries]);

  if (!entries || entries.length === 0) return null;

  return (
    <div className="w-full h-[300px] mt-6">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
          <XAxis 
            dataKey="date" 
            stroke="#888888" 
            fontSize={12} 
            tickLine={false} 
            axisLine={false} 
          />
          <YAxis 
            yAxisId="left" 
            stroke="#888888" 
            fontSize={12} 
            tickLine={false} 
            axisLine={false} 
            tickFormatter={(value) => `${value}`}
          />
          <YAxis 
            yAxisId="right" 
            orientation="right" 
            stroke="#888888" 
            fontSize={12} 
            tickLine={false} 
            axisLine={false}
          />
          <Tooltip
            contentStyle={{ backgroundColor: '#1A1200', border: '1px solid rgba(244,169,0,0.4)', borderRadius: '12px' }}
            itemStyle={{ color: '#E5E7EB' }}
          />
          <Legend wrapperStyle={{ paddingTop: '20px' }} />
          <Line 
            yAxisId="left" 
            type="monotone" 
            dataKey="mortality" 
            name="Mortality (birds)" 
            stroke="#F87171" 
            strokeWidth={3}
            dot={{ r: 4, strokeWidth: 2 }}
            activeDot={{ r: 6 }} 
          />
          <Line 
            yAxisId="right" 
            type="monotone" 
            dataKey="weight" 
            name="Avg Weight (kg)" 
            stroke="#4ADE80" 
            strokeWidth={3}
            dot={{ r: 4, strokeWidth: 2 }}
            activeDot={{ r: 6 }} 
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}