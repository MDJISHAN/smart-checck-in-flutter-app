import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
   String currentAddress = ""; // <-- declare here

  late ApiService api;
  final _auth = AuthService();
  String? empId;
  String? name;
  String? token;
  bool loading = false;
StreamSubscription<Position>? positionStream;

@override
  void initState() {
    super.initState();
    api = ApiService('https://n8n-pe1m.onrender.com');// its hard codded keep in mind change if needed  this.baseUrl change in .env file

    // Fetch initial location
    _updateCurrentAddress();

    // Listen to live location updates
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      List<Placemark> placemarks = [];
      try {
        placemarks =
            await placemarkFromCoordinates(position.latitude, position.longitude);
      } catch (e) {
        print("Error in geocoding: $e");
      }

      setState(() {
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          currentAddress =
              "${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
        } else {
          currentAddress = "${position.latitude}, ${position.longitude}";
        }
      });
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  // Fetch current location once
  Future<String> _updateCurrentAddress() async {
    String address = "Unknown location";
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
            "${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
      } else {
        address = "${position.latitude}, ${position.longitude}";
      }
    } catch (e) {
      print("Error fetching location: $e");
    }

    setState(() {
      currentAddress = address;
    });

    return address;
  }




Future<void> _sendAttendance(String type) async {
  if (empId == null) return;

  setState(() => loading = true);

  try {
    final timestamp = DateTime.now().toIso8601String();
    final address = await _updateCurrentAddress();  // human readable location

    final res = await api.sendAttendance(
      empId: empId!,
      name: name!,
      type: type, // "check-in" or "check-out"
      timestamp: timestamp,
      location: address,
         // send address instead of lat/lng
    );

    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$type successful at $address")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${res['error'] ?? 'Unknown error'}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }

  setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome $name")),
      body: Center(
        child: loading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _sendAttendance("Check-In"),
                    child: Text("Check In"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _sendAttendance("Check-Out"),
                    child: Text("Check Out"),
                  ),
                ],
              ),
      ),
    );
  }
}
