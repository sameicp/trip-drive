import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from "isomorphic-fetch";
import canisterIds from ".dfx/local/canister_ids.json";
import { idlFactory } from "../declarations/tripdrive_backend/tripdrive_backend.did.js";
import { identity } from "./identity.ts";

export const createActor = async (canisterId, options) => {
  const agent = new HttpAgent({ ...options?.agentOptions });
  await agent.fetchRootKey();

  // Creates an actor with using the candid interface and the HttpAgent
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options?.actorOptions,
  });
};

export const tripdriveCanister = canisterIds.tripdrive_backend.local;

export const tripdrive = await createActor(tripdriveCanister, {
  agentOptions: {
    host: "http://127.0.0.1:8000",
    fetch,
    identity: await identity,
  },
});
