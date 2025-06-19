import 'package:asthma_app/common/widgets/appbar/appbar.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class LocationConfirmationDialog extends StatefulWidget {
  const LocationConfirmationDialog({super.key});

  @override
  State<LocationConfirmationDialog> createState() =>
      _LocationConfirmationDialogState();
}

class _LocationConfirmationDialogState
    extends State<LocationConfirmationDialog> {
  bool _isLoading = false;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services in your device settings.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          Get.snackbar(
            'Location Permission Denied',
            'Please grant location permission to use this feature.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        Get.snackbar(
          'Location Permission Denied Permanently',
          'Location permission is permanently denied. Please enable it in app settings.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _launchMapsWithSearch() async {
    // This function will be called after confirmation and loading state is handled by the dialog
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        return; // Snackbars in _handleLocationPermission already informed the user
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Increased timeout slightly
      );

      final String searchTerm = "Hospitals & Clinics";
      final String searchQuery = "${searchTerm}";
      final Uri googleMapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchQuery)}');

      if (!await launchUrl(googleMapsUri,
          mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Could not open Google Maps.';
        if (e.toString().contains('TimeoutException')) {
          errorMessage =
              'Could not get your location. Please check GPS and try again.';
        }
        Get.dialog(
          AlertDialog(
            title: const Text('Error'),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Get.back(), // Dismiss error dialog
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Maps Confirmation'),
      content: _isLoading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching location and opening maps...'),
              ],
            )
          : const Text(
              'Do you want to open Google Maps to find nearby Hospitals & Clinics?'),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            if (!_isLoading) {
              Get.back(); // Dismiss confirmation dialog
            }
          },
        ),
        TextButton(
          child: const Text('Confirm'),
          onPressed: _isLoading
              ? null // Disable button while loading
              : () async {
                  setState(() {
                    _isLoading = true;
                  });

                  // Dismiss this confirmation dialog BEFORE attempting to launch maps or show another error dialog
                  Get.back();

                  await _launchMapsWithSearch();

                  // No need to set _isLoading = false here as the dialog is already dismissed.
                  // If _launchMapsWithSearch shows its own dialog, that's a separate flow.
                },
        ),
      ],
    );
  }
}
