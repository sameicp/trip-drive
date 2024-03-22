import Types "/types";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";

actor {
  // building the backend
  let users_map = TrieMap.TrieMap<Principal, Types.User>(Principal.equal, Principal.hash);
  let drivers_map = TrieMap.TrieMap<Principal, Types.Driver>(Principal.equal, Principal.hash);
  let ride_information_storage = TrieMap.TrieMap<Nat, Types.RideInformation>(Nat.equal, Hash.hash);
  let user_ride_information = TrieMap.TrieMap<Principal, Buffer.Buffer<Types.RideInformation>>(Principal.equal, Principal.hash);
  let driver_ride_information = TrieMap.TrieMap<Principal, Buffer.Buffer<Types.RideInformation>>(Principal.equal, Principal.hash);

  // storing the list of passengers without a ride yet.
  let passengers_at_uz = Buffer.Buffer<Types.User>(0);
  let passengers_in_cbd = Buffer.Buffer<Types.User>(0);
  let drivers_at_uz = Buffer.Buffer<Types.Driver>(0);
  let drivers_in_cbd = Buffer.Buffer<Types.Driver>(0);
};


