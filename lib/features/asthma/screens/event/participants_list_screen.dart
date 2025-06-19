import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:asthma_app/common/widgets/appbar/appbar.dart';
import 'package:asthma_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:asthma_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:asthma_app/features/participants/controllers/participant_controller.dart';
import 'package:asthma_app/features/events/controllers/event_controller.dart';
import 'package:asthma_app/features/personalization/controllers/dependent_controller.dart';
import 'package:asthma_app/features/personalization/controllers/patient_controller.dart';
import 'package:asthma_app/utils/popups/loaders.dart';
import 'package:asthma_app/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantsListScreen extends StatefulWidget {
  final String eventId;
  final String healthcareId;

  const ParticipantsListScreen({
    super.key,
    required this.eventId,
    required this.healthcareId,
  });

  @override
  State<ParticipantsListScreen> createState() => _ParticipantsListScreenState();
}

class _ParticipantsListScreenState extends State<ParticipantsListScreen> {
  final participantController = Get.put(ParticipantController());
  final eventController = Get.find<EventController>();
  final dependentController = Get.find<DependentController>();
  final patientController = Get.find<PatientController>();
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch participants for this event
      await participantController.getParticipantsByEvent(widget.eventId);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load participants: $e',
      );
    }
  }

  Future<Map<String, dynamic>?> _getParticipantDetails(
      String participantId) async {
    try {
      // First check in Dependents collection
      final dependentDoc =
          await _firestore.collection('Dependents').doc(participantId).get();
      if (dependentDoc.exists) {
        final data = dependentDoc.data()!;
        final dateOfBirth = data['dateOfBirth'] as String? ?? '';
        final age = _calculateAge(dateOfBirth);
        return {
          'name': data['name'] ?? 'Unknown',
          'profilePicture': data['ProfilePicture'] ?? '',
          'age': age,
        };
      }

      // If not found in Dependents, check in Patients collection
      final patientDoc =
          await _firestore.collection('Patients').doc(participantId).get();
      if (patientDoc.exists) {
        final data = patientDoc.data()!;
        // Get date of birth from the correct field name in Patient collection
        final dateOfBirth = data['DateOfBirth'] as String? ?? '';
        final age = _calculateAge(dateOfBirth);
        return {
          'name': '${data['FirstName'] ?? ''} ${data['LastName'] ?? ''}'.trim(),
          'profilePicture': data['ProfilePicture'] ?? '',
          'age': age,
        };
      }

      return null;
    } catch (e) {
      TLogger.error('Error fetching participant details', e);
      return null;
    }
  }

  String _calculateAge(String dateOfBirth) {
    if (dateOfBirth.isEmpty) return 'Unknown';

    try {
      // Print the date string for debugging
      print('Date of birth string: $dateOfBirth');

      // Try to parse the date
      DateTime dob;

      // Check if the date is in a different format
      if (dateOfBirth.contains('/')) {
        // Handle MM/DD/YYYY format
        final parts = dateOfBirth.split('/');
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          dob = DateTime(year, month, day);
        } else {
          throw FormatException('Invalid date format');
        }
      } else if (dateOfBirth.contains('-')) {
        // Handle YYYY-MM-DD format
        dob = DateTime.parse(dateOfBirth);
      } else {
        // Try to parse as is
        dob = DateTime.parse(dateOfBirth);
      }

      final today = DateTime.now();
      int age = today.year - dob.year;
      final monthDiff = today.month - dob.month;

      if (monthDiff < 0 || (monthDiff == 0 && today.day < dob.day)) {
        age--;
      }

      return '$age years old';
    } catch (e) {
      print('Error calculating age: $e');
      return 'Unknown';
    }
  }

  Widget _buildParticipantInfo(String participantId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getParticipantDetails(participantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Text(
            'Unknown Participant',
            style: Theme.of(context).textTheme.titleMedium,
          );
        }

        final data = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              data['age'],
              style: Theme.of(context).textTheme.bodySmall?.apply(
                    color: TColors.darkerGrey,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _getParticipantInitial(String participantId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getParticipantDetails(participantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('?');
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('?');
        }

        final data = snapshot.data!;
        final name = data['name'] as String;
        return Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.apply(color: TColors.primary),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header
            TPrimaryHeaderContainer(
              child: Column(
                children: [
                  TAppBar(
                    title: Text(
                      'Event Participants',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .apply(color: TColors.white),
                    ),
                    showBackArrow: true,
                    leadingIcon: Iconsax.arrow_left,
                    leadingOnPressed: () => Get.back(),
                    iconColor: TColors.white,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              ),
            ),

            /// -- Body
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Info Card
                  Obx(() {
                    final event = eventController.events
                        .firstWhereOrNull((e) => e.eventId == widget.eventId);
                    return TRoundedContainer(
                      padding: const EdgeInsets.all(TSizes.md),
                      backgroundColor: TColors.white,
                      showBorder: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event?.eventName ?? 'Loading...',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: TSizes.spaceBtwItems / 2),
                          Text(
                            '${event?.date ?? ''} at ${event?.time ?? ''}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // Participants List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participants List',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Obx(() {
                        final participants = participantController.participants
                            .where((p) => p.eventId == widget.eventId)
                            .toList();
                        return Text(
                          '${participants.length} participants',
                          style: Theme.of(context).textTheme.bodyMedium?.apply(
                                color: TColors.darkerGrey,
                              ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Obx(() {
                    if (participantController.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final participants = participantController.participants
                        .where((p) => p.eventId == widget.eventId)
                        .toList();

                    if (participants.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: TSizes.spaceBtwItems),
                            Text(
                              'No participants yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.apply(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: participants.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: TSizes.spaceBtwItems),
                      itemBuilder: (context, index) {
                        final participant = participants[index];

                        return FutureBuilder<Map<String, dynamic>?>(
                          future:
                              _getParticipantDetails(participant.dependentId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const TRoundedContainer(
                                padding: EdgeInsets.all(TSizes.md),
                                backgroundColor: TColors.white,
                                showBorder: true,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final data = snapshot.data;
                            if (data == null) {
                              return TRoundedContainer(
                                padding: const EdgeInsets.all(TSizes.md),
                                backgroundColor: TColors.white,
                                showBorder: true,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          TColors.primary.withOpacity(0.1),
                                      child: const Text('?'),
                                    ),
                                    const SizedBox(width: TSizes.spaceBtwItems),
                                    Expanded(
                                      child: Text(
                                        'Unknown Participant',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      'Joined\n${_formatDate(participant.dateJoin)}',
                                      textAlign: TextAlign.end,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return TRoundedContainer(
                              padding: const EdgeInsets.all(TSizes.md),
                              backgroundColor: TColors.white,
                              showBorder: true,
                              child: Row(
                                children: [
                                  // Profile Picture
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        TColors.primary.withOpacity(0.1),
                                    child: Text(
                                      data['name'].toString().isNotEmpty
                                          ? data['name'][0].toUpperCase()
                                          : '?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.apply(color: TColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: TSizes.spaceBtwItems),
                                  // Participant Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          data['age'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.apply(
                                                color: TColors.darkerGrey,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Join Date
                                  Text(
                                    'Joined\n${_formatDate(participant.dateJoin)}',
                                    textAlign: TextAlign.end,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
