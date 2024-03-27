import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import List "mo:base/List";


module {

    public type RideID = {
        ride_id: Nat;
    };

    public type RequestID = {
        request_id: Nat;
    };

    public type UserType = {
        #Driver;
        #Passenger;
    };

    public type PaymentStatus = {
        #Paid;
        #NotPaid;
    };

    public type RideStatus = {
        #RideAccepted;
        #RideCompleted;
        #RideCancelled;
    };

    public type RequestStatus = {
        #Accepted;
        #Pending;
        #Denied;
    };

    public type CurrentSupportedLocation = {
        #UniversityCampus;
        #HarareCityCentre;
    };

    public type Location = {
        lat: Float;
        lng: Float;
    };

    public type Car = {
        name: Text;
        license_plate_number: Text;
        color: Text;
        car_model: Text;
        image: Blob;
    };

    public type RideInformation = {
        ride_id: RideID;
        user_id: Principal;
        driver_id: Principal;
        origin: CurrentSupportedLocation;
        destination: CurrentSupportedLocation;
        var payment_status: PaymentStatus;
        var price: Float;
        var ride_status: RideStatus;
        date_of_ride: Nat;
    };

    public type Profile = {
        username: Text;
        email: Text;
        phone_number: Text;
        poster: Blob;
    };

    public type User = {
        id: Principal;
        username: Text;
        email: Text;
        phone_number: Text;
        poster: Blob;
        var ride_history: List.List<RideID>;
    };

    public type Driver = {
        user: User;
        car: Car;
    };

    public type RideRequestType = {
        request_id: RequestID;
        user_id: Principal;
        from: CurrentSupportedLocation;
        to: CurrentSupportedLocation;
        var status: RequestStatus;
        var price: Float;
    };

    public type FullRequestInfo = {
        profile: Profile;
        request_id: RequestID;
        price: Float;
    };

    // creating types for inputs

    public type UserInput = {
        username: Text; 
        email: Text;
        phone_number: Text; 
        poster: Blob;
    };

    public type RequestInput = {
        from: CurrentSupportedLocation;
        to: CurrentSupportedLocation;
        price: Float;
    };

    public type QueryPassengers = {
        from: CurrentSupportedLocation;
        to: CurrentSupportedLocation;
    };

}