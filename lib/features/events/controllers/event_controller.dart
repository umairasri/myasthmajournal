import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:asthma_app/utils/popups/full_screen_loader.dart';
import 'package:asthma_app/utils/popups/loaders.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:asthma_app/utils/helpers/network_manager.dart';
import 'package:asthma_app/utils/logger.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';
import 'package:flutter/material.dart';
import 'package:asthma_app/features/notification/noti_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:asthma_app/features/personalization/controllers/dependent_controller.dart';
import 'package:asthma_app/features/participants/controllers/participant_controller.dart';
import 'package:asthma_app/features/participants/models/participant_model.dart';

class EventController extends GetxController {
  final EventRepository _eventRepository = EventRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<EventModel> events = <EventModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<XFile?> eventImage = Rx<XFile?>(null);
  final RxString selectedFilter = 'All'.obs;

  // Form controllers
  final eventName = TextEditingController();
  final time = TextEditingController();
  final date = TextEditingController();
  final location = TextEditingController();
  final details = TextEditingController();
  final numberOfParticipant = TextEditingController();
  GlobalKey<FormState> eventFormKey = GlobalKey<FormState>();

  // Controllers
  late final DependentController _dependentController;
  late final ParticipantController _participantController;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    try {
      TLogger.info("Initializing controllers...");

      // Initialize DependentController if not already initialized
      if (!Get.isRegistered<DependentController>()) {
        TLogger.info("Initializing DependentController...");
        _dependentController = Get.put(DependentController());
      } else {
        TLogger.info(
            "DependentController already initialized, getting instance...");
        _dependentController = Get.find<DependentController>();
      }

      // Initialize ParticipantController if not already initialized
      if (!Get.isRegistered<ParticipantController>()) {
        TLogger.info("Initializing ParticipantController...");
        _participantController = Get.put(ParticipantController());
      } else {
        TLogger.info(
            "ParticipantController already initialized, getting instance...");
        _participantController = Get.find<ParticipantController>();
      }

      TLogger.info("All controllers initialized successfully");
      await fetchTomorrowEventsAndNotify();
    } catch (e) {
      TLogger.error("Error initializing controllers: $e");
    }
  }

  @override
  void onClose() {
    eventName.dispose();
    time.dispose();
    date.dispose();
    location.dispose();
    details.dispose();
    numberOfParticipant.dispose();
    super.onClose();
  }

  // Helper method to create a DocumentReference from healthcareId
  DocumentReference _getHealthcareRef(String healthcareId) {
    return _firestore.collection('Healthcare').doc(healthcareId);
  }

  Future<bool> _validateHealthcare(String healthcareId) async {
    try {
      TLogger.info('Validating healthcare ID: $healthcareId');

      // First check if the ID is not empty
      if (healthcareId.isEmpty) {
        TLoaders.errorSnackBar(
            title: 'Error', message: 'Healthcare ID is empty');
        return false;
      }

      // Check if the document exists
      final healthcareDoc =
          await _firestore.collection('Healthcare').doc(healthcareId).get();

      if (!healthcareDoc.exists) {
        TLogger.error('Healthcare provider not found with ID: $healthcareId');
        TLoaders.errorSnackBar(
            title: 'Error',
            message:
                'Healthcare provider not found. Please check your healthcare ID.');
        return false;
      }

      // Log the healthcare data for debugging
      TLogger.info('Healthcare document found: ${healthcareDoc.data()}');
      return true;
    } catch (e) {
      TLogger.error('Failed to validate healthcare provider: $e');
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to validate healthcare provider: $e');
      return false;
    }
  }

  Future<void> createEvent({
    required String healthcareId,
  }) async {
    try {
      TLogger.info('Creating event for healthcare ID: $healthcareId');

      // Start Loading
      TFullScreenLoader.openLoadingDialog(
          'Creating event...', TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validate healthcare exists
      final isValidHealthcare = await _validateHealthcare(healthcareId);
      if (!isValidHealthcare) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!eventFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Create new event
      final newEvent = EventModel(
        eventId: _firestore.collection('Events').doc().id,
        healthcareId: healthcareId,
        eventName: eventName.text.trim(),
        time: time.text.trim(),
        date: date.text.trim(),
        location: location.text.trim(),
        details: details.text.trim(),
        numberOfParticipant: int.tryParse(numberOfParticipant.text.trim()) ?? 0,
        image: eventImage.value?.path,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Save to Firestore
      await _eventRepository.createEvent(newEvent);

      // Update UI
      events.add(newEvent);

      // Clear form
      clearForm();

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(
          title: 'Success', message: 'Event created successfully');

      // Navigate back
      Get.back();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLogger.error('Failed to create event: $e');
      TLoaders.errorSnackBar(
          title: 'Error', message: 'Failed to create event. Please try again.');
    }
  }

  /// Clear form
  void clearForm() {
    eventName.clear();
    time.clear();
    date.clear();
    location.clear();
    details.clear();
    numberOfParticipant.clear();
    eventImage.value = null;
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        eventImage.value = image;
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Oh Snap!', message: 'Failed to pick image: $e');
    }
  }

  Future<void> getEventsByHealthcareId(String healthcareId) async {
    try {
      isLoading.value = true;
      final eventList =
          await _eventRepository.getEventsByHealthcareId(healthcareId);
      events.assignAll(eventList);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch events: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<EventModel?> getEventById(String eventId) async {
    try {
      isLoading.value = true;
      return await _eventRepository.getEventById(eventId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch event: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      isLoading.value = true;
      await _eventRepository.updateEvent(event);
      await getEventsByHealthcareId(event.healthcareId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update event: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEvent(String eventId, String healthcareId) async {
    try {
      isLoading.value = true;
      await _eventRepository.deleteEvent(eventId);
      await getEventsByHealthcareId(healthcareId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete event: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateParticipantCount(String eventId, int newCount) async {
    try {
      isLoading.value = true;
      await _eventRepository.updateParticipantCount(eventId, newCount);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update participant count: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAllEvents() async {
    try {
      isLoading.value = true;
      final eventList = await _eventRepository.getAllEvents();
      events.assignAll(eventList);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch events: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<EventModel> getPastEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return events.where((event) {
      try {
        final parts = event.date.split('/');
        if (parts.length != 3) return false;

        final eventDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        final eventDay =
            DateTime(eventDate.year, eventDate.month, eventDate.day);

        return eventDay.isBefore(today);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<EventModel> getUpcomingEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return events.where((event) {
      try {
        final parts = event.date.split('/');
        if (parts.length != 3) return false;

        final eventDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        final eventDay =
            DateTime(eventDate.year, eventDate.month, eventDate.day);

        return !eventDay.isBefore(today);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> fetchTomorrowEventsAndNotify() async {
    try {
      TLogger.info("=== Starting Event Notification Check ===");

      // 1. Check Notification Service
      final notiService = NotiService();
      TLogger.info("Checking notification service initialization...");
      if (!notiService.isInitialized) {
        TLogger.info("Initializing notification service...");
        await notiService.initNotification();
      }

      // Check notification permission
      final hasPermission = await notiService.isNotificationPermissionGranted();
      TLogger.info("Notification permission status: $hasPermission");
      if (!hasPermission) {
        TLogger.warning(
            "Notification permission not granted. Requesting permission...");
        final granted = await notiService.requestNotificationPermission();
        if (!granted) {
          TLogger.error("Notification permission denied by user");
          return;
        }
      }

      // 2. Get current user and their dependents' IDs
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        TLogger.error(
            "User not logged in, skipping tomorrow event notification.");
        return;
      }
      TLogger.info("Current user ID: $currentUserId");

      TLogger.info("Fetching user dependents...");
      await _dependentController.fetchUserDependents();
      final List<String> dependentIds =
          _dependentController.dependents.map((d) => d.id).toList();
      TLogger.info("Found ${dependentIds.length} dependents: $dependentIds");

      // Create a map of dependent IDs to their names for better notification messages
      final Map<String, String> dependentNames = {
        for (var d in _dependentController.dependents) d.id: d.name
      };

      final List<String> personsOfInterestIds = [
        currentUserId,
        ...dependentIds
      ];
      TLogger.info(
          "Persons of interest for event notification: $personsOfInterestIds");

      // 3. Ensure events are loaded
      if (events.isEmpty) {
        TLogger.info("Events list is empty, fetching all events...");
        await getAllEvents();
      }
      TLogger.info("Total events loaded: ${events.length}");

      // 4. Filter events for tomorrow
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      TLogger.info("Checking for events on: ${tomorrow.toString()}");

      final allTomorrowEvents = events.where((event) {
        try {
          final parts = event.date.split('/');
          if (parts.length != 3) {
            TLogger.warning("Invalid date format for event: ${event.date}");
            return false;
          }
          final eventDate = DateTime(
            int.parse(parts[2]), // Year
            int.parse(parts[1]), // Month
            int.parse(parts[0]), // Day
          );
          final isTomorrow = eventDate.year == tomorrow.year &&
              eventDate.month == tomorrow.month &&
              eventDate.day == tomorrow.day;

          if (isTomorrow) {
            TLogger.info(
                "Found event for tomorrow: ${event.eventName} on ${event.date}");
          }
          return isTomorrow;
        } catch (e) {
          TLogger.error(
              "Error parsing event date for notification: ${event.date}", e);
          return false;
        }
      }).toList();

      if (allTomorrowEvents.isEmpty) {
        TLogger.info("No events scheduled for tomorrow in the general list.");
        return;
      }
      TLogger.info(
          "Found ${allTomorrowEvents.length} total events for tomorrow: ${allTomorrowEvents.map((e) => e.eventName).join(', ')}");

      // 5. Filter these events by participation of user or dependents
      final List<Map<String, dynamic>> relevantTomorrowEvents = [];

      for (final event in allTomorrowEvents) {
        try {
          TLogger.info(
              "=== Checking participation for event: ${event.eventName} (ID: ${event.eventId}) ===");

          // Get all participants for this event
          final List<Participant> eventParticipants =
              await _participantController
                  .getParticipantsByEvent(event.eventId);
          TLogger.info(
              "Event ${event.eventName} has ${eventParticipants.length} participants");

          if (eventParticipants.isEmpty) {
            TLogger.info("No participants found for event ${event.eventName}");
            continue;
          }

          // Check if any of the persons of interest (user or dependents) are participants
          List<String> participatingNames = [];
          bool isRelevant = false;

          for (final participant in eventParticipants) {
            TLogger.info(
                "Checking participant - ID: ${participant.participantId}, Dependent ID: ${participant.dependentId}");

            if (participant.dependentId == currentUserId) {
              isRelevant = true;
              participatingNames.add("You");
              TLogger.info(
                  "Found matching participant for event ${event.eventName}: Current User");
            } else if (dependentIds.contains(participant.dependentId)) {
              isRelevant = true;
              final dependentName = dependentNames[participant.dependentId] ??
                  "Unknown Dependent";
              participatingNames.add(dependentName);
              TLogger.info(
                  "Found matching participant for event ${event.eventName}: $dependentName");
            }
          }

          if (isRelevant) {
            relevantTomorrowEvents.add({
              'event': event,
              'participants': participatingNames,
            });
            TLogger.info(
                "Event ${event.eventName} IS RELEVANT for the user/dependents.");
          } else {
            TLogger.info(
                "Event ${event.eventName} is NOT relevant for the user/dependents.");
          }
        } catch (e) {
          TLogger.error(
              "Error checking participation for event ${event.eventId}: $e");
        }
      }

      // 6. Show notification if there are relevant events
      if (relevantTomorrowEvents.isNotEmpty) {
        TLogger.info(
            "=== Found ${relevantTomorrowEvents.length} RELEVANT events for tomorrow notification ===");

        // Create detailed notification message
        final List<String> eventDetails =
            relevantTomorrowEvents.map((eventData) {
          final event = eventData['event'] as EventModel;
          final participants = eventData['participants'] as List<String>;
          return "${event.eventName} (${participants.join(', ')})";
        }).toList();

        final String eventNames = eventDetails.join('\n');
        try {
          await notiService.showEventTomorrowNotification(
              eventNames: eventNames,
              eventCount: relevantTomorrowEvents.length);
          TLogger.info("Notification sent successfully for tomorrow's events");
        } catch (e) {
          TLogger.error("Failed to send notification: $e");
        }
      } else {
        TLogger.info(
            "No relevant events for tomorrow for the current user or their dependents after checking participation.");
      }
    } catch (e) {
      TLogger.error("Error in fetchTomorrowEventsAndNotify: $e");
    } finally {
      TLogger.info("=== Event Notification Check Complete ===");
    }
  }
}
