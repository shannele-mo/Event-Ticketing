import React, { createContext, useContext, useEffect, useState } from 'react';
import { AuthClient } from '@dfinity/auth-client';
import { HttpAgent } from '@dfinity/agent';
import { ticketing_backend } from 'declarations/ticketing_backend';

export const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [identity, setIdentity] = useState(null);
  const [authClient, setAuthClient] = useState(null);
  const [actor, setActor] = useState(ticketing_backend);

  useEffect(() => {
    AuthClient.create().then(async (client) => {
      setAuthClient(client);
      const isAuthenticated = await client.isAuthenticated();
      setIsAuthenticated(isAuthenticated);
      if (isAuthenticated) {
        const identity = client.getIdentity();
        setIdentity(identity);
        const agent = new HttpAgent({ identity });
        const actor = ticketing_backend;
        setActor(actor);
      }
    });
  }, []);

  const login = async () => {
    await authClient.login({
      identityProvider:
        process.env.DFX_NETWORK === 'ic'
          ? 'https://identity.ic0.app/#authorize'
          : `http://localhost:4943?canisterId=${process.env.INTERNET_IDENTITY_CANISTER_ID}`,
      onSuccess: () => {
        const identity = authClient.getIdentity();
        setIdentity(identity);
        setIsAuthenticated(true);
        const agent = new HttpAgent({ identity });
        const actor = ticketing_backend;
        setActor(actor);
      },
    });
  };

  const logout = async () => {
    await authClient.logout();
    setIdentity(null);
    setIsAuthenticated(false);
    setActor(ticketing_backend);
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, login, logout, actor, identity }}>
      {children}
    </AuthContext.Provider>
  );
};
