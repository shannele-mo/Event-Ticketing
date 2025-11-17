import React, { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { useParams } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const EventDetailsPage = () => {
  const { id } = useParams();
  const { actor, isAuthenticated, identity } = useAuth();
  const [quantity, setQuantity] = useState(1);

  const { data: event, isLoading } = useQuery({
    queryKey: ['event', id],
    queryFn: async () => {
      const result = await actor.getEvent(BigInt(id));
      if ('ok' in result) {
        return result.ok;
      }
      return null;
    },
  });

  const purchaseMutation = useMutation({
    mutationFn: async () => {
      const result = await actor.purchaseTickets({
        eventId: BigInt(id),
        quantity: BigInt(quantity),
        totalPrice: event.pricePerTicket * BigInt(quantity),
        buyerAccount: {
          owner: identity.getPrincipal(),
          subaccount: [],
        },
      });
      if ('ok' in result) {
        return result.ok;
      }
      throw new Error('Purchase failed');
    },
    onSuccess: () => {
      alert('Purchase successful!');
    },
    onError: (error) => {
      alert(`Purchase failed: ${error.message}`);
    },
  });

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (!event) {
    return <div>Event not found</div>;
  }

  const handlePurchase = () => {
    if (!isAuthenticated) {
      alert('Please login to purchase tickets');
      return;
    }
    purchaseMutation.mutate();
  };

  return (
    <div>
      <img src={event.imageUrl} alt={event.name} />
      <h1>{event.name}</h1>
      <p>{event.description}</p>
      <p>
        <strong>Date:</strong> {new Date(Number(event.date / 1000000n)).toLocaleString()}
      </p>
      <p>
        <strong>Venue:</strong> {event.venue}
      </p>
      <p>
        <strong>Price per ticket:</strong> {Number(event.pricePerTicket)}
      </p>
      <p>
        <strong>Available tickets:</strong> {Number(event.availableTickets)}
      </p>
      <div>
        <label htmlFor="quantity">Quantity:</label>
        <input
          type="number"
          id="quantity"
          value={quantity}
          onChange={(e) => setQuantity(Number(e.target.value))}
          min="1"
          max={Number(event.availableTickets)}
        />
      </div>
      <button onClick={handlePurchase} disabled={purchaseMutation.isLoading}>
        {purchaseMutation.isLoading ? 'Purchasing...' : 'Purchase Tickets'}
      </button>
    </div>
  );
};

export default EventDetailsPage;
