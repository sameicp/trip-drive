import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import List "mo:base/List";


module {

    public type RideID = Nat;
    public type RequestID = Nat;

    public type UserType = {
        #Driver;
        #Passenger;
    };

    public type RideStatus = {
        #RideRequested;
        #RideAccepted;
        #RideCompleted;
        #RideCancelled;
    };

    public type BookStatus = {
        #BookingAccepted;
        #BookingPending;
        #BookingDenied;
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
        model: Text;
        image: Blob;
    };

    public type RideInformation = {
        ride_id: RideID;
        origin: CurrentSupportedLocation;
        destination: CurrentSupportedLocation;
        var passenger_count: Nat;
        var price: Float;
        var ride_status: RideStatus;
        date: Text;
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

    public type BookInformation = {
        booking_id: Nat;
        passenger_id: Principal;
        driver_id: Principal;
        ride_id: Nat;
        var book_status: BookStatus;
    };

    public type RideRequestType = {
        request_id: RequestID;
        user_id: Principal;
        from: CurrentSupportedLocation;
        to: CurrentSupportedLocation;
        var price: Float;
    }

}