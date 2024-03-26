import { expect, test } from "vitest";
import { Actor, CanisterStatus, HttpAgent } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { tripdriveCanister, tripdrive } from "./actor";

test("should create user account", async () => {
  const result1 = await tripdrive.create_user_acc(
    'record{username: "samuel", email: "samuel@gmail.com", phone_number: "0771212234" }'
  );
  expect(result1).toBe("Hello, test!");
});

test("Should contain a candid interface", async () => {
  const agent = Actor.agentOf(tripdrive) as HttpAgent;
  const id = Principal.from(tripdriveCanister);

  const canisterStatus = await CanisterStatus.request({
    canisterId: id,
    agent,
    paths: ["time", "controllers", "candid"],
  });

  expect(canisterStatus.get("time")).toBeTruthy();
  expect(Array.isArray(canisterStatus.get("controllers"))).toBeTruthy();
  expect(canisterStatus.get("candid")).toMatchInlineSnapshot(`
    "service : {
        cancel_request: (RequestID) -> (text);
        change_price: (RequestID, float64) -> ();
        create_driver_acc: (Car) -> ();
        create_request: (RequestInput) -> (RequestID);
        create_user_acc: (UserInput) -> (text);
        finished_ride: (RideID) -> () oneway;
        query_passengers_available: (QueryPassengers) -> (vec FullRequestInfo);
        select_user: (RequestID, nat) -> ();
    }
    "
  `);
});
