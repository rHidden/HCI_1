import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  Position? position;
  String? errorMessage;
  bool isLoading = false;

  Future<void> getLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      position = await _determinePosition();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Determines the current position of the device, checking that
  /// location services are enabled and that permission has been granted.
  /// As recommended by the geolocator package docs.
  Future<Position> _determinePosition() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocationCard(
              position: appState.position,
              errorMessage: appState.errorMessage,
              isLoading: appState.isLoading,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                appState.getLocation();
              },
              child: Text('Get Location'),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.position,
    required this.errorMessage,
    required this.isLoading,
  });

  final Position? position;
  final String? errorMessage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    Widget content;
    if (isLoading) {
      content = CircularProgressIndicator(color: theme.colorScheme.onPrimary);
    } else if (errorMessage != null) {
      content = Text(
        errorMessage!,
        style: style,
        textAlign: TextAlign.center,
      );
    } else if (position == null) {
      content = Text(
        'Press the button to get your location.',
        style: style,
        textAlign: TextAlign.center,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latitude: ${position!.latitude.toStringAsFixed(6)}', style: style),
          Text('Longitude: ${position!.longitude.toStringAsFixed(6)}', style: style),
          Text('Accuracy: ${position!.accuracy.toStringAsFixed(1)} m', style: style),
        ],
      );
    }

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}
