import React from 'react';
import { Routes, Route, Link } from 'react-router-dom';
import HomePage from './components/HomePage';
import EventDetailsPage from './components/EventDetailsPage';
import CreateEventPage from './components/CreateEventPage';
import MyTicketsPage from './components/MyTicketsPage';
import ProfilePage from './components/ProfilePage';
import { useAuth } from './context/AuthContext';

function App() {
  const { isAuthenticated, login, logout, identity } = useAuth();

  return (
    <div>
      <nav>
        <ul>
          <li>
            <Link to="/">Home</Link>
          </li>
          <li>
            <Link to="/create-event">Create Event</Link>
          </li>
          <li>
            <Link to="/my-tickets">My Tickets</Link>
          </li>
          <li>
            <Link to="/profile">Profile</Link>
          </li>
        </ul>
        {isAuthenticated ? (
          <div>
            <p>Welcome, {identity.getPrincipal().toText()}</p>
            <button onClick={logout}>Logout</button>
          </div>
        ) : (
          <button onClick={login}>Login</button>
        )}
      </nav>

      <main>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/event/:id" element={<EventDetailsPage />} />
          <Route path="/create-event" element={<CreateEventPage />} />
          <Route path="/my-tickets" element={<MyTicketsPage />} />
          <Route path="/profile" element={<ProfilePage />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;
