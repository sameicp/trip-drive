import Types "/types";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Debug "mo:base/Debug"; // use when the canister traps.
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Array "mo:base/Array";

actor {
  // building the backend
  let users_map = TrieMap.TrieMap<Principal, Types.User>(Principal.equal, Principal.hash);
  let drivers_map = TrieMap.TrieMap<Principal, Types.Driver>(Principal.equal, Principal.hash);
  let ride_information_storage = TrieMap.TrieMap<Nat, Types.RideInformation>(Nat.equal, Hash.hash);

  // storing the list of passengers without a ride yet.
  let passengers_at_uz = Buffer.Buffer<Types.User>(0);
  let passengers_in_cbd = Buffer.Buffer<Types.User>(0);
  let drivers_at_uz = Buffer.Buffer<Types.Driver>(0);
  let drivers_in_cbd = Buffer.Buffer<Types.Driver>(0);

  // List for a list of requests
  stable var pool_requests = List.nil<Types.RideRequestType>();

  stable var request_id_counter = 0;

  let default_user: Types.User = {
    id = Principal.fromText("");
    username = "";
    email = "";
    phone_number = "";
    poster = Blob.fromArrayMut(Array.init(32, 0 : Nat8));
    var ride_history = List.nil<Types.RideID>();
  };

  func check_user_account(user_id: Principal): Bool {
    if (Principal.isAnonymous(user_id)) { 
      Debug.trap("Annonymous id.")
    };

    // checking if the caller have already registered to the application
    let option_user: ?Types.User = users_map.get(user_id);
    return Option.isSome(option_user);
  };

  public shared({caller}) func create_user_acc(username: Text, email: Text, phone_number: Text, poster: Blob): async (Text) {
  
    if(check_user_account(caller)) {
      Debug.trap("The user is already registered")
    };


    // creating the user account
    let ride_history = List.nil<Types.RideID>();

    let new_user: Types.User = {
      id = caller;
      username;
      email;
      phone_number;
      poster;
      var ride_history;
    };

    users_map.put(caller, new_user);
    return "User created successfuly";

  };

  // First the driver have to create an account as a normal user
  // get the driver basic infor from his user account
  // add some additonal about the driver like his car information
  // driver has to upload the images of his cars.
  public shared({caller}) func create_driver_acc(car: Types.Car): async() {
    // check if the driver has already created an account
    // If the caller is not registered to the application he is not supposed to create an account
    if(not check_user_account(caller)) {
      Debug.trap("Please start by creating an account as a user")
    };

    let option_user: ?Types.User = users_map.get(caller);
    let user: Types.User = Option.get(option_user, default_user);

    // check if the driver has already created an account
    let option_driver: ?Types.Driver = drivers_map.get(caller);
    if (Option.isSome(option_driver)) {
      Debug.trap("Driver account already exists");
    };

    // create an account if the account does not exist
    let new_driver: Types.Driver = {
      user;
      car;
    };

    // register the created account 
    drivers_map.put(caller, new_driver);
    
  };

  func new_request_id() : Types.RequestID {
    let id = request_id_counter;
    request_id_counter += 1;
    return id;
  };

  public shared({caller}) func create_request(from: Types.CurrentSupportedLocation, to: Types.CurrentSupportedLocation, price: Float): async(Types.RequestID) {
    if(not check_user_account(caller)) {
      Debug.trap("Please start by creating an account as a user")
    };

    // generation the id of the request
    let request_id: Types.RequestID = new_request_id();

    // creating users request and add it to a list of requests
    let request: Types.RideRequestType = {
      request_id;
      user_id = caller;
      from;
      to;
      var price;
    };

    // adding the request into a pool of request
    pool_requests := List.push(request, pool_requests);
    return request_id;

  };

  /// Define an internal helper function to retrieve auctions by ID:
  func find_request(request_id : Types.RequestID) : Types.RideRequestType {
    let result = List.find<Types.RideRequestType>(pool_requests, func request = request.request_id == request_id);
    switch (result) {
      case null Debug.trap("Inexistent id");
      case (?request) return request;
    };
  };

  // the users can have the option to cancel the request
  public shared({caller}) func cancel_request(id: Types.RequestID): async(Text) {
    // check if the user is the one who made the request
    let request = find_request(id);

    if (Principal.notEqual(caller, request.user_id)) {
      Debug.trap("You are not the one who made the request");
    };

    pool_requests := List.filter<Types.RideRequestType>(pool_requests, func request = request.request_id != id);
    return "request removed";
  }
};


