import T "/types";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Debug "mo:base/Debug"; // use when the canister traps.
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Error "mo:base/Error";

actor {
  
  // storage.
  let users_map = TrieMap.TrieMap<Principal, T.User>(Principal.equal, Principal.hash);
  let drivers_map = TrieMap.TrieMap<Principal, T.Driver>(Principal.equal, Principal.hash);

  // a record of the rides on the platform.
  stable var ride_information_storage = List.nil<T.RideInformation>();


  // List for a list of requests
  stable var pool_requests = List.nil<T.RideRequestType>();
  stable var request_id_counter = 0;
  stable var ride_id_counter = 0;

  let default_user: T.User = {
    id = Principal.fromText("2vxsx-fae");
    username = "";
    email = "";
    phone_number = "";
    poster = Blob.fromArrayMut(Array.init(32, 0 : Nat8));
    var ride_history = List.nil<T.RideID>();
  };

  /////////////////////////
  /// PRIVATE METHODS   ///
  /////////////////////////

  func user_has_account(user_id: Principal): async Bool {
    if (Principal.isAnonymous(user_id)) { 
      Debug.trap("Annonymous id.")
    };

    // checking if the caller have already registered to the application
    let option_user: ?T.User = users_map.get(user_id);
    return Option.isSome(option_user);
  };

  func get_user_account(user_id: Principal): T.User {
    let option_user: ?T.User = users_map.get(user_id);
    let user: T.User = Option.get(option_user, default_user);
    return user;
  };

  func generate_request_id() : T.RequestID {
    let id = request_id_counter;
    request_id_counter += 1;
    return {
      request_id = id;
    };
  };

  func generate_ride_id() : T.RideID {
    let id = ride_id_counter;
    ride_id_counter += 1;
    return {
      ride_id = id;
    };
  };

  func validate_inputs(
    from: T.CurrentSupportedLocation, 
    to: T.CurrentSupportedLocation
  ): async() {
    if (from == to) {
      Debug.trap("select another destination.");
    }
  };

  /// Define an internal helper function to retrieve requests by ID:
  func find_request(request_id : T.RequestID) : ?T.RideRequestType {
    let result: ?T.RideRequestType = 
      List.find<T.RideRequestType>(pool_requests, func request = request.request_id == request_id);
    return result;
  };

  func extract_request(request_id : T.RequestID): T.RideRequestType {
    let request_option = find_request(request_id);
    return switch (request_option) {
      case null Debug.trap("Request id does not exist.");
      case (?request) request;
    };
  };

  func check_if_user_made_request(user_id: Principal, request_id: T.RequestID): async() {
    // check if the user is the one who made the request
    let request: T.RideRequestType = extract_request(request_id);
    if (Principal.notEqual(user_id, request.user_id)) {
      Debug.trap("You are not the one who made the request");
    };

  };

  // get useful user information
  func user_info(user_id: Principal): async T.Profile {
    // get user information
    let option_user: ?T.User = users_map.get(user_id);
    let user: T.User = switch (option_user) {
      case null Debug.trap("User this ID " # Principal.toText(user_id) # " does not exist.");
      case (?user) user;
    };

    let user_profile: T.Profile = {
      username = user.username;
      email = user.email;
      phone_number = user.phone_number;
      poster = user.poster;
    };
    return user_profile;
  };

  // this function has to take in a list of requests and return passenger info nad the request id
  func passenger_details(requests_list: [T.RideRequestType]): async [T.FullRequestInfo] {
    let output: Buffer.Buffer<T.FullRequestInfo> = 
      Buffer.Buffer<T.FullRequestInfo>(10);

    for(request in requests_list.vals()) {
      let profile: T.Profile = await user_info(request.user_id);
      let updated_info: T.FullRequestInfo = {
        profile;
        request_id = request.request_id;
        price = request.price;
      };
      output.add(updated_info);
    };
    return Buffer.toArray<T.FullRequestInfo>(output);
  };

  func approve_ride(driver_id: Principal, request: T.RideRequestType, date_of_ride: Nat): async () {
    let ride_id = create_ride_object(request, date_of_ride, driver_id);
    add_ride_id_to_passenger(request.user_id, ride_id);
    await add_ride_to_driver(driver_id, ride_id);
  };

  func create_ride_object(
    request: T.RideRequestType, 
    date_of_ride: Nat, 
    driver_id: Principal
  ): T.RideID {
    
    let ride_info: T.RideInformation = {
      ride_id = generate_ride_id();
      user_id = request.user_id;
      driver_id;
      origin = request.from;
      destination = request.to;
      var payment_status = #NotPaid;
      var price = request.price;
      var ride_status = #RideAccepted;
      date_of_ride; 
    };

    ride_information_storage := List.push(ride_info, ride_information_storage);
    return ride_info.ride_id;
  };

  // function that adds the ride id to list of rides that the user has done
  // the function takes the ride id as an argument and the user id
  func add_ride_id_to_passenger(user_id: Principal, ride_id: T.RideID) {
    // first we check if the account exists
    let user: T.User = get_user_account(user_id);
    user.ride_history := List.push(ride_id, user.ride_history);
  };

  // add the ride information to the driver's history to keep statistics
  func add_ride_to_driver(driver_id: Principal, ride_id: T.RideID): async() {
    let option_driver: ?T.Driver = drivers_map.get(driver_id);
    let driver: T.Driver = switch (option_driver) {
      case null Debug.trap("User this ID " # Principal.toText(driver_id) # " does not exist.");
      case (?driver) driver;
    };

    driver.user.ride_history := List.push(ride_id, driver.user.ride_history);

  };

  func get_ride_option(ride_id: T.RideID): ?T.RideInformation {
    let ride_option: ?T.RideInformation = List.find<T.RideInformation>(
      ride_information_storage, 
      func ride = ride.ride_id ==ride_id
    );
    return ride_option;
  };

  func get_ride(ride_id: T.RideID): T.RideInformation {
    let ride_option: ?T.RideInformation = get_ride_option(ride_id);
    return switch (ride_option) {
      case null Debug.trap("Inexistent ride id");
      case (?ride) return ride;
    };
  };

  func driver_already_exists(id: Principal): async() {
    let option_driver: ?T.Driver = drivers_map.get(id);

    if (Option.isSome(option_driver)) {
      Debug.trap("Driver account already exists");
    };
  };

  func _create_request(request_id: T.RequestID, user_id: Principal, request_input: T.RequestInput): T.RideRequestType {
    return {
      request_id;
      user_id;
      from = request_input.from;
      to = request_input.to;
      var status = #Pending;
      var price = request_input.price;
    };
  };

  func validate_driver(driver_id: Principal): async() {
    // check if the caller is the driver
    let option_driver: ?T.Driver = drivers_map.get(driver_id);
    if (Option.isNull(option_driver)) {
      Debug.trap("Driver not registered");
    };
  };

  func create_user(id: Principal, user_input: T.UserInput): T.User {
    let ride_history = List.nil<T.RideID>();
    return {
      id;
      username = user_input.username;
      email = user_input.email;
      phone_number = user_input.phone_number;
      poster = user_input.poster;
      var ride_history;
    };
  };

  func filter_request(requests_array: [T.RideRequestType], query_passengers: T.QueryPassengers): [T.RideRequestType] {
    return Array.filter<T.RideRequestType>(
          requests_array, 
          func request = 
            request.from == query_passengers.from 
            and request.to == query_passengers.to 
            and request.status != #Accepted
        );
  };

  func create_driver_object(user: T.User, car: T.Car): T.Driver {
    return {
        user;
        car;
      };
  };

  func remove_request(request_id: T.RequestID) {
    pool_requests := 
        List.filter<T.RideRequestType>(pool_requests, func request = request.request_id != request_id);
  };

  func check_principals(from_request: Principal, caller: Principal): async(){
    if(Principal.notEqual(from_request, caller)) {
      Debug.trap("not authorized to execute this function");
    };
  };

  func update_ride_status(ride: T.RideInformation) {
    ride.ride_status := #RideCompleted;
    ride.payment_status := #Paid;
  };

  func check_account(user_id:Principal): async() {
    if(await user_has_account(user_id)) {
      Debug.trap("The user is already registered")
    };
  };

  func check_user(user_id: Principal): async() {
    let is_user: Bool = await user_has_account(user_id);
    if(not is_user) {
      Debug.trap("Please start by creating an account as a user")
    };
  };

  func check_ride_info(ride_id: T.RideID): async () {
    let ride_option: ?T.RideInformation = get_ride_option(ride_id);
    if(Option.isNull(ride_option)) {
      Debug.trap("The information is not found.")
    };
  };

  func check_request(request_id: T.RequestID): async () {
    let request_option: ?T.RideRequestType = find_request(request_id);
    if(Option.isNull(request_option)) {
      Debug.trap("Request does not exist");
    };
  };

  ////////////////////
  // PUBLIC METHODS //
  ////////////////////

  ///////////////////////
  // Passenger Methods //
  ///////////////////////

  public shared({caller}) func create_user_acc(user_input: T.UserInput): async (Result.Result<Text, Text>) {
    try {
      await check_account(caller);
      // creating the user account
      let new_user: T.User = create_user(caller, user_input);
      users_map.put(caller, new_user);
      return #ok("User created successfuly");
    } catch e {
      return #err(Error.message(e))
    }

  };

  public shared({caller}) func create_request(request_input: T.RequestInput): async(Result.Result<T.RequestID, Text>) {
    try {
      await check_user(caller);
      await validate_inputs(request_input.from, request_input.to);
      // generation the id of the request
      let request_id: T.RequestID = generate_request_id();
      // creating users request and add it to a list of requests
      let request: T.RideRequestType = _create_request(request_id, caller, request_input);
      // adding the request into a pool of request
      pool_requests := List.push(request, pool_requests);
      return #ok(request_id);
    } catch e {
      return #err(Error.message(e));
    }
  };

  // the users can have the option to cancel the request
  public shared({caller}) func cancel_request(id: T.RequestID): async(Result.Result<Text, Text>) {
    try {
      // check if the user is the one who made the request
      await check_if_user_made_request(caller, id);
      remove_request(id);
      return #ok("request removed");
    } catch e {
      return #err(Error.message(e))
    }
  };

  // change the price on offer
  // am not sure if this works at all
  public shared({caller}) func change_price(request_id: T.RequestID, new_price: Float): async(Result.Result<(), Text>) {
    try {
      await check_if_user_made_request(caller, request_id);
      await check_request(request_id);

      let request: T.RideRequestType = extract_request(request_id);
      request.price := new_price;
      return #ok()
    } catch e {
      return #err(Error.message(e));
    }
  };

  public shared({caller}) func get_request_status(request_id: T.RequestID): async(Result.Result<T.RequestStatus, Text>) {
    try {
      await check_if_user_made_request(caller, request_id);
      await check_request(request_id);
      let request: T.RideRequestType = extract_request(request_id);
      return #ok(request.status);
    } catch e {
      return #err(Error.message(e));
    };
  };

  //////////////////////
  // Driver's Methods //
  //////////////////////

  // writing the function of the driver
  public shared({caller}) func query_passengers_available(query_passengers: T.QueryPassengers): async(Result.Result<[T.FullRequestInfo], Text>) {
    try {
      await validate_driver(caller);
      let requests_array: [T.RideRequestType] = List.toArray(pool_requests);
      // filter the array based on driver's location
      let local_requests: [T.RideRequestType] = filter_request(requests_array, query_passengers);
      return #ok(await passenger_details(local_requests));
    } catch e {
      return #err(Error.message(e));
    }
  };

  // First the driver have to create an account as a normal user
  // get the driver basic infor from his user account
  // add some additonal about the driver like his car information
  // driver has to upload the images of his cars.
  public shared({caller}) func register_car(car: T.Car): async(Result.Result<(), Text>) {
    try {
      // check if the driver has already created an account
      await check_user(caller);
      await driver_already_exists(caller);
      // If the caller is not registered to the application he is not supposed to create an account
      let user: T.User = get_user_account(caller);
      // create an account if the account does not exist
      let new_driver: T.Driver = create_driver_object(user, car);
      // register the created account 
      drivers_map.put(caller, new_driver);
      return #ok()
    } catch e {
      return #err(Error.message(e))
    }
    
  };

  // logic after the driver has selected a passenger for the trip
  // this is the stage where we create a ride info object and add it to the list.
  public shared({caller}) func select_passenger(request_id: T.RequestID, date_of_ride: Nat): async(Result.Result<(), Text>) {
    try {
      // get the request if it exist
      await check_request(request_id);
      let request: T.RideRequestType = extract_request(request_id);
      // update the request status to be accepted
      request.status := #Accepted;
      // approve the ride if the driver has selected the user
      await approve_ride(caller, request, date_of_ride);
      return #ok();
    } catch e {
      return #err(Error.message(e));
    }
  };

  public shared({caller}) func finished_ride(ride_id: T.RideID): async(Result.Result<(), Text>) {
    try {
      await check_ride_info(ride_id);
      let ride: T.RideInformation = get_ride(ride_id);
      await check_principals(ride.user_id, caller);
      update_ride_status(ride);
      return #ok();
    } catch e {
      return #err(Error.message(e));
    }
  };

  public func get_users_number(): async(Nat) {
    return users_map.size();
  };

  public func get_drivers_number(): async(Nat) {
    return drivers_map.size();
  };

  // record the lat and lng of the ride process
};
