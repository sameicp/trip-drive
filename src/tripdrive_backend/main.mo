import Types "/types";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
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

  // a record of the rides on the platform.
  stable var ride_information_storage = List.nil<Types.RideInformation>();


  // List for a list of requests
  stable var pool_requests = List.nil<Types.RideRequestType>();

  stable var request_id_counter = 0;
  stable var ride_id_counter = 0;

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

  func get_user_account(user_id: Principal): Types.User {
    if(not check_user_account(user_id)) {
      Debug.trap("Please start by creating an account as a user")
    };

    let option_user: ?Types.User = users_map.get(user_id);
    let user: Types.User = Option.get(option_user, default_user);
    return user;
  };

  public shared({caller}) func create_user_acc(
    username: Text, 
    email: Text, 
    phone_number: Text, 
    poster: Blob
  ): async (Text) {
  
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
    let user: Types.User = get_user_account(caller);

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

  func new_ride_id() : Types.RideID {
    let id = ride_id_counter;
    ride_id_counter += 1;
    return id;
  };

  public shared({caller}) func create_request(
    from: Types.CurrentSupportedLocation, 
    to: Types.CurrentSupportedLocation, 
    price: Float
  ): async(Types.RequestID) {
    if(not check_user_account(caller)) {
      Debug.trap("Please start by creating an account as a user")
    };

    // generation the id of the request
    let request_id: Types.RequestID = new_request_id();

    let status: Types.RequestStatus = #Pending;

    // creating users request and add it to a list of requests
    let request: Types.RideRequestType = {
      request_id;
      user_id = caller;
      from;
      to;
      var status;
      var price;
    };

    // adding the request into a pool of request
    pool_requests := List.push(request, pool_requests);
    return request_id;

  };

  /// Define an internal helper function to retrieve auctions by ID:
  func find_request(request_id : Types.RequestID) : Types.RideRequestType {
    let result = 
      List.find<Types.RideRequestType>(pool_requests, func request = request.request_id == request_id);
    switch (result) {
      case null Debug.trap("Inexistent id");
      case (?request) return request;
    };
  };

  func check_if_user_made_request(user_id: Principal, request_id: Types.RequestID) {
    // check if the user is the one who made the request
    let request = find_request(request_id);

    if (Principal.notEqual(user_id, request.user_id)) {
      Debug.trap("You are not the one who made the request");
    };

  };

  // the users can have the option to cancel the request
  public shared({caller}) func cancel_request(id: Types.RequestID): async(Text) {
    // check if the user is the one who made the request
    check_if_user_made_request(caller, id);

    pool_requests := 
      List.filter<Types.RideRequestType>(pool_requests, func request = request.request_id != id);
    return "request removed";
  };

  // change the price on offer
  // am not sure if this works at all
  // 
  public shared({caller}) func change_price(
    id: Types.RequestID, 
    new_price: Float
  ): async() {
    check_if_user_made_request(caller, id);

    let request: Types.RideRequestType = find_request(id);
    request.price := new_price;

  };

  // writing the function of the driver
  public shared({caller}) func query_passengers_available(
      from: Types.CurrentSupportedLocation, 
      to: Types.CurrentSupportedLocation
    ): async([Types.FullRequestInfo]) {
    // check if the caller is the driver
    let option_driver: ?Types.Driver = drivers_map.get(caller);
    let driver: Types.Driver = switch (option_driver) {
      case null Debug.trap("You are not a registered driver");
      case (?driver) driver;
    };

    // select passengers to carry based on the location of the driver
    // first change the List to an Array
    let requests_array: [Types.RideRequestType] = List.toArray(pool_requests);

    // filter the array based on driver's location
    let local_requests: [Types.RideRequestType] = 
      Array.filter<Types.RideRequestType>(
        requests_array, 
        func request = request.from == from and request.to == to
      );

    return passenger_details(local_requests);
  };

  // get useful user information
  func user_info(user_id: Principal): Types.Profile {
    // get user information
    let option_user: ?Types.User = users_map.get(user_id);
    let user: Types.User = switch (option_user) {
      case null Debug.trap("User this ID " # Principal.toText(user_id) # " does not exist.");
      case (?user) user;
    };

    let user_profile: Types.Profile = {
      username = user.username;
      email = user.email;
      phone_number = user.phone_number;
      poster = user.poster;
    };
    return user_profile;
  };

  // this function has to take in a list of requests and return passenger info nad the request id
  func passenger_details(requests_list: [Types.RideRequestType]): [Types.FullRequestInfo] {
    let output: Buffer.Buffer<Types.FullRequestInfo> = 
      Buffer.Buffer<Types.FullRequestInfo>(10);

    for(request in requests_list.vals()) {
      let profile: Types.Profile = user_info(request.user_id);
      let updated_info: Types.FullRequestInfo = {
        profile;
        request_id = request.request_id;
        price = request.price;
      };
      output.add(updated_info);
    };
    return Buffer.toArray<Types.FullRequestInfo>(output);
  };

  // logic after the driver has selected a passenger for the trip
  // this is the stage where we create a ride info object and add it to the list.
  public shared({caller}) func selected_user(request_id: Types.RequestID, date_of_ride: Nat): async() {
    // get the request if it exist
    let request: Types.RideRequestType = find_request(request_id);

    // update the request status to be accepted
    request.status := #Accepted;

    // approve the ride if the driver has selected the user
    approve_ride(caller, request, date_of_ride);
  };

  // after the driver has selected a user they must communicate how they are going to meet and at what time
  // the information must reflect on the users side.
  // they can use whatsapp to communicate
  // they can use email to communicate
  // they can communicate on the IC. but how?f

  func approve_ride(id: Principal, request: Types.RideRequestType, date_of_ride: Nat): () {
    let ride_id = create_ride_object(request, date_of_ride, id);
    add_ride_id_to_passenger(request.user_id, ride_id);
    add_ride_to_driver(id, ride_id);
  };

  func create_ride_object(
    request: Types.RideRequestType, 
    date_of_ride: Nat, 
    driver_id: Principal
  ): Types.RideID {
    
    let ride_info: Types.RideInformation = {
      ride_id = new_ride_id();
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
  func add_ride_id_to_passenger(user_id: Principal, ride_id: Types.RideID) {
    // first we check if the account exists
    let user: Types.User = get_user_account(user_id);
    user.ride_history := List.push(ride_id, user.ride_history);
  };

  // add the ride information to the driver's history to keep statistics
  func add_ride_to_driver(driver_id: Principal, ride_id: Types.RideID) {
    let option_driver: ?Types.Driver = drivers_map.get(driver_id);
    
    let driver: Types.Driver = switch (option_driver) {
      case null Debug.trap("User this ID " # Principal.toText(driver_id) # " does not exist.");
      case (?driver) driver;
    };

    driver.user.ride_history := List.push(ride_id, driver.user.ride_history);

  };

  func get_ride_object(ride_id: Types.RideID): Types.RideInformation {
    let result = List.find<Types.RideInformation>(
      ride_information_storage, 
      func ride = ride.ride_id ==ride_id
    );
    switch (result) {
      case null Debug.trap("Inexistent id");
      case (?ride) return ride;
    };
  };

  public shared({caller}) func update_finished_ride(ride_id: Types.RideID) {
    let ride: Types.RideInformation = get_ride_object(ride_id);

    if(Principal.notEqual(ride.user_id, caller)) {
      Debug.trap("not authorized to execute this function");
    };
    ride.ride_status := #RideCompleted;
    ride.payment_status := #Paid;
  }

};
