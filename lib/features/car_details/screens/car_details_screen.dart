import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/car_details_controller.dart';
import '../models/car_details_model.dart';
import '../../inspection_form/models/inspection_field_defs.dart';
import '../../inspection_form/screens/inspection_form_screen.dart';
import '../../schedules/models/schedule_model.dart';
import '../../../personalization/controllers/user_controller.dart';
import 'package:video_player/video_player.dart';

// Royal blue theme
const Color _accentColor = Color(0xFF0D6EFD);
const Color _lightAccent = Color(0xFFE7F0FF);

class CarDetailsScreen extends StatelessWidget {
  final String appointmentId;

  const CarDetailsScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final tag = 'car_$appointmentId';
    Get.put(CarDetailsController(appointmentId: appointmentId), tag: tag);
    final controller = Get.find<CarDetailsController>(tag: tag);
    final dark = THelperFunctions.isDarkMode(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: dark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA),
        systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: TColors.primary));
          }

          if (controller.hasError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(controller.errorMessage.value, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: controller.refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final car = controller.carDetails.value!;
          return _CarDetailsBody(car: car, dark: dark);
        }),
      ),
    );
  }
}

class _CarDetailsBody extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;

  const _CarDetailsBody({required this.car, required this.dark});

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeroAppBar(context),
        _buildVehicleNameHeader(context),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildQuickStats(context),
              const SizedBox(height: 24),
              _CarDetailsTabs(car: car, dark: dark, txtTheme: txtTheme),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAppBar(BuildContext context) {
    final controller = Get.find<CarDetailsController>(tag: 'car_${car.appointmentId}');
    final images = car.allImages.isNotEmpty ? car.allImages : [car.frontMain.isNotEmpty ? car.frontMain.first : ''];

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        if (UserController.instance.user.value.id == 'superadmin')
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () {
                final schedule = ScheduleModel(
                  id: car.id,
                  carRegistrationNumber: car.registrationNumber,
                  yearOfRegistration: car.registrationDate,
                  ownerName: car.registeredOwner,
                  ownershipSerialNumber: car.ownerSerialNumber,
                  make: car.make,
                  model: car.model,
                  variant: car.variant,
                  emailAddress: car.emailAddress,
                  appointmentSource: 'Re-Inspection', // Use re-inspection logic to load data
                  vehicleStatus: car.status,
                  zipCode: '',
                  customerContactNumber: car.contactNumber,
                  city: car.city,
                  yearOfManufacture: car.yearMonthOfManufacture,
                  allocatedTo: '',
                  inspectionStatus: 'Re-Inspected',
                  approvalStatus: car.approvalStatus,
                  priority: 'Medium',
                  ncdUcdName: '',
                  repName: '',
                  repContact: '',
                  bankSource: '',
                  referenceName: '',
                  remarks: '',
                  createdBy: '',
                  odometerReadingInKms: car.odometerReadingInKms,
                  additionalNotes: '',
                  carImages: [],
                  inspectionDateTime: DateTime.now(),
                  inspectionAddress: '',
                  inspectionEngineerNumber: '',
                  addedBy: '',
                  timeStamp: DateTime.now(),
                  appointmentId: car.appointmentId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                Get.to(() => InspectionFormScreen(appointmentId: car.appointmentId, schedule: schedule));
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isNotEmpty && images.first.isNotEmpty)
              CarouselSlider.builder(
                itemCount: images.length,
                options: CarouselOptions(
                  height: 350,
                  viewportFraction: 1.0,
                  onPageChanged: (index, _) => controller.currentImageIndex.value = index,
                ),
                itemBuilder: (_, index, __) => Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _buildImgPlaceholder(),
                ),
              )
            else
              _buildImgPlaceholder(),
            if (images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(() => AnimatedSmoothIndicator(
                        activeIndex: controller.currentImageIndex.value,
                        count: images.length,
                        effect: ExpandingDotsEffect(dotHeight: 6, dotWidth: 6, activeDotColor: Colors.white, expansionFactor: 4),
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImgPlaceholder() => Container(color: Colors.grey.shade200, child: const Icon(Icons.directions_car, size: 80, color: Colors.grey));

  Widget _buildVehicleNameHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(car.fullCarName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(car.appointmentId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const Spacer(),
                if (car.allImages.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ImageGalleryScreen(images: car.allImages, title: 'All Photos'))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: _lightAccent, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.photo_library_rounded, size: 14, color: _accentColor),
                          SizedBox(width: 6),
                          Text('View All', style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickStatChip(icon: Icons.speed_rounded, label: '${car.odometerReadingInKms} km', color: Colors.blue),
            const SizedBox(width: 10),
            _QuickStatChip(icon: Icons.local_gas_station_rounded, label: car.fuelType, color: Colors.orange),
            const SizedBox(width: 10),
            _QuickStatChip(icon: Icons.person_rounded, label: '${car.ownerSerialNumber} Owner', color: Colors.purple),
            const SizedBox(width: 10),
            if (car.seatingCapacity > 0)
              _QuickStatChip(icon: Icons.event_seat_rounded, label: '${car.seatingCapacity} Seats', color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickStatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CarDetailsTabs extends StatefulWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _CarDetailsTabs({required this.car, required this.dark, required this.txtTheme});

  @override
  State<_CarDetailsTabs> createState() => _CarDetailsTabsState();
}

class _CarDetailsTabsState extends State<_CarDetailsTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabLabels = InspectionFieldDefs.sections.map((s) => s.title).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.dark ? const Color(0xFF1A1F36) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _accentColor),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            padding: const EdgeInsets.all(4),
            tabAlignment: TabAlignment.start,
            tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => _SectionContent(section: InspectionFieldDefs.sections[_tabController.index], car: widget.car, dark: widget.dark),
        ),
      ],
    );
  }
}

class _SectionContent extends StatelessWidget {
  final FormSectionDef section;
  final CarDetailsModel car;
  final bool dark;

  const _SectionContent({required this.section, required this.car, required this.dark});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    List<F> fields = section.fields;

    // 🏆 Custom Sequence for Interior section
    if (section.title == 'Interior') {
      final interiorSequence = [
        'noOfAirBags',
        'airbagFeaturesDriverSide',
        'driverAirbagImages',
        'airbagFeaturesCoDriverSide',
        'coDriverAirbagImages',
        'driverSeatAirbag',
        'driverSeatAirbagImages',
        'coDriverSeatAirbag',
        'coDriverSeatAirbagImages',
        'rhsCurtainAirbag',
        'rhsCurtainAirbagImages',
        'lhsCurtainAirbag',
        'lhsCurtainAirbagImages',
        'driverSideKneeAirbag',
        'driverKneeAirbagImages',
        'coDriverKneeSeatAirbag',
        'coDriverKneeAirbagImages',
        'rhsRearSideAirbag',
        'rhsRearSideAirbagImages',
        'lhsRearSideAirbag',
        'lhsRearSideAirbagImages',
        'seatsUpholstery',
        'driverSeat',
        'coDriverSeat',
        'frontCentreArmRest',
        'rearSeats',
        'thirdRowSeats',
        'frontSeatsFromDriverSideImages',
        'rearSeatsFromRightSideImages',
        'dashboardImages',
        'commentOnInterior',
      ];

      // Reorder fields based on sequence, only including those present in section.fields
      final Map<String, F> fieldMap = {for (var f in section.fields) f.key: f};
      fields = interiorSequence
          .where((key) => fieldMap.containsKey(key))
          .map((key) => fieldMap[key]!)
          .toList();
    }

    final Set<String> processedKeys = {};

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      if (processedKeys.contains(field.key)) continue;

      // Start a new group with the current field
      final List<String> currentGroup = [field.key];
      processedKeys.add(field.key);

      // Disable grouping for Interior section to keep the sequence flat as requested
      if (section.title != 'Interior') {
        // Look ahead for related fields (images/videos/comments) that should be in the same card
        for (int j = i + 1; j < fields.length; j++) {
          final nextField = fields[j];
          if (processedKeys.contains(nextField.key)) continue;

          // Relation Check: If next field is an image/video/additional field for the current one
          final bool isRelated =
              nextField.key.toLowerCase().contains(field.key.toLowerCase()) &&
              (nextField.type == FType.image ||
                  nextField.type == FType.video ||
                  nextField.key.toLowerCase().contains('comment'));

          // OR: If the current field is an image and the next one is ALSO an image for the same "part"
          final bool isPartImage =
              (field.type == FType.image || field.type == FType.video) &&
              (nextField.type == FType.image || nextField.type == FType.video) &&
              nextField.label.toLowerCase().contains(field.label.toLowerCase());

          if (isRelated || isPartImage) {
            currentGroup.add(nextField.key);
            processedKeys.add(nextField.key);
          } else {
            break; // Stop grouping once a non-related field is encountered
          }
        }
      }

      // Special case: "Full View" for the first image of a main body section
      String groupTitle = field.label;
      if (i == 0 &&
          (field.type == FType.image || field.type == FType.video) &&
          ['Front', 'Rear', 'Left', 'Right'].contains(section.title)) {
        groupTitle = 'Full View';
      }

      children.add(_buildGroup(context, groupTitle, currentGroup));
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: children,
    );
  }

  Widget _buildGroup(BuildContext context, String groupTitle, List<String> fieldKeys) {
    // Helper to find field def
    F? findField(String k) {
      for (final s in InspectionFieldDefs.sections) {
        for (final f in s.fields) {
          if (f.key == k) return f;
        }
      }
      return null;
    }

    final List<Widget> rows = [];
    for (final key in fieldKeys) {
      final field = findField(key);
      if (field == null) continue;
      
      // 🛟 Airbag reserved index mapping
      final airbagKeys = [
        'driverAirbagImages',
        'coDriverAirbagImages',
        'driverSeatAirbagImages',
        'coDriverSeatAirbagImages',
        'rhsCurtainAirbagImages',
        'lhsCurtainAirbagImages',
        'driverKneeAirbagImages',
        'coDriverKneeAirbagImages',
        'rhsRearSideAirbagImages',
        'lhsRearSideAirbagImages'
      ];
      if (airbagKeys.contains(field.key)) {
        final index = airbagKeys.indexOf(field.key);
        // Only show if the slot in the 10-index array exists and has a valid URL
        if (index >= car.airbagimages.length || car.airbagimages[index].isEmpty) continue;
      }

      rows.add(_GroupedDetailRow(field: field, car: car, dark: dark));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final headerColor = _getHeaderTintColor(groupTitle);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E243A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.4 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groupTitle.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: dark ? headerColor.withValues(alpha: 0.15) : headerColor.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(color: dark ? Colors.white10 : Colors.grey.shade100),
                  left: BorderSide(color: headerColor, width: 4),
                ),
              ),
              child: Text(
                groupTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: dark ? headerColor.withValues(alpha: 0.9) : headerColor.withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Color _getHeaderTintColor(String title) {
    if (title.isEmpty) return const Color(0xFF0D6EFD);
    final t = title.toLowerCase();
    if (t.contains('identification')) return Colors.indigo;
    if (t.contains('chassis') || t.contains('vin')) return Colors.blue;
    if (t.contains('rc') || t.contains('doc')) return Colors.teal;
    if (t.contains('tax') || t.contains('insur')) return Colors.green;
    if (t.contains('legal') || t.contains('key')) return Colors.blueGrey;
    if (t.contains('interior') || t.contains('airbag') || t.contains('zone')) return Colors.purple;
    if (t.contains('engine') || t.contains('mech')) return Colors.deepOrange;
    if (t.contains('view') || t.contains('full')) return Colors.cyan;
    final palette = [Colors.blue, Colors.teal, Colors.purple, Colors.deepOrange, Colors.indigo, Colors.pink, Colors.cyan, Colors.orange];
    return palette[(title.length + title.codeUnits.fold<int>(0, (p, c) => p + c)) % palette.length];
  }
}

class _GroupedDetailRow extends StatelessWidget {
  final F field;
  final CarDetailsModel car;
  final bool dark;

  const _GroupedDetailRow({required this.field, required this.car, required this.dark});

  @override
  Widget build(BuildContext context) {
    final value = car.getFieldValue(field.key);
    final images = car.getFieldImages(field.key);
    
    final String displayValue = _formatDisplayValue(value);
    final bool hasValue = displayValue != '-' && !displayValue.startsWith('http');
    final bool hasImages = images.isNotEmpty;
    
    // Skip if nothing to show
    if (!hasValue && !hasImages) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Text Info (Label + Value)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasValue)
                  _ValueBadge(value: displayValue, dark: dark),
              ],
            ),
          ),

          // 2. Images Side-by-Side
          if (hasImages) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _ImageThumbnail(
                    url: images[index],
                    label: '${field.label} ${index + 1}',
                    allImages: images,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDisplayValue(dynamic value) {
    if (value == null) return '-';
    String str = '';
    if (value is List) str = value.join(', ');
    else str = value.toString();

    if (str.isEmpty || str == '-' || str == 'null') return '-';

    // ISO Date Detection (UTC to Local)
    if (str.length > 10 && str.contains('T') && str.contains('Z')) {
      try {
        final date = DateTime.parse(str).toLocal();
        return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      } catch (_) {}
    }
    return str;
  }
}

class _ValueBadge extends StatelessWidget {
  final String value;
  final bool dark;

  const _ValueBadge({required this.value, required this.dark});

  @override
  Widget build(BuildContext context) {
    final Color color = _getStatusColor(value, dark);
    final isSpecial = value.toLowerCase().contains('repaid') || 
                      value.toLowerCase().contains('dent') || 
                      value.toLowerCase().contains('scratch') ||
                      value.toLowerCase().contains('broken');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconForValue(value), size: 10, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSpecial ? FontWeight.w800 : FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForValue(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('date') || lower.contains('-202')) return Icons.calendar_today_rounded;
    if (lower.contains('okay') || lower == 'yes' || lower == 'ok' || lower == 'original') return Icons.check_circle_rounded;
    if (lower.contains('not')) return Icons.remove_circle_outline_rounded;
    return Icons.info_outline_rounded;
  }

  Color _getStatusColor(String value, bool dark) {
    final lower = value.toLowerCase();
    if (lower == 'okay' || lower == 'ok' || lower == 'original' || lower == 'yes') return Colors.green.shade500;
    if (lower.contains('repaired') || lower.contains('repainted') || lower.contains('replaced')) return Colors.orange.shade500;
    if (lower.contains('dent') || lower.contains('scratch') || lower.contains('broken') || lower.contains('damage') || lower == 'no') return Colors.red.shade500;
    return dark ? Colors.white70 : Colors.black87;
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String url;
  final String label;
  final List<String> allImages;

  const _ImageThumbnail({required this.url, required this.label, required this.allImages});

  @override
  Widget build(BuildContext context) {
    final isVideo = url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _ImageGalleryScreen(images: allImages, title: label, initialIndex: allImages.indexOf(url))),
      ),
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
            ),
            if (isVideo)
              const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 24)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                color: Colors.black54,
                child: Text(
                  isVideo ? 'VIDEO' : 'IMAGE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGalleryScreen extends StatelessWidget {
  final List<String> images;
  final String title;
  final int initialIndex;

  const _ImageGalleryScreen({required this.images, required this.title, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (_, index) {
          final url = images[index];
          final isVideo = url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');

          if (isVideo) {
            return Center(child: _VideoPlayerWidget(url: url));
          }

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.setLooping(true);
      });
    
    _controller.addListener(_updateListener);
  }

  void _updateListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updateListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final duration = _controller.value.duration;
    final position = _controller.value.position;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              if (!_controller.value.isPlaying)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Video Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: VideoProgressColors(
                  playedColor: _accentColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _controller.seekTo(position - const Duration(seconds: 10)),
                        icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          });
                        },
                        icon: Icon(
                          _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _controller.seekTo(position + const Duration(seconds: 10)),
                        icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
