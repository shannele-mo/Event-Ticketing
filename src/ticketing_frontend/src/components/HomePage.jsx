import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { Link } from 'react-router-dom';

const HomePage = () => {
  const { actor } = useAuth();

  const { data: events, isLoading } = useQuery({
    queryKey: ['events'],
    queryFn: async () => {
      const events = await actor.listEvents();
      return events;
    },
  });

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <h1>Events</h1>
      <div className="event-list">
        {events.map((event) => (
          <div key={event.id} className="event-card">
            <img src={event.imageUrl} alt={event.name} />
            <h2>{event.name}</h2>
            <p>{event.description}</p>
            <p>
              <strong>Date:</strong> {new Date(Number(event.date / 1000000n)).toLocaleString()}
            </p>
            <p>
              <strong>Venue:</strong> {event.venue}
            </p>
            <Link to={`/event/${event.id}`}>View Details</Link>
          </div>
        ))}
      </div>
    </div>
  );
};

export default HomePage;
