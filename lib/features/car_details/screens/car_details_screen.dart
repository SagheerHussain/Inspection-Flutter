import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/car_details_controller.dart';
import '../models/car_details_model.dart';

// Royal blue to match the inspection form
const Color _accentColor = Color(0xFF0D6EFD);
const Color _lightAccent = Color(0xFFE7F0FF);

class CarDetailsScreen extends StatelessWidget {
  final String appointmentId;

  const CarDetailsScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final tag = 'car_$appointmentId';
    final controller = Get.put(
      CarDetailsController(appointmentId: appointmentId),
      tag: tag,
    );
    final dark = THelperFunctions.isDarkMode(context);
    final txtTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor:
            dark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA),
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            dark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: TColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading inspection report...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (controller.hasError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load',
                    style: txtTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final car = controller.carDetails.value!;
          return _CarDetailsBody(car: car, dark: dark, txtTheme: txtTheme);
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════
// Main body with CustomScrollView
// ══════════════════════════════════════════
class _CarDetailsBody extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _CarDetailsBody({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CarDetailsController>(tag: 'car_${car.appointmentId}');

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Image AppBar ──
        _buildHeroAppBar(context, controller),

        // ── Car Name & Appointment ID Clean Header ──
        _buildVehicleNameHeader(controller),

        // ── Content ──
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Quick Stats Row
              _buildQuickStats(),
              const SizedBox(height: 24),

              // Tabs Section
              _CarDetailsTabs(car: car, dark: dark, txtTheme: txtTheme),

              const SizedBox(height: 100), // Bottom spacing
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAppBar(BuildContext context, CarDetailsController controller) {
    final images = car.allImages.isNotEmpty ? car.allImages : [car.frontMain.isNotEmpty ? car.frontMain.first : ''];

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
      ),
      backgroundColor: dark ? const Color(0xFF0A0E21) : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ── Swipable Hero Images ──
            if (images.isNotEmpty && images.first.isNotEmpty)
              CarouselSlider.builder(
                itemCount: images.length,
                options: CarouselOptions(
                  height: 350,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  autoPlay: false,
                  onPageChanged: (index, reason) {
                    controller.currentImageIndex.value = index;
                  },
                ),
                itemBuilder: (ctx, index, realIdx) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  );
                },
              )
            else
              _buildPlaceholder(),

            // Top Gradient for back button visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Image Page Indicator
            if (images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(() => AnimatedSmoothIndicator(
                        activeIndex: controller.currentImageIndex.value,
                        count: images.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          activeDotColor: Colors.white,
                          dotColor: Colors.white.withValues(alpha: 0.5),
                          expansionFactor: 4,
                          spacing: 4,
                        ),
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: dark ? const Color(0xFF1A1F36) : TColors.grey.withValues(alpha: 0.2),
      child: const Icon(
        Icons.directions_car,
        size: 80,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildVehicleNameHeader(CarDetailsController controller) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        color: dark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Name with no shadow
            Text(
              car.fullCarName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Appointment ID Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: dark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag,
                        size: 14,
                        color: dark ? Colors.white70 : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        car.appointmentId,
                        style: TextStyle(
                          color: dark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Gallery button moved here for cleaner UI
                if (car.allImages.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openGallery(Get.context!, car.allImages, 'All Photos'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _lightAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.photo_library_rounded, size: 14, color: _accentColor),
                          SizedBox(width: 6),
                          Text(
                            'View All',
                            style: TextStyle(
                              color: _accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
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

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _QuickStatChip(
            icon: Icons.speed_rounded,
            label: '${car.odometerReadingInKms} km',
            color: const Color(0xFF4A90D9),
          ),
          const SizedBox(width: 10),
          _QuickStatChip(
            icon: Icons.local_gas_station_rounded,
            label: car.fuelType,
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 10),
          _QuickStatChip(
            icon: Icons.person_rounded,
            label: '${car.ownerSerialNumber} Owner',
            color: const Color(0xFF7C4DFF),
          ),
          if (car.seatingCapacity > 0) ...[
            const SizedBox(width: 10),
            _QuickStatChip(
              icon: Icons.event_seat_rounded,
              label: '${car.seatingCapacity} Seats',
              color: const Color(0xFF4CAF50),
            ),
          ],
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, List<String> images, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageGalleryScreen(images: images, title: title),
      ),
    );
  }
}

// ══════════════════════════════════════════
// Tabbed sections for the details
// ══════════════════════════════════════════
class _CarDetailsTabs extends StatefulWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _CarDetailsTabs({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  State<_CarDetailsTabs> createState() => _CarDetailsTabsState();
}

class _CarDetailsTabsState extends State<_CarDetailsTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabLabels = [
    'Overview',
    'Exterior',
    'Engine',
    'Interior',
    'Documents',
    'Auction',
  ];

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
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.dark ? const Color(0xFF1A1F36) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.dark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _accentColor,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            padding: const EdgeInsets.all(4),
            tabAlignment: TabAlignment.start,
            tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Tab Content
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return _buildTabContent(_tabController.index);
          },
        ),
      ],
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _OverviewTab(
          car: widget.car,
          dark: widget.dark,
          txtTheme: widget.txtTheme,
        );
      case 1:
        return _ExteriorTab(
          car: widget.car,
          dark: widget.dark,
          txtTheme: widget.txtTheme,
        );
      case 2:
        return _EngineTab(
          car: widget.car,
          dark: widget.dark,
          txtTheme: widget.txtTheme,
        );
      case 3:
        return _InteriorTab(
          car: widget.car,
          dark: widget.dark,
          txtTheme: widget.txtTheme,
        );
      case 4:
        return _DocumentsTab(
          car: widget.car,
          dark: widget.dark,
          txtTheme: widget.txtTheme,
        );
      case 5:
        return _AuctionTab(
          car: widget.car,
          dark: widget.dark,
          txtTheme: widget.txtTheme,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════
// TAB 1: Overview
// ══════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _OverviewTab({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Vehicle Info Card
          _SectionCard(
            dark: dark,
            title: 'Vehicle Information',
            icon: Icons.directions_car_rounded,
            iconColor: const Color(0xFF4A90D9),
            children: [
              _DetailRow('Make', car.make),
              _DetailRow('Model', car.model),
              _DetailRow('Variant', car.variant),
              _DetailRow('Fuel Type', car.fuelType),
              _DetailRow('CC', '${car.cubicCapacity}'),
              if (car.color.isNotEmpty) _DetailRow('Color', car.color),
              _DetailRow('Cylinders', '${car.numberOfCylinders}'),
              if (car.norms.isNotEmpty) _DetailRow('Emission Norms', car.norms),
              _DetailRow('Odometer', '${car.odometerReadingInKms} km'),
              if (car.fuelLevel.isNotEmpty)
                _DetailRow('Fuel Level', car.fuelLevel),
            ],
          ),
          const SizedBox(height: 16),

          // Registration Card
          _SectionCard(
            dark: dark,
            title: 'Registration Details',
            icon: Icons.assignment_rounded,
            iconColor: const Color(0xFF7C4DFF),
            children: [
              _DetailRow('Reg. Number', car.registrationNumber),
              if (car.registrationDate.isNotEmpty)
                _DetailRow('Reg. Date', _formatDate(car.registrationDate)),
              _DetailRow('State', car.registrationState),
              _DetailRow('RTO', car.registeredRto),
              _DetailRow('Type', car.registrationType),
              _DetailRow('Owner #', '${car.ownerSerialNumber}'),
              if (car.registeredOwner.isNotEmpty &&
                  car.registeredOwner != 'Nil')
                _DetailRow('Owner', car.registeredOwner),
              if (car.engineNumber.isNotEmpty && car.engineNumber != 'Nil')
                _DetailRow('Engine No.', car.engineNumber),
              _DetailRow('Chassis No.', car.chassisNumber),
            ],
          ),
          const SizedBox(height: 16),

          // Contact Card
          _SectionCard(
            dark: dark,
            title: 'Contact & Location',
            icon: Icons.contact_phone_rounded,
            iconColor: const Color(0xFF4CAF50),
            children: [
              if (car.contactNumber.isNotEmpty)
                _DetailRow('Phone', car.contactNumber, isPhone: true),
              if (car.emailAddress.isNotEmpty)
                _DetailRow('Email', car.emailAddress),
              _DetailRow('City', car.city),
              if (car.inspectionCity.isNotEmpty)
                _DetailRow('Inspection City', car.inspectionCity),
              if (car.ieName.isNotEmpty) _DetailRow('IE Name', car.ieName),
              if (car.retailAssociate.isNotEmpty)
                _DetailRow('Retail Associate', car.retailAssociate),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// TAB 2: Exterior
// ══════════════════════════════════════════
class _ExteriorTab extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _ExteriorTab({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Image Gallery Strip
          if (car.allExteriorImages.isNotEmpty) ...[
            _ImageStrip(
              images: car.allExteriorImages,
              title: 'Exterior Photos',
              dark: dark,
            ),
            const SizedBox(height: 16),
          ],

          // Front Section
          _SectionCard(
            dark: dark,
            title: 'Front',
            icon: Icons.arrow_upward_rounded,
            iconColor: const Color(0xFF2196F3),
            children: [
              _ConditionRow('Bonnet', car.bonnet),
              _ConditionRow('Front Windshield', car.frontWindshield),
              _ConditionRow('Front Bumper', car.frontBumper),
              _ConditionRow('Roof', car.roof),
            ],
          ),
          const SizedBox(height: 16),

          // LHS Section
          _SectionCard(
            dark: dark,
            title: 'Left Hand Side (LHS)',
            icon: Icons.arrow_back_rounded,
            iconColor: const Color(0xFFFF9800),
            children: [
              _ConditionRow('Headlamp', car.lhsHeadlamp),
              _ConditionRow('Foglamp', car.lhsFoglamp),
              _ConditionRow('Fender', car.lhsFender),
              _ConditionRow('ORVM', car.lhsOrvm),
              _ConditionRow('A-Pillar', car.lhsAPillar),
              _ConditionRow('B-Pillar', car.lhsBPillar),
              _ConditionRow('C-Pillar', car.lhsCPillar),
              _ConditionRow('Front Door', car.lhsFrontDoor),
              _ConditionRow('Rear Door', car.lhsRearDoor),
              _ConditionRow('Running Border', car.lhsRunningBorder),
              _ConditionRow('Quarter Panel', car.lhsQuarterPanel),
              _ConditionRow('Front Alloy', car.lhsFrontAlloy),
              _ConditionRow('Front Tyre', car.lhsFrontTyre),
              _ConditionRow('Rear Alloy', car.lhsRearAlloy),
              _ConditionRow('Rear Tyre', car.lhsRearTyre),
            ],
          ),
          const SizedBox(height: 16),

          // RHS Section
          _SectionCard(
            dark: dark,
            title: 'Right Hand Side (RHS)',
            icon: Icons.arrow_forward_rounded,
            iconColor: const Color(0xFF9C27B0),
            children: [
              _ConditionRow('Headlamp', car.rhsHeadlamp),
              _ConditionRow('Foglamp', car.rhsFoglamp),
              _ConditionRow('Fender', car.rhsFender),
              _ConditionRow('ORVM', car.rhsOrvm),
              _ConditionRow('A-Pillar', car.rhsAPillar),
              _ConditionRow('B-Pillar', car.rhsBPillar),
              _ConditionRow('C-Pillar', car.rhsCPillar),
              _ConditionRow('Front Door', car.rhsFrontDoor),
              _ConditionRow('Rear Door', car.rhsRearDoor),
              _ConditionRow('Running Border', car.rhsRunningBorder),
              _ConditionRow('Quarter Panel', car.rhsQuarterPanel),
              _ConditionRow('Front Alloy', car.rhsFrontAlloy),
              _ConditionRow('Front Tyre', car.rhsFrontTyre),
              _ConditionRow('Rear Alloy', car.rhsRearAlloy),
              _ConditionRow('Rear Tyre', car.rhsRearTyre),
            ],
          ),
          const SizedBox(height: 16),

          // Rear Section
          _SectionCard(
            dark: dark,
            title: 'Rear',
            icon: Icons.arrow_downward_rounded,
            iconColor: const Color(0xFFF44336),
            children: [
              _ConditionRow('Rear Bumper', car.rearBumper),
              _ConditionRow('LHS Tail Lamp', car.lhsTailLamp),
              _ConditionRow('RHS Tail Lamp', car.rhsTailLamp),
              _ConditionRow('Rear Windshield', car.rearWindshield),
              _ConditionRow('Boot Door', car.bootDoor),
              _ConditionRow('Spare Tyre', car.spareTyre),
              _ConditionRow('Boot Floor', car.bootFloor),
            ],
          ),

          if (car.comments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CommentCard(
              dark: dark,
              title: 'Exterior Comments',
              text: car.comments,
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// TAB 3: Engine
// ══════════════════════════════════════════
class _EngineTab extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _EngineTab({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (car.allEngineImages.isNotEmpty) ...[
            _ImageStrip(
              images: car.allEngineImages,
              title: 'Engine Photos',
              dark: dark,
            ),
            const SizedBox(height: 16),
          ],

          _SectionCard(
            dark: dark,
            title: 'Structural',
            icon: Icons.build_rounded,
            iconColor: const Color(0xFF795548),
            children: [
              _ConditionRow('Upper Cross Member', car.upperCrossMember),
              _ConditionRow('Radiator Support', car.radiatorSupport),
              _ConditionRow('Headlight Support', car.headlightSupport),
              _ConditionRow('Lower Cross Member', car.lowerCrossMember),
              _ConditionRow('LHS Apron', car.lhsApron),
              _ConditionRow('RHS Apron', car.rhsApron),
              _ConditionRow('Firewall', car.firewall),
              _ConditionRow('Cowl Top', car.cowlTop),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            dark: dark,
            title: 'Engine & Fluids',
            icon: Icons.engineering_rounded,
            iconColor: const Color(0xFFE91E63),
            children: [
              _ConditionRow('Engine', car.engine),
              _ConditionRow('Battery', car.battery),
              _ConditionRow('Coolant', car.coolant),
              _ConditionRow('Oil Dipstick', car.engineOilLevelDipstick),
              _ConditionRow('Engine Oil', car.engineOil),
              _ConditionRow('Engine Mount', car.engineMount),
              _ConditionRow('Blow By', car.enginePermisableBlowBy),
              _ConditionRow('Exhaust Smoke', car.exhaustSmoke),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            dark: dark,
            title: 'Transmission',
            icon: Icons.settings_rounded,
            iconColor: const Color(0xFF009688),
            children: [
              _ConditionRow('Clutch', car.clutch),
              _ConditionRow('Gear Shift', car.gearShift),
              _ConditionRow('Steering', car.steering),
              _ConditionRow('Brakes', car.brakes),
              _ConditionRow('Suspension', car.suspension),
            ],
          ),

          // Comments
          if (car.commentsOnEngine.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CommentCard(
              dark: dark,
              title: 'Engine Comments',
              text: car.commentsOnEngine,
            ),
          ],
          if (car.commentsOnEngineOil.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CommentCard(
              dark: dark,
              title: 'Oil Comments',
              text: car.commentsOnEngineOil,
            ),
          ],
          if (car.commentsOnTransmission.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CommentCard(
              dark: dark,
              title: 'Transmission',
              text: car.commentsOnTransmission,
            ),
          ],
          if (car.commentsOnOthers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CommentCard(
              dark: dark,
              title: 'Other Comments',
              text: car.commentsOnOthers,
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// TAB 4: Interior
// ══════════════════════════════════════════
class _InteriorTab extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _InteriorTab({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (car.allInteriorImages.isNotEmpty) ...[
            _ImageStrip(
              images: car.allInteriorImages,
              title: 'Interior Photos',
              dark: dark,
            ),
            const SizedBox(height: 16),
          ],

          _SectionCard(
            dark: dark,
            title: 'Electricals & Features',
            icon: Icons.electric_bolt_rounded,
            iconColor: const Color(0xFFFFC107),
            children: [
              _ConditionRow('ABS', car.abs),
              _ConditionRow('Electricals', car.electricals),
              _ConditionRow('Music System', car.musicSystem),
              if (car.stereo.isNotEmpty) _ConditionRow('Stereo', car.stereo),
              _ConditionRow('Rear Wiper', car.rearWiperWasher),
              _ConditionRow('Rear Defogger', car.rearDefogger),
              if (car.reverseCamera.isNotEmpty)
                _ConditionRow('Reverse Camera', car.reverseCamera),
              if (car.steeringMountedAudioControl.isNotEmpty)
                _ConditionRow(
                  'Steering Controls',
                  car.steeringMountedAudioControl,
                ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            dark: dark,
            title: 'Windows & Seats',
            icon: Icons.weekend_rounded,
            iconColor: const Color(0xFF00BCD4),
            children: [
              _DetailRow('Power Windows', car.noOfPowerWindows),
              _DetailRow('RHS Front Window', car.powerWindowConditionRhsFront),
              _DetailRow('LHS Front Window', car.powerWindowConditionLhsFront),
              _DetailRow('RHS Rear Window', car.powerWindowConditionRhsRear),
              _DetailRow('LHS Rear Window', car.powerWindowConditionLhsRear),
              if (car.leatherSeats.isNotEmpty)
                _DetailRow('Leather Seats', car.leatherSeats),
              if (car.fabricSeats.isNotEmpty)
                _DetailRow('Fabric Seats', car.fabricSeats),
              if (car.sunroof.isNotEmpty) _DetailRow('Sunroof', car.sunroof),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            dark: dark,
            title: 'Airbags',
            icon: Icons.health_and_safety_rounded,
            iconColor: const Color(0xFFF44336),
            children: [
              _DetailRow('Total Airbags', '${car.noOfAirBags}'),
              _ConditionRow('Driver Side', car.airbagFeaturesDriverSide),
              _ConditionRow('Co-Driver Side', car.airbagFeaturesCoDriverSide),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            dark: dark,
            title: 'Air Conditioning',
            icon: Icons.ac_unit_rounded,
            iconColor: const Color(0xFF03A9F4),
            children: [
              if (car.airConditioningManual.isNotEmpty)
                _ConditionRow('Manual AC', car.airConditioningManual),
              if (car.airConditioningClimateControl.isNotEmpty)
                _ConditionRow(
                  'Climate Control',
                  car.airConditioningClimateControl,
                ),
            ],
          ),

          if (car.commentOnInterior.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CommentCard(
              dark: dark,
              title: 'Interior Comments',
              text: car.commentOnInterior,
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// TAB 5: Documents
// ══════════════════════════════════════════
class _DocumentsTab extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _DocumentsTab({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (car.allDocumentImages.isNotEmpty) ...[
            _ImageStrip(
              images: car.allDocumentImages,
              title: 'Document Photos',
              dark: dark,
            ),
            const SizedBox(height: 16),
          ],

          _SectionCard(
            dark: dark,
            title: 'RC Book',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF4A90D9),
            children: [
              _DetailRow('Availability', car.rcBookAvailability),
              _DetailRow('Condition', car.rcCondition),
              if (car.rcStatus.isNotEmpty)
                _DetailRow('RC Status', car.rcStatus),
              if (car.blacklistStatus.isNotEmpty)
                _DetailRow('Blacklist', car.blacklistStatus),
              _DetailRow('Hypothecation', car.hypothecationDetails),
              if (car.hypothecatedTo.isNotEmpty)
                _DetailRow('Hypothecated To', car.hypothecatedTo),
              _DetailRow('Mismatch in RC', car.mismatchInRc),
              _DetailRow('Road Tax', car.roadTaxValidity),
              if (car.fitnessTill.isNotEmpty)
                _DetailRow('Fitness Till', _formatDate(car.fitnessTill)),
              _DetailRow('To Be Scrapped', car.toBeScrapped),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            dark: dark,
            title: 'Insurance',
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF4CAF50),
            children: [
              _DetailRow('Insurance', car.insurance),
              if (car.insurancePolicyNumber.isNotEmpty)
                _DetailRow('Policy No.', car.insurancePolicyNumber),
              if (car.insuranceValidity.isNotEmpty)
                _DetailRow('Validity', _formatDate(car.insuranceValidity)),
              if (car.noClaimBonus.isNotEmpty)
                _DetailRow('NCB', car.noClaimBonus),
              if (car.mismatchInInsurance.isNotEmpty)
                _DetailRow('Mismatch', car.mismatchInInsurance),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            dark: dark,
            title: 'Other Documents',
            icon: Icons.folder_rounded,
            iconColor: const Color(0xFFFF9800),
            children: [
              _DetailRow('Duplicate Key', car.duplicateKey),
              if (car.rtoNoc.isNotEmpty) _DetailRow('RTO NOC', car.rtoNoc),
              if (car.rtoForm28.isNotEmpty)
                _DetailRow('RTO Form 28', car.rtoForm28),
              if (car.pucNumber.isNotEmpty)
                _DetailRow('PUC Number', car.pucNumber),
              if (car.pucValidity.isNotEmpty)
                _DetailRow('PUC Validity', _formatDate(car.pucValidity)),
              if (car.partyPeshi.isNotEmpty)
                _DetailRow('Party Peshi', car.partyPeshi),
              if (car.additionalDetails.isNotEmpty)
                _DetailRow('Additional', car.additionalDetails),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// TAB 6: Auction
// ══════════════════════════════════════════
class _AuctionTab extends StatelessWidget {
  final CarDetailsModel car;
  final bool dark;
  final TextTheme txtTheme;

  const _AuctionTab({
    required this.car,
    required this.dark,
    required this.txtTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Price Discovery Card (Highlighted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A90D9),
                  const Color(0xFF4A90D9).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Price Discovery',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${_formatAmount(car.priceDiscovery)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (car.priceDiscoveryBy.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'by ${car.priceDiscoveryBy}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bid & Auction Info
          if (car.highestBid > 0) ...[
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    dark: dark,
                    label: 'Highest Bid',
                    value: '₹ ${_formatAmount(car.highestBid)}',
                    icon: Icons.gavel_rounded,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    dark: dark,
                    label: 'Auction Status',
                    value: car.auctionStatus.replaceAll(RegExp(r'(?=[A-Z])'), ' ').trim(),
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          _SectionCard(
            dark: dark,
            title: 'Approval',
            icon: Icons.verified_rounded,
            iconColor: const Color(0xFF4CAF50),
            children: [
              _DetailRow('Status', car.approvalStatus),
              if (car.approvedBy.isNotEmpty) _DetailRow('Approved By', car.approvedBy),
              if (car.approvalDate.isNotEmpty) _DetailRow('Date', _formatDate(car.approvalDate)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// Reusable Components
// ══════════════════════════════════════════

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionCard extends StatelessWidget {
  final bool dark;
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.dark,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1F36) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: dark ? 0.15 : 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPhone;

  const _DetailRow(this.label, this.value, {this.isPhone = false});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child:
                isPhone
                    ? GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('tel:$value');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF4A90D9),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                    : Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final String condition;

  const _ConditionRow(this.label, this.condition);

  Color _conditionColor(String cond) {
    final lower = cond.toLowerCase();
    if (lower.contains('okay') &&
        !lower.contains('repaired') &&
        !lower.contains('repainted')) {
      return const Color(0xFF4CAF50);
    }
    if (lower.contains('repaired') ||
        lower.contains('replaced') ||
        lower.contains('damaged')) {
      return const Color(0xFFF44336);
    }
    if (lower.contains('repainted') || lower.contains('scratched')) {
      return const Color(0xFFFF9800);
    }
    if (lower.contains('not applicable') || lower.contains('not working')) {
      return const Color(0xFF9E9E9E);
    }
    return const Color(0xFF4CAF50);
  }

  IconData _conditionIcon(String cond) {
    final lower = cond.toLowerCase();
    if (lower.contains('okay') &&
        !lower.contains('repaired') &&
        !lower.contains('repainted')) {
      return Icons.check_circle_rounded;
    }
    if (lower.contains('repaired') ||
        lower.contains('replaced') ||
        lower.contains('damaged')) {
      return Icons.warning_rounded;
    }
    if (lower.contains('repainted') || lower.contains('scratched')) {
      return Icons.info_rounded;
    }
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    if (condition.isEmpty) return const SizedBox.shrink();
    final color = _conditionColor(condition);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_conditionIcon(condition), size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                condition,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final bool dark;
  final String title;
  final String text;

  const _CommentCard({
    required this.dark,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1F36) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sticky_note_2_rounded,
            color: const Color(0xFFFF9800).withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: dark ? Colors.white70 : Colors.black87,
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

class _ImageStrip extends StatelessWidget {
  final List<String> images;
  final String title;
  final bool dark;

  const _ImageStrip({
    required this.images,
    required this.title,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const Spacer(),
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              _ImageGalleryScreen(images: images, title: title),
                    ),
                  ),
              child: Text(
                'View All ${images.length}',
                style: const TextStyle(
                  color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length > 6 ? 6 : images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => _ImageGalleryScreen(
                              images: images,
                              title: title,
                              initialIndex: index,
                            ),
                      ),
                    ),
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(
                    right:
                        index < (images.length > 6 ? 5 : images.length - 1)
                            ? 10
                            : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color:
                                dark
                                    ? const Color(0xFF1A1F36)
                                    : Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final bool dark;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.dark,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1F36) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// Image Gallery Full Screen
// ══════════════════════════════════════════
class _ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final String title;
  final int initialIndex;

  const _ImageGalleryScreen({
    required this.images,
    required this.title,
    this.initialIndex = 0,
  });

  @override
  State<_ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<_ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.title} (${_currentIndex + 1}/${widget.images.length})',
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: TColors.primary,
                      value:
                          progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder:
                    (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════
// Helper Functions
// ══════════════════════════════════════════
String _formatDate(String dateStr) {
  try {
    if (dateStr.isEmpty) return '';
    final dt = DateTime.parse(dateStr).toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final datePart = '${dt.day} ${months[dt.month - 1]} ${dt.year}';

    // If string looks like it contains time, append formatted time
    if (dateStr.contains('T') || dateStr.contains(':')) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$datePart, $hour:$minute $period';
    }

    return datePart;
  } catch (_) {
    return dateStr;
  }
}

String _formatAmount(int amount) {
  if (amount >= 100000) {
    return '${(amount / 100000).toStringAsFixed(2)} L';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)} K';
  }
  return amount.toString();
}
