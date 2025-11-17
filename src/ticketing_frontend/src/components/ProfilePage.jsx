import React from 'react';
import { useAuth } from '../context/AuthContext';

const ProfilePage = () => {
  const { isAuthenticated, identity } = useAuth();

  if (!isAuthenticated) {
    return <div>Please login to see your profile.</div>;
  }

  return (
    <div>
      <h1>Profile</h1>
      <p>
        <strong>Principal ID:</strong> {identity.getPrincipal().toText()}
      </p>
    </div>
  );
};

export default ProfilePage;
