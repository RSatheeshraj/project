'use client';

import { useState } from 'react';
import { Bell, CheckCircle2, Clock, Syringe, Wheat, FileText, Plus, Edit2, Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { PageLoader, ErrorState, EmptyState } from '@/components/ui/States';
import { Modal } from '@/components/ui/Modal';
import { useReminders } from '@/hooks/useReminders';
import { ReminderForm } from './ReminderForm';
import { useToast } from '@/components/ui/Toast';
import type { Reminder, ReminderInput } from '@/types/models';

type FilterType = 'All' | 'Pending' | 'Due Today' | 'Upcoming' | 'Overdue' | 'Completed';

// Dynamic status calculation
function getDynamicStatus(reminder: Reminder): FilterType {
  if (reminder.status === 'Completed') return 'Completed';

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const dueDate = new Date(reminder.dueDate);
  dueDate.setHours(0, 0, 0, 0);

  const diffTime = dueDate.getTime() - today.getTime();
  const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'Overdue';
  if (diffDays === 0) return 'Due Today';
  if (diffDays > 0 && diffDays <= 7) return 'Upcoming';
  
  return 'Pending';
}

export function RemindersClient() {
  const { reminders, isLoading, isError, error, addReminder, updateReminder, deleteReminder, isAdding, isUpdating } = useReminders();
  const { toast } = useToast();
  
  const [filter, setFilter] = useState<FilterType>('All');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingReminder, setEditingReminder] = useState<Reminder | null>(null);

  const handleAddClick = () => {
    setEditingReminder(null);
    setIsModalOpen(true);
  };

  const handleEditClick = (reminder: Reminder) => {
    setEditingReminder(reminder);
    setIsModalOpen(true);
  };

  const handleDeleteClick = async (id: string) => {
    if (confirm('Are you sure you want to delete this reminder?')) {
      try {
        await deleteReminder(id);
        toast('Reminder deleted', 'success');
      } catch (err) {
        toast(err instanceof Error ? err.message : 'Failed to delete reminder', 'error');
      }
    }
  };

  const markCompleted = async (id: string) => {
    try {
      await updateReminder({ id, data: { status: 'Completed' } });
      toast('Reminder marked as completed', 'success');
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Failed to update reminder', 'error');
    }
  };

  const handleFormSubmit = async (data: ReminderInput) => {
    try {
      if (editingReminder) {
        await updateReminder({ id: editingReminder.id, data });
        toast('Reminder updated successfully', 'success');
      } else {
        await addReminder(data);
        toast('Reminder created successfully', 'success');
      }
      setIsModalOpen(false);
    } catch (err) {
      console.error('Failed to save reminder:', err);
      toast(err instanceof Error ? err.message : 'Failed to save reminder', 'error');
    }
  };

  const getIcon = (category: string) => {
    switch (category) {
      case 'Vaccination': return <Syringe className="w-5 h-5 text-blue-500" />;
      case 'Weekly Entry': return <FileText className="w-5 h-5 text-orange-500" />;
      case 'Feed': return <Wheat className="w-5 h-5 text-amber-500" />;
      case 'Medicine': return <Syringe className="w-5 h-5 text-red-500" />;
      default: return <Bell className="w-5 h-5 text-muted-foreground" />;
    }
  };

  const getStatusColor = (status: FilterType) => {
    switch (status) {
      case 'Completed': return 'text-green-500 bg-green-500/10 border-green-500/20';
      case 'Overdue': return 'text-red-500 bg-red-500/10 border-red-500/20';
      case 'Due Today': return 'text-orange-500 bg-orange-500/10 border-orange-500/20';
      case 'Upcoming': return 'text-blue-500 bg-blue-500/10 border-blue-500/20';
      case 'Pending': return 'text-gray-500 bg-gray-500/10 border-gray-500/20';
      default: return 'text-gray-500 bg-gray-500/10 border-gray-500/20';
    }
  };

  if (isLoading) return <PageLoader />;
  if (isError) return <ErrorState title="Failed to load reminders" message={error?.message} />;

  const remindersWithDynamicStatus = reminders.map(r => ({
    ...r,
    displayStatus: getDynamicStatus(r)
  }));

  const filteredReminders = remindersWithDynamicStatus.filter(r => {
    if (filter === 'All') return true;
    return r.displayStatus === filter;
  });

  const activeReminders = filteredReminders.filter(r => r.displayStatus !== 'Completed');
  const completedReminders = filteredReminders.filter(r => r.displayStatus === 'Completed');

  const filters: FilterType[] = ['All', 'Pending', 'Due Today', 'Upcoming', 'Overdue', 'Completed'];

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4 flex-wrap">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Reminders & Tasks</h2>
          <p className="text-muted-foreground text-sm mt-1">Manage vaccinations, feed schedules, and entries.</p>
        </div>
        <div className="flex-1" />
        <Button onClick={handleAddClick} style={{ background: 'linear-gradient(135deg, #F4A900, #d4920a)', color: '#1A1200' }}>
          <Plus className="w-4 h-4 mr-2" />
          Add Reminder
        </Button>
      </div>

      <div className="flex flex-wrap gap-2">
        {filters.map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
              filter === f 
                ? 'bg-[#F4A900] text-[#1A1200]' 
                : 'bg-card border border-border text-muted-foreground hover:text-foreground'
            }`}
          >
            {f}
          </button>
        ))}
      </div>

      {reminders.length === 0 ? (
        <EmptyState
          title="No Reminders"
          description="You don't have any reminders yet. Create one to stay organized."
          action={<Button onClick={handleAddClick}>Add Reminder</Button>}
        />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-4">
            <h3 className="font-bold text-lg">Active Tasks</h3>
            {activeReminders.map(reminder => (
              <div key={reminder.id} className="rounded-2xl border border-border bg-card p-5 glass group transition-all relative">
                
                <div className="absolute top-4 right-4 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    onClick={() => handleEditClick(reminder)}
                    className="p-1.5 rounded-md hover:bg-accent text-muted-foreground hover:text-foreground transition-colors"
                    title="Edit"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDeleteClick(reminder.id)}
                    className="p-1.5 rounded-md hover:bg-red-500/10 text-muted-foreground hover:text-red-500 transition-colors"
                    title="Delete"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>

                <div className="flex gap-4 pr-16">
                  <div className="w-12 h-12 rounded-full bg-accent flex items-center justify-center shrink-0">
                    {getIcon(reminder.category)}
                  </div>
                  <div className="flex-1">
                    <div className="flex justify-between items-start flex-wrap gap-2">
                      <h3 className="font-bold text-lg">{reminder.title}</h3>
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${getStatusColor(reminder.displayStatus)}`}>
                        {reminder.displayStatus}
                      </span>
                    </div>
                    {reminder.description && (
                      <p className="text-sm text-muted-foreground mt-1">{reminder.description}</p>
                    )}
                    <div className="flex items-center flex-wrap gap-4 mt-4">
                      <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground bg-background px-3 py-1.5 rounded-lg border border-border/50">
                        <Clock className="w-3.5 h-3.5 text-[#F4A900]" />
                        {reminder.dueDate.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })}
                      </div>
                      <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground bg-background px-3 py-1.5 rounded-lg border border-border/50">
                        <Bell className="w-3.5 h-3.5" />
                        {reminder.category}
                      </div>
                      
                      <div className="flex-1" />
                      
                      <Button size="sm" variant="outline" className="h-8 text-xs hover:bg-green-500/10 hover:text-green-500 hover:border-green-500/30" onClick={() => markCompleted(reminder.id)}>
                        <CheckCircle2 className="w-4 h-4 mr-1.5" />
                        Mark as Done
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
            {activeReminders.length === 0 && (
              <div className="text-center py-8 text-muted-foreground bg-card/50 border border-border/50 rounded-2xl glass">
                No active tasks match this filter.
              </div>
            )}
          </div>

          <div className="space-y-4">
            <h3 className="font-bold text-lg flex items-center justify-between">
              Completed Tasks
              <span className="text-xs bg-green-500/10 text-green-500 px-2.5 py-1 rounded-full">{completedReminders.length}</span>
            </h3>
            <div className="rounded-2xl border border-border bg-card p-5 glass space-y-4">
              {completedReminders.length === 0 ? (
                <p className="text-sm text-muted-foreground text-center py-4">No completed tasks yet.</p>
              ) : (
                completedReminders.map(reminder => (
                  <div key={reminder.id} className="flex gap-3 items-start pb-4 border-b border-border/50 last:border-0 last:pb-0 relative group">
                    <CheckCircle2 className="w-5 h-5 text-green-500 shrink-0 mt-0.5" />
                    <div className="flex-1">
                      <h4 className="font-semibold text-sm line-through text-muted-foreground">{reminder.title}</h4>
                      <p className="text-xs text-muted-foreground/70 flex items-center gap-1 mt-1">
                        <Clock className="w-3 h-3" />
                        {reminder.dueDate.toLocaleDateString()}
                      </p>
                    </div>
                    <div className="absolute right-0 top-0 opacity-0 group-hover:opacity-100 transition-opacity flex">
                      <button
                        onClick={() => handleDeleteClick(reminder.id)}
                        className="p-1 rounded text-muted-foreground hover:text-red-500"
                        title="Delete"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      <Modal
        open={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingReminder ? 'Edit Reminder' : 'Add Reminder'}
      >
        <ReminderForm
          defaultValues={editingReminder || undefined}
          onSubmit={handleFormSubmit}
          onCancel={() => setIsModalOpen(false)}
          loading={isAdding || isUpdating}
        />
      </Modal>
    </div>
  );
}
