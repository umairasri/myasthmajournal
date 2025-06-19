import 'package:asthma_app/common/widgets/asthma_diary/symptom_trend_chart.dart';
import 'package:asthma_app/common/widgets/asthma_diary/today_medication_usage.dart';
import 'package:asthma_app/common/widgets/asthma_diary/today_symptom_card.dart';
import 'package:asthma_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:asthma_app/common/widgets/texts/section_heading.dart';
import 'package:asthma_app/features/asthma/controllers/medication_controller.dart';
import 'package:asthma_app/features/asthma/controllers/symptom_controller.dart';
import 'package:asthma_app/features/asthma/controllers/selected_date_controller.dart';
import 'package:asthma_app/features/asthma/screens/home/widgets/homepage_appbar.dart';
import 'package:asthma_app/features/asthma/screens/home/widgets/calendar_widget.dart';
import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:asthma_app/features/personalization/controllers/patient_controller.dart';
import 'package:asthma_app/features/personalization/controllers/selected_dependent_controller.dart';
import 'package:asthma_app/features/personalization/controllers/dependent_controller.dart';
import 'package:asthma_app/features/personalization/models/dependent_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  late final PatientController userController;
  late final SelectedDependentController selectedDependentController;
  late final DependentController dependentController;
  late final SelectedDateController selectedDateController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    userController = Get.find<PatientController>();
    selectedDependentController = Get.find<SelectedDependentController>();
    dependentController = Get.put(DependentController());
    selectedDateController = Get.put(SelectedDateController());

    // Initialize data
    _initializeData();

    // Listen for changes in user data
    ever(userController.user, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is signed in, refresh data
        _initializeData();
      }
    });
  }

  @override
  void dispose() {
    // Reset the selected date when leaving the page
    selectedDateController.resetToToday();
    super.dispose();
  }

  void _initializeData() async {
    try {
      // Wait for SelectedDependentController to be fully initialized
      await selectedDependentController.waitForInitialization();

      // Fetch user data
      await userController.fetchUserRecord();

      // Check if there's a last selected dependent
      final lastSelectedType =
          selectedDependentController.getLastSelectedType();
      final lastSelectedId = selectedDependentController.getLastSelectedId();

      if (lastSelectedType == 'dependent' &&
          lastSelectedId?.isNotEmpty == true) {
        // Try to restore the last selected dependent
        await dependentController.fetchUserDependents();
        final dependent = dependentController.dependents.firstWhere(
          (d) => d.id == lastSelectedId,
          orElse: () => DependentModel(
            id: '',
            userId: '',
            name: '',
            gender: '',
            dateOfBirth: '',
            profilePicture: '',
            relation: '',
            evohaler: '',
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          ),
        );
        if (dependent.id?.isNotEmpty == true) {
          selectedDependentController.selectDependent(dependent);
        } else {
          selectedDependentController.selectUser();
        }
      } else if (!selectedDependentController.isSelectionValid()) {
        // If no valid selection exists, default to user
        selectedDependentController.selectUser();
      }

      // Fetch symptoms and medications
      await SymptomController.instance.fetchSymptoms();
      await MedicationController.instance.fetchMedications();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header
            TPrimaryHeaderContainer(
              child: Column(
                children: [
                  SizedBox(height: TSizes.spaceBtwItems),

                  /// -- Appbar
                  THomePageAppBar(),
                  SizedBox(height: TSizes.spaceBtwInputFields),

                  /// -- Categories
                  Padding(
                    padding:
                        const EdgeInsets.only(left: TSizes.defaultSpace - 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// -- Styled Date Heading
                        Obx(() {
                          final selectedDate =
                              selectedDateController.selectedDate;
                          final isToday = selectedDateController.isToday();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, MMMM yyyy')
                                      .format(selectedDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(1, 2),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                ),
                                if (!isToday) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Viewing ${DateFormat('d').format(selectedDate)}${_getDaySuffix(selectedDate.day)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: TSizes.spaceBtwItems - 5),

                        /// Categories
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: TCalendarWidget(),
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections + 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Body
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  /// -- Symptom Daily Trend Chart
                  TSectionHeading(
                    title: 'Daily Symptom Trend :',
                    showActionButton: false,
                    fontSize: 13,
                  ),
                  SizedBox(height: TSizes.sm),

                  SymptomTrendChart(disableIcon: true),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- Medications usages
                  Column(
                    children: [
                      TSectionHeading(
                        title: 'Medications usages :',
                        showActionButton: false,
                        fontSize: 13,
                      ),
                      SizedBox(height: TSizes.sm),
                      TodayMedicationUsage(),
                    ],
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- Symptom Tracker
                  Column(
                    children: [
                      TSectionHeading(
                        title: 'Symptom tracker :',
                        showActionButton: false,
                        fontSize: 13,
                      ),
                      SizedBox(height: TSizes.sm),
                      TodaySymptomCard(),
                      SizedBox(height: 100),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
