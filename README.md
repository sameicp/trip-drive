# Tripdrive

- creating a decentralised ride sharing platform hosted on the internet computer.

### Tests

- created a tests folder to test function but currently it is not working

### Terminal commands

Creating a USER in the terminal

```bash
dfx canister call tripdrive_backend create_user_acc 'record{username="samuel"; email="same@gmail.com"; phone_number="0771212234"; poster=vec {1; 2; 3}}'
```

Creating a REQUEST in the terminal

```bash
dfx canister call tripdrive_backend create_request 'record{from = variant{UniversityCampus = null}; to = variant {HarareCityCentre = null}; price = 1.00}'
```

Changing PRICE for the ride

```bash
dfx canister call tripdrive_backend change_price '(record{request_id = 0 }, 1.50)'
```

Cancelling a REQUEST

```bash
dfx canister call tripdrive_backend cancel_request '(record {request_id = 0})'
```

Register a Vehicle

```bash
dfx canister call tripdrive_backend register_car '(record {name = "Toyota"; license_plate_number = "AAA:1232"; color = "Blue"; car_model = "Runnx"; image = vec{2; 6; 12; 32; 22}})'
```

Creating a Driver

```bash
dfx identity new driver
dfx identity use driver
dfx canister call tripdrive_backend create_user_acc 'record{username="Salim"; email="salim@gmail.com"; phone_number="0771212234"; poster=vec {121; 122; 39}}'
dfx canister call tripdrive_backend register_car '(record {name = "Toyota"; license_plate_number = "AAA:1232"; color = "Blue"; car_model = "Runnx"; image = vec{2; 6; 12; 32; 22}})'
```

Check for people for a Ride

```bash
dfx canister call tripdrive_backend query_passengers_available 'record {from = variant{UniversityCampus = null}; to = variant {HarareCityCentre = null}}'
```

Select passengers

```bash
dfx canister call tripdrive_backend select_passenger '(record {request_id=0}, 1234245566)
```

Passenger check the status of the request

```bash
dfx canister call tripdrive_backend get_request_status '(record {request_id = 0})'
```
