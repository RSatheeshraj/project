'use client';

import { useState } from 'react';
import { Search, Phone, MessageCircle, Mail, MapPin, Stethoscope, Plus, Edit2, Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { PageLoader, EmptyState, ErrorState } from '@/components/ui/States';
import { Modal } from '@/components/ui/Modal';
import { useVeterinarians } from '@/hooks/useVeterinarians';
import type { Veterinarian, VeterinarianInput } from '@/types/models';
import { VeterinarianForm } from './VeterinarianForm';

export function DirectoryClient() {
  const { veterinarians, isLoading, isError, error, addVeterinarian, updateVeterinarian, deleteVeterinarian, isAdding, isUpdating } = useVeterinarians();
  
  const [searchTerm, setSearchTerm] = useState('');
  const [showEmergencyOnly, setShowEmergencyOnly] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingVet, setEditingVet] = useState<Veterinarian | null>(null);

  const filteredVets = veterinarians.filter(vet => {
    const matchesSearch = vet.doctorName.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          vet.address.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesEmergency = showEmergencyOnly ? vet.isEmergency : true;
    return matchesSearch && matchesEmergency;
  });

  const handleAddClick = () => {
    setEditingVet(null);
    setIsModalOpen(true);
  };

  const handleEditClick = (vet: Veterinarian) => {
    setEditingVet(vet);
    setIsModalOpen(true);
  };

  const handleDeleteClick = async (id: string) => {
    if (confirm('Are you sure you want to delete this veterinarian?')) {
      await deleteVeterinarian(id);
    }
  };

  const handleEmailClick = (e: React.MouseEvent, email?: string) => {
    e.preventDefault();
    if (!email || email.trim() === '') {
      alert('Email address not available.');
      return;
    }
    let cleanEmail = email.trim();
    if (cleanEmail.toLowerCase().startsWith('mailto:')) {
      cleanEmail = cleanEmail.substring(7);
    }
    if (cleanEmail.toLowerCase().startsWith('https://')) {
      cleanEmail = cleanEmail.substring(8);
    }
    window.location.href = `mailto:${cleanEmail}`;
  };

  const handleFormSubmit = async (data: VeterinarianInput) => {
    try {
      if (editingVet) {
        await updateVeterinarian({ id: editingVet.id, data });
      } else {
        await addVeterinarian(data);
      }
      setIsModalOpen(false);
    } catch (err) {
      console.error('Failed to save veterinarian:', err);
    }
  };

  if (isLoading) return <PageLoader />;
  if (isError) return <ErrorState title="Failed to load directory" message={error?.message} />;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Veterinarian Directory</h2>
          <p className="text-muted-foreground text-sm mt-1">Find expert poultry veterinarians near you.</p>
        </div>
        <Button onClick={handleAddClick} className="gap-2">
          <Plus className="w-4 h-4" />
          Add Veterinarian
        </Button>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search by name or clinic..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full h-10 pl-9 pr-4 rounded-xl border border-border bg-background text-sm focus:outline-none focus:border-[#F4A900] transition-colors"
          />
        </div>
        <Button 
          variant={showEmergencyOnly ? 'default' : 'outline'}
          onClick={() => setShowEmergencyOnly(!showEmergencyOnly)}
          className={showEmergencyOnly ? 'bg-red-500 hover:bg-red-600 text-white border-transparent' : ''}
        >
          {showEmergencyOnly ? 'Showing Emergency Only' : 'Show Emergency Only'}
        </Button>
      </div>

      {veterinarians.length === 0 ? (
        <EmptyState
          title="No Veterinarians"
          description="Your directory is currently empty. Add a veterinarian to get started."
          action={<Button onClick={handleAddClick}>Add Veterinarian</Button>}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {filteredVets.map(vet => (
            <div key={vet.id} className="relative rounded-2xl border border-border bg-card p-5 glass group transition-all hover:shadow-lg hover:shadow-[#F4A900]/5">
              
              {/* Edit/Delete Actions */}
              <div className="absolute top-4 right-4 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  onClick={() => handleEditClick(vet)}
                  className="p-1.5 rounded-md hover:bg-accent text-muted-foreground hover:text-foreground transition-colors"
                  title="Edit"
                >
                  <Edit2 className="w-4 h-4" />
                </button>
                <button
                  onClick={() => handleDeleteClick(vet.id)}
                  className="p-1.5 rounded-md hover:bg-red-500/10 text-muted-foreground hover:text-red-500 transition-colors"
                  title="Delete"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>

              <div className="flex justify-between items-start mb-4 pr-16">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-accent flex items-center justify-center shrink-0">
                    <Stethoscope className="w-6 h-6 text-[#F4A900]" />
                  </div>
                  <div>
                    <h3 className="font-bold text-lg leading-tight">{vet.doctorName}</h3>
                  </div>
                </div>
              </div>

              {vet.isEmergency && (
                <div className="mb-4">
                  <span className="px-2 py-1 bg-red-500/10 text-red-500 text-xs font-bold rounded-full animate-pulse">
                    Available for Emergency
                  </span>
                </div>
              )}

              <div className="space-y-2 text-sm mt-4 mb-6">
                <div className="flex items-start gap-2 text-muted-foreground">
                  <MapPin className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{vet.address}</span>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-2 pt-4 border-t border-border/50">
                <a href={`tel:${vet.phoneNumber}`} className="flex flex-col items-center gap-1 p-2 rounded-lg hover:bg-accent/50 transition-colors text-emerald-500" title="Call">
                  <Phone className="w-5 h-5" />
                  <span className="text-[10px] font-medium">Call</span>
                </a>
                <a href={`https://wa.me/${vet.whatsappNumber.replace(/[^0-9]/g, '')}`} target="_blank" rel="noreferrer" className="flex flex-col items-center gap-1 p-2 rounded-lg hover:bg-accent/50 transition-colors text-green-500" title="WhatsApp">
                  <MessageCircle className="w-5 h-5" />
                  <span className="text-[10px] font-medium">Chat</span>
                </a>
                <button onClick={(e) => handleEmailClick(e, vet.email)} className="flex flex-col items-center gap-1 p-2 rounded-lg hover:bg-accent/50 transition-colors text-blue-500" title="Email">
                  <Mail className="w-5 h-5" />
                  <span className="text-[10px] font-medium">Email</span>
                </button>
                <a href={`https://maps.google.com/?q=${encodeURIComponent(vet.address)}`} target="_blank" rel="noreferrer" className="flex flex-col items-center gap-1 p-2 rounded-lg hover:bg-accent/50 transition-colors text-orange-500" title="Map">
                  <MapPin className="w-5 h-5" />
                  <span className="text-[10px] font-medium">Map</span>
                </a>
              </div>
            </div>
          ))}
          {veterinarians.length > 0 && filteredVets.length === 0 && (
            <div className="col-span-full py-12 text-center text-muted-foreground">
              No veterinarians found matching your search.
            </div>
          )}
        </div>
      )}

      <Modal
        open={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingVet ? 'Edit Veterinarian' : 'Add Veterinarian'}
      >
        <VeterinarianForm
          defaultValues={editingVet || undefined}
          onSubmit={handleFormSubmit}
          onCancel={() => setIsModalOpen(false)}
          loading={isAdding || isUpdating}
        />
      </Modal>
    </div>
  );
}
