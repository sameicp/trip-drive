import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Nat "mo:base/Nat";


module {

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
    };

    public type RideInformation = {
        ride_id: Nat;
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
        poster: Text;
        phone_number: Text;
    };

    public type Driver = {
        user: User;
        car: Car;
        license_plate_number: Text;
    };

    public type BookInformation = {
        booking_id: Nat;
        passenger_id: Principal;
        driver_id: Principal;
        ride_id: Nat;
        var book_status: BookStatus;
    }

}