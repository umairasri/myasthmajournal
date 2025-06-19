import 'package:asthma_app/features/personalization/screens/profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asthma_app/data/repositories/authentication/authentication_repository.dart';
import 'package:asthma_app/data/repositories/patient/patient_repository.dart';
import 'package:asthma_app/data/repositories/user/user_repository.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:asthma_app/utils/helpers/network_manager.dart';
import 'package:asthma_app/utils/popups/full_screen_loader.dart';
import 'package:asthma_app/utils/popups/loaders.dart';
import 'package:asthma_app/features/authentication/screens/login/login.dart';
import 'package:asthma_app/features/personalization/models/patient_model.dart';
import 'package:asthma_app/features/personalization/screens/profile/widgets/re_authenticate_user_login_form.dart';
import 'package:image_picker/image_picker.dart';
import 'package:asthma_app/features/personalization/models/user_model.dart';
import 'package:asthma_app/utils/logger.dart';

class PatientController extends GetxController {
  static PatientController get instance => Get.find();

  final profileLoading = false.obs;
  Rx<PatientModel> user = PatientModel.empty().obs;

  final hidePassword = true.obs;
  final imageUploading = false.obs;
  final verifyEmail = TextEditingController();
  final verifyPassword = TextEditingController();
  final patientRepository = Get.put(PatientRepository());
  final userController = Get.put(UserRepository());
  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();

  // Form Keys
  final updateDailyMedicationFormKey = GlobalKey<FormState>();

  // Text Controllers
  final dailyMedication = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Check if user is a healthcare provider or admin
        final healthcareDoc = await FirebaseFirestore.instance
            .collection('Healthcare')
            .doc(user.uid)
            .get();
        final adminDoc = await FirebaseFirestore.instance
            .collection('Admins')
            .doc(user.uid)
            .get();

        if (!healthcareDoc.exists && !adminDoc.exists) {
          // Only fetch user record if not a healthcare provider or admin
          fetchUserRecord();
        } else {
          // Clear user data for healthcare providers and admins
          clearUserData();
        }
      } else {
        // User is signed out
        clearUserData();
      }
    });
  }

  @override
  void onClose() {
    dailyMedication.dispose();
    super.onClose();
  }

  /// Clear user data
  void clearUserData() {
    user.value = PatientModel.empty();
  }

  /// Fetch user record
  Future<void> fetchUserRecord() async {
    try {
      profileLoading.value = true;
      final currentUser = AuthenticationRepository.instance.authUser;
      if (currentUser == null) {
        // Use Future.microtask to defer the state update
        Future.microtask(() => clearUserData());
        return;
      }

      // Check if user is a healthcare provider or admin
      final healthcareDoc = await FirebaseFirestore.instance
          .collection('Healthcare')
          .doc(currentUser.uid)
          .get();
      final adminDoc = await FirebaseFirestore.instance
          .collection('Admins')
          .doc(currentUser.uid)
          .get();

      if (healthcareDoc.exists || adminDoc.exists) {
        // Use Future.microtask to defer the state update
        Future.microtask(() => clearUserData());
        return;
      }

      // Clear existing data before fetching new data
      Future.microtask(() => clearUserData());

      final userData = await patientRepository.fetchUserDetails();
      if (userData.id == currentUser.uid) {
        // Use Future.microtask to defer the state update
        Future.microtask(() => this.user(userData));
      } else {
        // Use Future.microtask to defer the state update
        Future.microtask(() => clearUserData());
      }
    } catch (e) {
      // Use Future.microtask to defer the state update
      Future.microtask(() => clearUserData());
    } finally {
      // Use Future.microtask to defer the state update
      Future.microtask(() => profileLoading.value = false);
    }
  }

  /// Save user Record from any Registration provider
  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      if (userCredentials != null) {
        // First create User record
        final user = UserModel(
          userId: userCredentials.user!.uid,
          email: userCredentials.user!.email ?? '',
          role: UserRole.patient,
        );

        final userRepository = Get.put(UserRepository());
        await userRepository.createUser(user);

        // Check if patient record already exists
        final existingPatient = await patientRepository.fetchUserDetails();

        if (existingPatient.id.isEmpty) {
          // Only create new patient record if one doesn't exist
          final nameParts =
              PatientModel.nameParts(userCredentials.user!.displayName ?? '');
          final username = PatientModel.generateUsername(
              userCredentials.user!.displayName ?? '');

          final patient = PatientModel(
            id: userCredentials.user!.uid,
            userId: userCredentials.user!.uid,
            username: username,
            firstName: nameParts[0],
            lastName:
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            phoneNumber: userCredentials.user!.phoneNumber ?? '',
            profilePicture: userCredentials.user!.photoURL ?? '',
            gender: '',
            dateOfBirth: '',
            evohaler: '0',
          );

          await patientRepository.saveUserRecord(patient);
        }
      }
    } catch (e) {
      TLoaders.warningSnackBar(
          title: 'Data not saved',
          message:
              'Something went wrong while saving your information. You can re-save your data in your Profile.');
    }
  }

  /// Delete Account Warning
  void deleteAccountWarningPopup() {
    Get.defaultDialog(
      title: "Delete Account",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
      titlePadding: const EdgeInsets.only(top: TSizes.lg, bottom: TSizes.sm),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: TSizes.lg, vertical: TSizes.md),
      radius: 15.0,
      content: Column(
        mainAxisSize: MainAxisSize.min, // Ensures Column takes minimum space
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 48, color: Colors.orangeAccent),
          const SizedBox(height: TSizes.md),
          const Text(
            'Are you sure you want to delete your account permanently?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: TSizes.sm),
          const Text(
            'This action is not reversible and all of your data will be removed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: Colors.black54),
          ),
        ],
      ),
      confirm: Padding(
        padding: const EdgeInsets.only(
            left: TSizes.sm,
            right: TSizes.xs,
            bottom: TSizes.sm,
            top: TSizes.sm), // Fine-tune spacing for buttons
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(); // Close the dialog first
            deleteUserAccount();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(
                horizontal: TSizes.lg, vertical: TSizes.sm),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
          ),
          child: const Text('Delete'),
        ),
      ),
      cancel: Padding(
        padding: const EdgeInsets.only(
            left: TSizes.xs,
            right: TSizes.sm,
            bottom: TSizes.sm,
            top: TSizes.sm), // Fine-tune spacing for buttons
        child: OutlinedButton(
          onPressed: () => Navigator.of(Get.overlayContext!).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87, // Text color
            side: BorderSide(color: Colors.grey.shade400),
            padding: const EdgeInsets.symmetric(
                horizontal: TSizes.lg, vertical: TSizes.sm),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
          ),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  /// Delete User Account
  void deleteUserAccount() async {
    try {
      TFullScreenLoader.openLoadingDialog('Processing', TImages.docerAnimation);

      /// First re-authenticate user
      final auth = AuthenticationRepository.instance;
      final provider =
          auth.authUser!.providerData.map((e) => e.providerId).first;
      if (provider.isNotEmpty) {
        // Re Verify Auth Email
        if (provider == 'google.com') {
          final userId = auth.authUser!.uid; // Get userId
          await auth.signInWithGoogle(); // Re-authenticate
          await userController
              .deleteUser(userId); // Delete from Users collection FIRST
          await auth.deleteAccount(); // Then delete from Patients & Auth
          TFullScreenLoader.stopLoading();
          Get.offAll(() => const LoginScreen());
        } else if (provider == 'password') {
          TFullScreenLoader.stopLoading();
          Get.to(() => const ReAuthLoginForm());
        }
      }
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// -- RE-AUTHENTICATE before deleting
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      TFullScreenLoader.openLoadingDialog('Processing', TImages.docerAnimation);

      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!reAuthFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final userId =
          AuthenticationRepository.instance.authUser!.uid; // Get userId
      await AuthenticationRepository.instance
          .reAuthenticateWithEmailAndPassword(
              verifyEmail.text.trim(), verifyPassword.text.trim());

      await userController
          .deleteUser(userId); // Delete from Users collection FIRST
      await AuthenticationRepository.instance
          .deleteAccount(); // Then delete from Patients & Auth

      TFullScreenLoader.stopLoading();

      Get.offAll(() => const LoginScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Upload Profile Image
  uploadUserProfilePicture() async {
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxHeight: 512,
          maxWidth: 512);
      if (image != null) {
        imageUploading.value = true;
        // Upload Image
        final imageUrl =
            await patientRepository.uploadImage('Users/Images/Profile/', image);

        // Update User Image Record
        Map<String, dynamic> json = {'ProfilePicture': imageUrl};
        await patientRepository.updateSingleField(json);

        user.value.profilePicture = imageUrl;
        user.refresh();

        TLoaders.successSnackBar(
            title: 'Congratulations',
            message: 'Your Profile Image has been updated!');
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Oh Snap!', message: 'Something went wrong: $e');
    } finally {
      imageUploading.value = true;
    }
  }

  /// Update Daily Medication
  Future<void> updateDailyMedication() async {
    try {
      if (!updateDailyMedicationFormKey.currentState!.validate()) return;

      TFullScreenLoader.openLoadingDialog(
          'Updating daily medication...', TImages.docerAnimation);

      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Update patient record
      final updatedPatient = user.value;
      updatedPatient.evohaler = dailyMedication.text.trim();
      await patientRepository.updateUserDetails(updatedPatient);

      // Update local user data
      user(updatedPatient);

      TFullScreenLoader.stopLoading();

      TLoaders.successSnackBar(
          title: 'Success',
          message: 'Your Flixotide Evohaler usage has been updated!');

      // Move to previous screen.
      Get.off(() => const ProfileScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Update user details
  Future<void> updateUserDetails(PatientModel updatedUser) async {
    try {
      await patientRepository.updateUserDetails(updatedUser);
      // Update local user data
      user.value = updatedUser;
      // Force refresh to notify all listeners
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Update single field
  Future<void> updateSingleField(Map<String, dynamic> json) async {
    try {
      await patientRepository.updateSingleField(json);
      // Update the corresponding field in the local user model
      if (json.containsKey('Username')) {
        user.value.username = json['Username'];
      }
      if (json.containsKey('FirstName')) {
        user.value.firstName = json['FirstName'];
      }
      if (json.containsKey('LastName')) {
        user.value.lastName = json['LastName'];
      }
      if (json.containsKey('PhoneNumber')) {
        user.value.phoneNumber = json['PhoneNumber'];
      }
      if (json.containsKey('ProfilePicture')) {
        user.value.profilePicture = json['ProfilePicture'];
      }
      if (json.containsKey('Gender')) {
        user.value.gender = json['Gender'];
      }
      if (json.containsKey('DateOfBirth')) {
        user.value.dateOfBirth = json['DateOfBirth'];
      }
      if (json.containsKey('Evohaler')) {
        user.value.evohaler = json['Evohaler'];
      }
      // Force refresh to notify all listeners
      user.refresh();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }
}
