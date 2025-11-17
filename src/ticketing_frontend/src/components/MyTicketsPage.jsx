import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';

const MyTicketsPage = () => {
  const { actor, isAuthenticated } = useAuth();

  const { data: tickets, isLoading } = useQuery({
    queryKey: ['my-tickets'],
    queryFn: async () => {
      const result = await actor.getMyTickets();
      if ('ok' in result) {
        return result.ok;
      }
      return [];
    },
    enabled: isAuthenticated,
  });

  if (!isAuthenticated) {
    return <div>Please login to see your tickets.</div>;
  }

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <h1>My Tickets</h1>
      <div className="ticket-list">
        {tickets.map((ticket) => (
          <div key={ticket.id} className="ticket-card">
            <h2>Event: {ticket.event.name}</h2>
            <p>
              <strong>Date:</strong>{' '}
              {new Date(Number(ticket.event.date / 1000000n)).toLocaleString()}
            </p>
            <p>
              <strong>Venue:</strong> {ticket.event.venue}
            </p>
            <p>
              <strong>QR Code:</strong> {ticket.qrCode}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default MyTicketsPage;
