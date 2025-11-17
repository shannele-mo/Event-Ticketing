import React, { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

const CreateEventPage = () => {
  const { actor, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [venue, setVenue] = useState('');
  const [date, setDate] = useState('');
  const [totalTickets, setTotalTickets] = useState(100);
  const [pricePerTicket, setPricePerTicket] = useState(10);
  const [imageUrl, setImageUrl] = useState('');
  const [category, setCategory] = useState('');

  const createEventMutation = useMutation({
    mutationFn: async () => {
      const result = await actor.createEvent({
        name,
        description,
        venue,
        date: BigInt(new Date(date).getTime() * 1000000),
        totalTickets: BigInt(totalTickets),
        pricePerTicket: BigInt(pricePerTicket),
        imageUrl,
        category,
        metadata: [],
      });
      if ('ok' in result) {
        return result.ok;
      }
      throw new Error('Event creation failed');
    },
    onSuccess: (data) => {
      alert('Event created successfully!');
      navigate(`/event/${data}`);
    },
    onError: (error) => {
      alert(`Event creation failed: ${error.message}`);
    },
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!isAuthenticated) {
      alert('Please login to create an event');
      return;
    }
    createEventMutation.mutate();
  };

  return (
    <div>
      <h1>Create Event</h1>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="name">Name:</label>
          <input
            type="text"
            id="name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="description">Description:</label>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="venue">Venue:</label>
          <input
            type="text"
            id="venue"
            value={venue}
            onChange={(e) => setVenue(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="date">Date:</label>
          <input
            type="datetime-local"
            id="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="totalTickets">Total Tickets:</label>
          <input
            type="number"
            id="totalTickets"
            value={totalTickets}
            onChange={(e) => setTotalTickets(Number(e.target.value))}
            required
          />
        </div>
        <div>
          <label htmlFor="pricePerTicket">Price Per Ticket:</label>
          <input
            type="number"
            id="pricePerTicket"
            value={pricePerTicket}
            onChange={(e) => setPricePerTicket(Number(e.target.value))}
            required
          />
        </div>
        <div>
          <label htmlFor="imageUrl">Image URL:</label>
          <input
            type="text"
            id="imageUrl"
            value={imageUrl}
            onChange={(e) => setImageUrl(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="category">Category:</label>
          <input
            type="text"
            id="category"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            required
          />
        </div>
        <button type="submit" disabled={createEventMutation.isLoading}>
          {createEventMutation.isLoading ? 'Creating...' : 'Create Event'}
        </button>
      </form>
    </div>
  );
};

export default CreateEventPage;
