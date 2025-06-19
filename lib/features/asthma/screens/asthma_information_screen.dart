import 'package:asthma_app/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:asthma_app/utils/constants/colors.dart';
import 'package:asthma_app/utils/constants/image_strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ImageLoader extends StatelessWidget {
  final String imagePath;
  final double height;
  final double width;
  final BoxFit fit;
  final Color backgroundColor;

  const ImageLoader({
    super.key,
    required this.imagePath,
    required this.height,
    required this.width,
    this.fit = BoxFit.contain,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate cache dimensions with a maximum size
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final maxCacheWidth = 2048; // Maximum cache width
    final maxCacheHeight = 2048; // Maximum cache height

    // Calculate cache dimensions, handling infinity case
    final cacheWidth = width.isFinite
        ? (width * devicePixelRatio).toInt().clamp(0, maxCacheWidth)
        : maxCacheWidth;
    final cacheHeight = height.isFinite
        ? (height * devicePixelRatio).toInt().clamp(0, maxCacheHeight)
        : maxCacheHeight;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Container(
        height: height,
        width: width,
        color: backgroundColor,
        child: Center(
          child: Image.asset(
            imagePath,
            height: height,
            width: width,
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: frame != null
                    ? child
                    : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.white,
                          height: height,
                          width: width,
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ImagePreloader {
  static void preloadImages(BuildContext context) {
    final images = [
      TImages.whatIsAsthma,
      TImages.typeOfAsthma,
      TImages.inhalerImage,
      TImages.severeAsthma,
      TImages.typeOfSevere,
      TImages.quickVsLongTerm,
      TImages.resqueQuickRelief,
      TImages.longTermControl,
    ];

    for (final image in images) {
      precacheImage(AssetImage(image), context);
    }
  }
}

class AsthmaInformationScreen extends StatelessWidget {
  const AsthmaInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ImagePreloader.preloadImages(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Asthma Informations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          elevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                labelStyle: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
                labelColor: TColors.primary,
                unselectedLabelColor: Colors.black54,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3, color: TColors.primary),
                  insets: const EdgeInsets.symmetric(horizontal: 24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'What is\nAsthma?'),
                  Tab(text: 'What Triggers\nAsthma?'),
                  Tab(text: 'Could I Have\nSevere Asthma?'),
                  Tab(text: 'Asthma\nMedications'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _WhatIsAsthmaTab(),
            _WhatTriggersAsthmaTab(),
            _SevereAsthmaTab(),
            _AsthmaMedicationsTab(),
          ],
        ),
        backgroundColor: const Color(0xFFF7F8FA),
      ),
    );
  }
}

class _WhatIsAsthmaTab extends StatelessWidget {
  const _WhatIsAsthmaTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What is Asthma Card with Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.whatIsAsthma,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: TColors.primary, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'What is Asthma?',
                            style: TextStyle(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Asthma is a chronic disease that causes inflammation in the lungs, which narrows the airways, making it more difficult for sufferers to breathe. There is no cure, but it can be managed with the right treatment and knowledge.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Did you know? Asthma affects people of all ages, but it most often starts during childhood.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Types of Asthma Card with Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TColors.secondary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.typeOfAsthma,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category_outlined,
                              color: TColors.secondary, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Types of Asthma',
                            style: TextStyle(
                              color: TColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Not all asthma is the same. It may be different for different people.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Did you know? The severity of asthma can change over time, and proper treatment can help manage symptoms effectively.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _AsthmaTypeText(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AsthmaTypeText extends StatelessWidget {
  const _AsthmaTypeText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Intermittent Asthma',
          style: TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
            '> Intermittent asthma is the mildest form of asthma and has very little impact on your daily life.'),
        SizedBox(height: 12),
        Text(
          'Mild Persistent Asthma',
          style: TextStyle(
              color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
            '> Mild persistent asthma may have a minor impact on your daily life and your physical activity. It can often be controlled by using a rescue inhaler when necessary and with doctor-prescribed long-term controller medication.'),
        SizedBox(height: 12),
        Text(
          'Moderate Persistent Asthma',
          style: TextStyle(
              color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
            '> Moderate persistent asthma will likely put increased limitations on your daily physical activity and your lung function tests may show that your breathing is impaired. Your doctor may prescribe a long-term controller medication.'),
        SizedBox(height: 12),
        Text(
          'Severe Persistent Asthma',
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
            '> If you have severe persistent asthma, you experience symptoms every day, may need a rescue inhaler several times a day, and your activities are significantly limited.'),
      ],
    );
  }
}

class _WhatTriggersAsthmaTab extends StatelessWidget {
  const _WhatTriggersAsthmaTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What Triggers Asthma Card with Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.triggersAsthma,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: TColors.primary, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'What Triggers Asthma?',
                            style: TextStyle(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Asthma symptoms and attacks can be triggered by exposure to a variety of toxic and non-toxic elements, irritants in the air, activities, and conditions that can aggravate your lungs. Triggers vary between sufferers, so it's best to know your own triggers and avoid exposure to them as much as possible.",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Did you know? Identifying and avoiding your asthma triggers is one of the most important steps in managing your asthma.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'Common Asthma Triggers',
              style: TextStyle(
                color: TColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _AsthmaTriggersGrid(),
        ],
      ),
    );
  }
}

class _AsthmaTriggersGrid extends StatelessWidget {
  const _AsthmaTriggersGrid();

  @override
  Widget build(BuildContext context) {
    final triggers = [
      {
        'image': TImages.smoking,
        'title': 'Smoking',
        'description':
            'Tobacco-based smoke is a significant trigger that asthma sufferers should avoid at all costs.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/asthma-and-smoking/',
      },
      {
        'image': TImages.foodSensitivity,
        'title': 'Food Sensitivities',
        'description':
            'Food allergies and sensitivities can adversely affect the immune system and trigger asthma symptoms.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/foods-that-trigger-asthma/',
      },
      {
        'image': TImages.exercise,
        'title': 'Exercise',
        'description':
            'Strenuous activity can make asthma symptoms worse in some sufferers, causing wheezing and tightness in your chest while exercising.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/exercise-with-asthma/',
      },
      {
        'image': TImages.stress,
        'title': 'Stress',
        'description':
            'Chronic stress can contribute to an increased risk of asthma attacks. Learning how to effectively manage stress can help reduce that risk.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/stress-and-asthma/',
      },
      {
        'image': TImages.dustMites,
        'title': 'Dust Mites & Insects',
        'description':
            'These microscopic bugs are found in almost every home in the U.S., and they generate allergens that commonly trigger asthma symptoms.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/insects-dust-mites-and-asthma/',
      },
      {
        'image': TImages.allergiesAndPollen,
        'title': 'Allergies & Pollen',
        'description':
            'Allergens and pollen can trigger a reaction in your immune system that causes your airways to constrict and narrow, resulting in difficulty breathing.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/seasonal-allergy-and-asthma/',
      },
      {
        'image': TImages.airQuality,
        'title': 'Air Quality & Pollution',
        'description':
            'The toxic elements in air pollution can affect respiratory tracts and inhibit breathing.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/air-pollution-and-asthma/',
      },
      {
        'image': TImages.illnesses,
        'title': 'Illness',
        'description':
            'Conditions such as the cold and flu, sinus infections, and even acid reflux, can trigger asthma symptoms.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/illness-and-asthma/',
      },
      {
        'image': TImages.medications,
        'title': 'Medications',
        'description':
            'A number of common prescription and over-the-counter medicines can have the unfortunate side-effect of triggering asthma symptoms.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/medications-and-asthma/',
      },
      {
        'image': TImages.pets,
        'title': 'Pets',
        'description':
            'Pet dander is another very common asthma trigger, and sufferers may experience an uptick in their symptoms when exposed to certain animals.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/pets-and-asthma/',
      },
      {
        'image': TImages.strongOdors,
        'title': 'Strong Odors',
        'description':
            'Strong odors and fragances can potentially trigger asthma symptoms or make them worse.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/strong-odors-and-asthma/',
      },
      {
        'image': TImages.weatherChanges,
        'title': 'Weather Changes',
        'description':
            'From high humidity levels in the summer to cold, dry air in the winter, changes in weather can trigger asthma symptoms.',
        'url':
            'https://www.asthma.com/understanding-asthma/asthma-triggers/weather-changes-and-asthma/',
      },
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[0])),
            const SizedBox(width: 16),
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[1])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[2])),
            const SizedBox(width: 16),
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[3])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[4])),
            const SizedBox(width: 16),
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[5])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[6])),
            const SizedBox(width: 16),
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[7])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[8])),
            const SizedBox(width: 16),
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[9])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[10])),
            const SizedBox(width: 16),
            Expanded(child: _AsthmaTriggerCard(trigger: triggers[11])),
          ],
        ),
      ],
    );
  }
}

class _AsthmaTriggerCard extends StatelessWidget {
  final Map<String, String> trigger;
  const _AsthmaTriggerCard({required this.trigger});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(trigger['url']!);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: ImageLoader(
              imagePath: trigger['image']!,
              height: 110,
              width: 170,
              fit: BoxFit.cover,
              backgroundColor: Colors.grey.shade100,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trigger['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  trigger['description']!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _launchURL,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Learn More',
                        style: TextStyle(
                          color: Color(0xFF1DBF73),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 16, color: Color(0xFF1DBF73)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SevereAsthmaTab extends StatelessWidget {
  const _SevereAsthmaTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What is Severe Asthma Card with Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.severeAsthma,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sick, color: Colors.orange, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'What Is Severe Asthma',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'People with severe asthma experience symptoms throughout the day, often have their sleep disrupted at night, may need their rescue inhalers multiple times a week (sometimes daily), and might have to put limits on their daily activity. Asthma attacks can be common, and may require urgent care, ER, or hospital visits and treatment with oral steroids.\n\nSevere asthma can also remain uncontrolled despite consistently following their prescribed medication routine.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Did you know? About 5-10% of people with asthma have severe asthma, which can be more challenging to control.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Type of Severe Asthma Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.typeOfSevere,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category_outlined,
                              color: Colors.blue, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Types of Severe Asthma',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.sick, size: 40),
                                SizedBox(height: 8),
                                Text('Allergy Asthma'),
                                SizedBox(height: 8),
                                Text(
                                  'Occurs in 50-80% of people with asthma and in about 50% of people with severe asthma.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.health_and_safety, size: 40),
                                SizedBox(height: 8),
                                Text('Nonallergy Asthma'),
                                SizedBox(height: 8),
                                Text(
                                  'Occurs in 10-33% of all individuals with asthma, not just severe asthma, and has a later onset.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Eosinophils & Asthma Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.whatIsAsthma,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.science, color: Colors.green, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Eosinophils & Asthma',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'About 50% of people with severe asthma have high levels of eosinophils—white blood cells that normally support the immune system. In eosinophilic asthma, these elevated cells cause ongoing lung inflammation, contributing to asthma development.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.science, size: 32),
                                SizedBox(height: 8),
                                Text(
                                  'Eosinophils can respond to common asthma triggers.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.masks, size: 32),
                                SizedBox(height: 8),
                                Text(
                                  'Active eosinophils can build up in your airways and cause inflammation.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AsthmaMedicationsTab extends StatelessWidget {
  const _AsthmaMedicationsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Card with Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.inhalerImage,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Asthma medications have certain risks and side effects. Your healthcare provider will discuss these with you when determining which treatment option, if any, is right for you.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Did you know? Always consult your healthcare provider before starting or changing any asthma medication.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Relief vs Long-Term Control Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.quickVsLongTerm,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_information,
                              color: Colors.blue, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Relief vs \nLong-Term Control',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Some people experience mild, infrequent symptoms and may only need quick-relief medications. Others suffer from frequent and persistent symptoms that require long-term controller medications. Consult your doctor or asthma specialist to determine the best course of treatment for your type of asthma.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Rescue/Quick Relief Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.resqueQuickRelief,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.orange, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Rescue/Quick Relief',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _BulletPoint(text: 'Treats sudden asthma symptoms'),
                      _BulletPoint(
                          text:
                              'Relaxes the muscles around the airways of the lungs'),
                      _BulletPoint(
                          text:
                              'Typically delivered by an inhaler—or nebulizer if needed'),
                      _BulletPoint(
                          text:
                              'Portable and should be accessible at all times'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Long-Term Control Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                ImageLoader(
                  imagePath: TImages.longTermControl,
                  height: 200,
                  width: 380,
                  fit: BoxFit.cover,
                  backgroundColor: Colors.grey.shade100,
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hourglass_bottom,
                              color: Colors.blue, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Long-Term Control',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _BulletPoint(
                          text:
                              'Taken daily or at regular intervals regardless of symptom frequency'),
                      _BulletPoint(
                          text:
                              'Used for preventing, not relieving symptoms on the spot'),
                      _BulletPoint(
                          text:
                              'Reduces inflammation in the airways of the lungs'),
                      _BulletPoint(
                          text: 'Can be inhalers, pills, or injections'),
                      _BulletPoint(
                          text:
                              'Multiple medications can be combined and delivered in a single inhaler'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 18, color: Colors.orange)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
