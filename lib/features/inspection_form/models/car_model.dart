class CarModel {
  final String id;
  final DateTime? timestamp;
  final String emailAddress; // renamed to ieName
  final String appointmentId;
  final String city; // renamed to inspectionCity
  final DateTime? inspectionDate;
  final String registrationType; // removed
  final String rcBookAvailability; // changed to rcBookAvailabilityDropdownList
  final String rcCondition;
  final String registrationNumber;
  final DateTime? registrationDate;
  final DateTime? fitnessTill; // renamed to fitnessValidity
  final String toBeScrapped;
  final String registrationState;
  final String registeredRto;
  final int ownerSerialNumber;
  final String make;
  final String model;
  final String variant;
  final String engineNumber;
  final String chassisNumber;
  final String registeredOwner;
  final String registeredAddressAsPerRc;
  final DateTime?
  yearMonthOfManufacture; // renamed to yearAndMonthOfManufacture
  final String fuelType;
  final int cubicCapacity;
  final String hypothecationDetails;
  final String mismatchInRc; // changed to mismatchInRcDropdownList
  final String roadTaxValidity;
  final DateTime? taxValidTill;
  final String insurance; // changed to insuranceDropdownList
  final String insurancePolicyNumber; // renamed to policyNumber
  final DateTime? insuranceValidity;
  final String noClaimBonus; // removed
  final String
  mismatchInInsurance; // changed to mismatchInInsuranceDropdownList
  final String duplicateKey;
  final String rtoNoc;
  final String rtoForm28;
  final String partyPeshi;
  final String additionalDetails; // changed to additionalDetailsDropdownList
  final List<String> rcTaxToken; // renamed to rcTokenImages
  final List<String> insuranceCopy; // renamed to insuranceImages
  final List<String> bothKeys; // renamed to duplicateKeyImages
  final List<String>
  form26GdCopyIfRcIsLost; // renamed to form26AndGdCopyIfRcIsLostImages
  final String bonnet; // changed to bonnetDropdownList
  final String frontWindshield; // changed to frontWindshieldDropdownList
  final String roof; // changed to roofDropdownList
  final String frontBumper; // changed to frontBumperDropdownList
  final String lhsHeadlamp; // changed to lhsHeadlampDropdownList
  final String lhsFoglamp; // changed to lhsFoglampDropdownList
  final String rhsHeadlamp; // changed to rhsHeadlampDropdownList
  final String rhsFoglamp; // changed to rhsFoglampDropdownList
  final String lhsFender; // changed to lhsFenderDropdownList
  final String lhsOrvm; // changed to lhsOrvmDropdownList
  final String lhsAPillar; // changed to lhsAPillarDropdownList
  final String lhsBPillar; // changed to lhsBPillarDropdownList
  final String lhsCPillar; // changed to lhsCPillarDropdownList
  final String lhsFrontAlloy; // renamed to lhsFrontWheelDropdownList
  final String lhsFrontTyre; // changed to lhsFrontTyreDropdownList
  final String lhsRearAlloy; // renamed to lhsRearWheelDropdownList
  final String lhsRearTyre; // changed to lhsRearTyreDropdownList
  final String lhsFrontDoor; // changed to lhsFrontDoorDropdownList
  final String lhsRearDoor; // changed to lhsRearDoorDropdownList
  final String lhsRunningBorder; // changed to lhsRunningBorderDropdownList
  final String lhsQuarterPanel; // changed to lhsQuarterPanelDropdownList
  final String rearBumper; // changed to rearBumperDropdownList
  final String lhsTailLamp; // changed to lhsTailLampDropdownList
  final String rhsTailLamp; // changed to rhsTailLampDropdownList
  final String rearWindshield; // changed to rearWindshieldDropdownList
  final String bootDoor; // changed to bootDoorDropdownList
  final String spareTyre; // changed to spareTyreDropdownList
  final String bootFloor; // changed to bootFloorDropdownList
  final String rhsRearAlloy; // renamed to rhsRearWheelDropdownList
  final String rhsRearTyre; // changed to rhsRearTyreDropdownList
  final String rhsFrontAlloy; // renamed to rhsFrontWheelDropdownList
  final String rhsFrontTyre; // changed to rhsFrontTyreDropdownList
  final String rhsQuarterPanel; // changed to rhsQuarterPanelDropdownList
  final String rhsAPillar; // changed to rhsAPillarDropdownList
  final String rhsBPillar; // changed to rhsBPillarDropdownList
  final String rhsCPillar; // changed to rhsCPillarDropdownList
  final String rhsRunningBorder; // changed to rhsRunningBorderDropdownList
  final String rhsRearDoor; // changed to rhsRearDoorDropdownList
  final String rhsFrontDoor; // changed to rhsFrontDoorDropdownList
  final String rhsOrvm; // changed to rhsOrvmDropdownList
  final String rhsFender; // changed to rhsFenderDropdownList
  final String comments; // renamed to commentsOnExteriorDropdownList
  final List<String> frontMain; // changed to frontMainImages
  final List<String>
  bonnetImages; // divided into bonnetClosedImages, bonnetOpenImages and bonnetImages
  final List<String> frontWindshieldImages;
  final List<String> roofImages;
  final List<String>
  frontBumperImages; // divided into frontBumperLhs45DegreeImages, frontBumperRhs45DegreeImages and frontBumperImages
  final List<String> lhsHeadlampImages;
  final List<String> lhsFoglampImages;
  final List<String> rhsHeadlampImages;
  final List<String> rhsFoglampImages;
  final List<String> lhsFront45Degree; // renamed to lhsFullViewImages
  final List<String> lhsFenderImages;
  final List<String> lhsFrontAlloyImages; // renamed to lhsFrontWheelImages
  final List<String> lhsFrontTyreImages;
  final List<String> lhsRunningBorderImages;
  final List<String> lhsOrvmImages;
  final List<String> lhsAPillarImages;
  final List<String> lhsFrontDoorImages;
  final List<String> lhsBPillarImages;
  final List<String> lhsRearDoorImages;
  final List<String> lhsCPillarImages;
  final List<String> lhsRearTyreImages;
  final List<String> lhsRearAlloyImages; // renamed to lhsRearWheelImages
  final List<String>
  lhsQuarterPanelImages; // divided into lhsQuarterPanelWithRearDoorOpenImages and lhsQuarterPanelWithRearDoorClosedImages
  final List<String> rearMain; // renamed to rearMainImages
  final String rearWithBootDoorOpen; // renamed to rearWithBootDoorOpenImages
  final List<String>
  rearBumperImages; // divided into rearBumperLhs45DegreeImages, rearBumperRhs45DegreeImages and rearBumperImages
  final List<String> lhsTailLampImages;
  final List<String> rhsTailLampImages;
  final List<String> rearWindshieldImages;
  final List<String> spareTyreImages;
  final List<String> bootFloorImages;
  final List<String> rhsRear45Degree; // renamed to rhsFullViewImages
  final List<String>
  rhsQuarterPanelImages; // divided into rhsQuarterPanelWithRearDoorOpenImages and rhsQuarterPanelWithRearDoorClosedImages
  final List<String> rhsRearAlloyImages; // renamed to rhsRearWheelImages
  final List<String> rhsRearTyreImages;
  final List<String> rhsCPillarImages;
  final List<String> rhsRearDoorImages;
  final List<String> rhsBPillarImages;
  final List<String> rhsFrontDoorImages;
  final List<String> rhsAPillarImages;
  final List<String> rhsRunningBorderImages;
  final List<String> rhsFrontAlloyImages; // renamed to rhsFrontWheelImages
  final List<String> rhsFrontTyreImages;
  final List<String> rhsOrvmImages;
  final List<String> rhsFenderImages;
  final String upperCrossMember; // changed to upperCrossMemberDropdownList
  final String radiatorSupport; // changed to radiatorSupportDropdownList
  final String headlightSupport; // changed to headlightSupportDropdownList
  final String lowerCrossMember; // changed to lowerCrossMemberDropdownList
  final String lhsApron; // changed to lhsApronDropdownList
  final String rhsApron; // changed to rhsApronDropdownList
  final String firewall; // changed to firewallDropdownList
  final String cowlTop; // changed to cowlTopDropdownList
  final String engine; // changed to engineDropdownList
  final String battery; // changed to batteryDropdownList
  final String coolant; // changed to coolantDropdownList
  final String
  engineOilLevelDipstick; // changed to engineOilLevelDipstickDropdownList
  final String engineOil; // changed to engineOilDropdownList
  final String engineMount; // changed to engineMountDropdownList
  final String
  enginePermisableBlowBy; // changed to enginePermisableBlowByDropdownList
  final String exhaustSmoke; // changed to exhaustSmokeDropdownList
  final String clutch; // changed to clutchDropdownList
  final String gearShift; // changed to gearShiftDropdownList
  final String commentsOnEngine; // changed to commentsOnEngineDropdownList
  final String
  commentsOnEngineOil; // changed to commentsOnEngineOilDropdownList
  final String commentsOnTowing; // changed to commentsOnTowingDropdownList
  final String
  commentsOnTransmission; // changed to commentsOnTransmissionDropdownList
  final String commentsOnRadiator; // changed to commentsOnRadiatorDropdownList
  final String commentsOnOthers; // changed to commentsOnOthersDropdownList
  final List<String> engineBay; // renamed to engineBayImages
  final List<String>
  apronLhsRhs; // removed apronLhsRhs and divided into lhsApronImages and rhsApronImages
  final List<String> batteryImages;
  final List<String> additionalImages; // renamed to additionalEngineImages
  final List<String> engineSound; // renamed to engineVideo
  final List<String> exhaustSmokeImages; // renamed to exhaustSmokeVideo
  final String steering; // changed to steeringDropdownList
  final String brakes; // changed to brakesDropdownList
  final String suspension; // changed to suspensionDropdownList
  final int odometerReadingInKms; // renamed to odometerReadingBeforeTestDrive
  final String fuelLevel;
  final String abs;
  final String electricals; // removed
  final String rearWiperWasher; // changed to rearWiperWasherDropdownList
  final String rearDefogger; // changed to rearDefoggerDropdownList
  final String
  musicSystem; // removed and merged into infotainmentSystemDropdownList
  final String stereo; // removed and merged into infotainmentSystemDropdownList
  final String inbuiltSpeaker;
  final String externalSpeaker;
  final String
  steeringMountedAudioControl; // removed and divided into steeringMountedMediaControls and steeringMountedSystemControls
  final String noOfPowerWindows;
  final String
  powerWindowConditionRhsFront; // renamed to rhsFrontDoorFeaturesDropdownList
  final String
  powerWindowConditionLhsFront; // renamed to lhsFrontDoorFeaturesDropdownList
  final String
  powerWindowConditionRhsRear; // renamed to rhsRearDoorFeaturesDropdownList
  final String
  powerWindowConditionLhsRear; // renamed to lhsRearDoorFeaturesDropdownList
  final String commentOnInterior; // changed to commentOnInteriorDropdownList
  final int noOfAirBags;
  final String airbagFeaturesDriverSide; // renamed to driverAirbag
  final String airbagFeaturesCoDriverSide; // renamed to coDriverAirbag
  final String airbagFeaturesLhsAPillarCurtain; // renamed to coDriverSeatAirbag
  final String airbagFeaturesLhsBPillarCurtain; // renamed to lhsCurtainAirbag
  final String airbagFeaturesLhsCPillarCurtain; // renamed to lhsRearSideAirbag
  final String airbagFeaturesRhsAPillarCurtain; // renamed to driverSeatAirbag
  final String airbagFeaturesRhsBPillarCurtain; // renamed to rhsCurtainAirbag
  final String airbagFeaturesRhsCPillarCurtain; // renamed to rhsRearSideAirbag
  final String sunroof; // changed to sunroofDropdownList
  final String leatherSeats; // removed and merged to seatsUpholstery
  final String fabricSeats; // removed and merged to seatsUpholstery
  final String commentsOnElectricals; // removed
  final List<String> meterConsoleWithEngineOn; // renamed to meterConsoleWithEngineOnImages
  final List<String> sunroofImages;
  final List<String>
  frontSeatsFromDriverSideDoorOpen; // renamed to frontSeatsFromDriverSideImages
  final List<String>
  rearSeatsFromRightSideDoorOpen; // renamed to rearSeatsFromRightSideImages
  final List<String> dashboardFromRearSeat; // renamed to dashboardImages
  final String reverseCamera; // changed to reverseCameraDropdownList
  final List<String> additionalImages2; // renamed to additionalInteriorImages
  final String airConditioningManual; // renamed to acTypeDropdownList
  final String
  airConditioningClimateControl; // renamed to acCoolingDropdownList
  final String commentsOnAc;
  final String approvedBy;
  final DateTime? approvalDate;
  final DateTime? approvalTime;
  final String approvalStatus;
  final String contactNumber;
  final DateTime? newArrivalMessage;
  final String budgetCar;
  final String status;
  final int priceDiscovery;
  final String priceDiscoveryBy;
  final String latlong;
  final String retailAssociate;
  final int kmRangeLevel;
  final String highestBidder;
  final int v;

  // ✅ New fields (all nullable)
  final String ieName;
  final String inspectionCity;
  final List<String> rcBookAvailabilityDropdownList;
  final DateTime? fitnessValidity;
  final DateTime? yearAndMonthOfManufacture;
  final List<String> mismatchInRcDropdownList;
  final List<String> insuranceDropdownList;
  final String policyNumber;
  final List<String> mismatchInInsuranceDropdownList;
  final List<String> additionalDetailsDropdownList;
  final List<String> rcTokenImages;
  final List<String> insuranceImages;
  final List<String> duplicateKeyImages;
  final List<String> form26AndGdCopyIfRcIsLostImages;
  final List<String> bonnetDropdownList;
  final List<String> frontWindshieldDropdownList;
  final List<String> roofDropdownList;
  final List<String> frontBumperDropdownList;
  final List<String> lhsHeadlampDropdownList;
  final List<String> lhsFoglampDropdownList;
  final List<String> rhsHeadlampDropdownList;
  final List<String> rhsFoglampDropdownList;
  final List<String> lhsFenderDropdownList;
  final List<String> lhsOrvmDropdownList;
  final List<String> lhsAPillarDropdownList;
  final List<String> lhsBPillarDropdownList;
  final List<String> lhsCPillarDropdownList;
  final List<String> lhsFrontWheelDropdownList;
  final List<String> lhsFrontTyreDropdownList;
  final List<String> lhsRearWheelDropdownList;
  final List<String> lhsRearTyreDropdownList;
  final List<String> lhsFrontDoorDropdownList;
  final List<String> lhsRearDoorDropdownList;
  final List<String> lhsRunningBorderDropdownList;
  final List<String> lhsQuarterPanelDropdownList;
  final List<String> rearBumperDropdownList;
  final List<String> lhsTailLampDropdownList;
  final List<String> rhsTailLampDropdownList;
  final List<String> rearWindshieldDropdownList;
  final List<String> bootDoorDropdownList;
  final List<String> spareTyreDropdownList;
  final List<String> bootFloorDropdownList;
  final List<String> rhsRearWheelDropdownList;
  final List<String> rhsRearTyreDropdownList;
  final List<String> rhsFrontWheelDropdownList;
  final List<String> rhsFrontTyreDropdownList;
  final List<String> rhsQuarterPanelDropdownList;
  final List<String> rhsAPillarDropdownList;
  final List<String> rhsBPillarDropdownList;
  final List<String> rhsCPillarDropdownList;
  final List<String> rhsRunningBorderDropdownList;
  final List<String> rhsRearDoorDropdownList;
  final List<String> rhsFrontDoorDropdownList;
  final List<String> rhsOrvmDropdownList;
  final List<String> rhsFenderDropdownList;
  final List<String> commentsOnExteriorDropdownList;
  final List<String> frontMainImages;
  final List<String> bonnetClosedImages;
  final List<String> bonnetOpenImages;
  final List<String> frontBumperLhs45DegreeImages;
  final List<String> frontBumperRhs45DegreeImages;
  final List<String> lhsFullViewImages;
  final List<String> lhsFrontWheelImages;
  final List<String> lhsRearWheelImages;
  final List<String> lhsQuarterPanelWithRearDoorOpenImages;
  final List<String> lhsQuarterPanelWithRearDoorClosedImages;
  final List<String> rearMainImages;
  final List<String> rearWithBootDoorOpenImages;
  final List<String> bootDoorImages;
  final List<String> rearBumperLhs45DegreeImages;
  final List<String> rearBumperRhs45DegreeImages;
  final List<String> rhsFullViewImages;
  final List<String> rhsQuarterPanelWithRearDoorOpenImages;
  final List<String> rhsQuarterPanelWithRearDoorClosedImages;
  final List<String> rhsRearWheelImages;
  final List<String> rhsFrontWheelImages;
  final List<String> upperCrossMemberDropdownList;
  final List<String> radiatorSupportDropdownList;
  final List<String> headlightSupportDropdownList;
  final List<String> lowerCrossMemberDropdownList;
  final List<String> lhsApronDropdownList;
  final List<String> rhsApronDropdownList;
  final List<String> firewallDropdownList;
  final List<String> cowlTopDropdownList;
  final List<String> engineDropdownList;
  final List<String> batteryDropdownList;
  final List<String> coolantDropdownList;
  final List<String> engineOilLevelDipstickDropdownList;
  final List<String> engineOilDropdownList;
  final List<String> engineMountDropdownList;
  final List<String> enginePermisableBlowByDropdownList;
  final List<String> exhaustSmokeDropdownList;
  final List<String> clutchDropdownList;
  final List<String> gearShiftDropdownList;
  final List<String> commentsOnEngineDropdownList;
  final List<String> commentsOnEngineOilDropdownList;
  final List<String> commentsOnTowingDropdownList;
  final List<String> commentsOnTransmissionDropdownList;
  final List<String> commentsOnRadiatorDropdownList;
  final List<String> commentsOnOthersDropdownList;
  final List<String> engineBayImages;
  final List<String> lhsApronImages;
  final List<String> rhsApronImages;
  final List<String> additionalEngineImages;
  final List<String> engineVideo;
  final List<String> exhaustSmokeVideo;
  final List<String> steeringDropdownList;
  final List<String> brakesDropdownList;
  final List<String> suspensionDropdownList;
  final int odometerReadingBeforeTestDrive;
  final List<String> rearWiperWasherDropdownList;
  final List<String> rearDefoggerDropdownList;
  final List<String> infotainmentSystemDropdownList;
  final String steeringMountedMediaControls;
  final String steeringMountedSystemControls;
  final List<String> rhsFrontDoorFeaturesDropdownList;
  final List<String> lhsFrontDoorFeaturesDropdownList;
  final List<String> rhsRearDoorFeaturesDropdownList;
  final List<String> lhsRearDoorFeaturesDropdownList;
  final List<String> commentOnInteriorDropdownList;
  final String driverAirbag;
  final String coDriverAirbag;
  final String coDriverSeatAirbag;
  final String lhsCurtainAirbag;
  final String lhsRearSideAirbag;
  final String driverSeatAirbag;
  final String rhsCurtainAirbag;
  final String rhsRearSideAirbag;
  final List<String> sunroofDropdownList;
  final String seatsUpholstery;
  final List<String> meterConsoleWithEngineOnImages;
  final List<String> airbagImages;
  final List<String> frontSeatsFromDriverSideImages;
  final List<String> rearSeatsFromRightSideImages;
  final List<String> dashboardImages;
  final List<String> reverseCameraDropdownList;
  final List<String> additionalInteriorImages;
  final String acTypeDropdownList;
  final String acCoolingDropdownList;
  // Fresh
  final List<String> chassisEmbossmentImages;
  final String chassisDetails;
  final List<String> vinPlateImages;
  final String vinPlateDetails;
  final List<String> roadTaxImages;
  final int seatingCapacity;
  final String color;
  final int numberOfCylinders;
  final String norms;
  final String hypothecatedTo;
  final String insurer;
  final List<String> pucImages;
  final DateTime? pucValidity;
  final String pucNumber;
  final String rcStatus;
  final String blacklistStatus;
  final List<String> rtoNocImages;
  final List<String> rtoForm28Images;
  final List<String> frontWiperAndWasherDropdownList;
  final List<String> frontWiperAndWasherImages;
  final List<String> lhsRearFogLampDropdownList;
  final List<String> lhsRearFogLampImages;
  final List<String> rhsRearFogLampDropdownList;
  final List<String> rhsRearFogLampImages;
  final List<String> rearWiperAndWasherImages;
  final List<String> spareWheelDropdownList;
  final List<String> spareWheelImages;
  final List<String> cowlTopImages;
  final List<String> firewallImages;
  final List<String> lhsSideMemberDropdownList;
  final List<String> rhsSideMemberDropdownList;
  final List<String> transmissionTypeDropdownList;
  final List<String> driveTrainDropdownList;
  final List<String> commentsOnClusterMeterDropdownList;
  final String irvm;
  final List<String> dashboardDropdownList;
  final List<String> acImages;
  final List<String> reverseCameraImages;
  final String driverSideKneeAirbag;
  final String coDriverKneeSeatAirbag;
  final List<String> driverSeatDropdownList;
  final List<String> coDriverSeatDropdownList;
  final List<String> frontCentreArmRestDropdownList;
  final List<String> rearSeatsDropdownList;
  final List<String> thirdRowSeatsDropdownList;
  final List<String> odometerReadingAfterTestDriveImages;
  final int odometerReadingAfterTestDriveInKms;
  final String version;
  final Map<String, dynamic>? attesterRawCarDetails;

  CarModel({
    required this.id,
    required this.timestamp,
    required this.emailAddress,
    required this.appointmentId,
    required this.city,
    required this.inspectionDate,
    required this.registrationType,
    required this.rcBookAvailability,
    required this.rcCondition,
    required this.registrationNumber,
    required this.registrationDate,
    required this.fitnessTill,
    required this.toBeScrapped,
    required this.registrationState,
    required this.registeredRto,
    required this.ownerSerialNumber,
    required this.make,
    required this.model,
    required this.variant,
    required this.engineNumber,
    required this.chassisNumber,
    required this.registeredOwner,
    required this.registeredAddressAsPerRc,
    required this.yearMonthOfManufacture,
    required this.fuelType,
    required this.cubicCapacity,
    required this.hypothecationDetails,
    required this.mismatchInRc,
    required this.roadTaxValidity,
    required this.taxValidTill,
    required this.insurance,
    required this.insurancePolicyNumber,
    required this.insuranceValidity,
    required this.noClaimBonus,
    required this.mismatchInInsurance,
    required this.duplicateKey,
    required this.rtoNoc,
    required this.rtoForm28,
    required this.partyPeshi,
    required this.additionalDetails,
    required this.rcTaxToken,
    required this.insuranceCopy,
    required this.bothKeys,
    required this.form26GdCopyIfRcIsLost,
    required this.bonnet,
    required this.frontWindshield,
    required this.roof,
    required this.frontBumper,
    required this.lhsHeadlamp,
    required this.lhsFoglamp,
    required this.rhsHeadlamp,
    required this.rhsFoglamp,
    required this.lhsFender,
    required this.lhsOrvm,
    required this.lhsAPillar,
    required this.lhsBPillar,
    required this.lhsCPillar,
    required this.lhsFrontAlloy,
    required this.lhsFrontTyre,
    required this.lhsRearAlloy,
    required this.lhsRearTyre,
    required this.lhsFrontDoor,
    required this.lhsRearDoor,
    required this.lhsRunningBorder,
    required this.lhsQuarterPanel,
    required this.rearBumper,
    required this.lhsTailLamp,
    required this.rhsTailLamp,
    required this.rearWindshield,
    required this.bootDoor,
    required this.spareTyre,
    required this.bootFloor,
    required this.rhsRearAlloy,
    required this.rhsRearTyre,
    required this.rhsFrontAlloy,
    required this.rhsFrontTyre,
    required this.rhsQuarterPanel,
    required this.rhsAPillar,
    required this.rhsBPillar,
    required this.rhsCPillar,
    required this.rhsRunningBorder,
    required this.rhsRearDoor,
    required this.rhsFrontDoor,
    required this.rhsOrvm,
    required this.rhsFender,
    required this.comments,
    required this.frontMain,
    required this.bonnetImages,
    required this.frontWindshieldImages,
    required this.roofImages,
    required this.frontBumperImages,
    required this.lhsHeadlampImages,
    required this.lhsFoglampImages,
    required this.rhsHeadlampImages,
    required this.rhsFoglampImages,
    required this.lhsFront45Degree,
    required this.lhsFenderImages,
    required this.lhsFrontAlloyImages,
    required this.lhsFrontTyreImages,
    required this.lhsRunningBorderImages,
    required this.lhsOrvmImages,
    required this.lhsAPillarImages,
    required this.lhsFrontDoorImages,
    required this.lhsBPillarImages,
    required this.lhsRearDoorImages,
    required this.lhsCPillarImages,
    required this.lhsRearTyreImages,
    required this.lhsRearAlloyImages,
    required this.lhsQuarterPanelImages,
    required this.rearMain,
    required this.rearWithBootDoorOpen,
    required this.rearBumperImages,
    required this.lhsTailLampImages,
    required this.rhsTailLampImages,
    required this.rearWindshieldImages,
    required this.spareTyreImages,
    required this.bootFloorImages,
    required this.rhsRear45Degree,
    required this.rhsQuarterPanelImages,
    required this.rhsRearAlloyImages,
    required this.rhsRearTyreImages,
    required this.rhsCPillarImages,
    required this.rhsRearDoorImages,
    required this.rhsBPillarImages,
    required this.rhsFrontDoorImages,
    required this.rhsAPillarImages,
    required this.rhsRunningBorderImages,
    required this.rhsFrontAlloyImages,
    required this.rhsFrontTyreImages,
    required this.rhsOrvmImages,
    required this.rhsFenderImages,
    required this.upperCrossMember,
    required this.radiatorSupport,
    required this.headlightSupport,
    required this.lowerCrossMember,
    required this.lhsApron,
    required this.rhsApron,
    required this.firewall,
    required this.cowlTop,
    required this.engine,
    required this.battery,
    required this.coolant,
    required this.engineOilLevelDipstick,
    required this.engineOil,
    required this.engineMount,
    required this.enginePermisableBlowBy,
    required this.exhaustSmoke,
    required this.clutch,
    required this.gearShift,
    required this.commentsOnEngine,
    required this.commentsOnEngineOil,
    required this.commentsOnTowing,
    required this.commentsOnTransmission,
    required this.commentsOnRadiator,
    required this.commentsOnOthers,
    required this.engineBay,
    required this.apronLhsRhs,
    required this.batteryImages,
    required this.additionalImages,
    required this.engineSound,
    required this.exhaustSmokeImages,
    required this.steering,
    required this.brakes,
    required this.suspension,
    required this.odometerReadingInKms,
    required this.fuelLevel,
    required this.abs,
    required this.electricals,
    required this.rearWiperWasher,
    required this.rearDefogger,
    required this.musicSystem,
    required this.stereo,
    required this.inbuiltSpeaker,
    required this.externalSpeaker,
    required this.steeringMountedAudioControl,
    required this.noOfPowerWindows,
    required this.powerWindowConditionRhsFront,
    required this.powerWindowConditionLhsFront,
    required this.powerWindowConditionRhsRear,
    required this.powerWindowConditionLhsRear,
    required this.commentOnInterior,
    required this.noOfAirBags,
    required this.airbagFeaturesDriverSide,
    required this.airbagFeaturesCoDriverSide,
    required this.airbagFeaturesLhsAPillarCurtain,
    required this.airbagFeaturesLhsBPillarCurtain,
    required this.airbagFeaturesLhsCPillarCurtain,
    required this.airbagFeaturesRhsAPillarCurtain,
    required this.airbagFeaturesRhsBPillarCurtain,
    required this.airbagFeaturesRhsCPillarCurtain,
    required this.sunroof,
    required this.leatherSeats,
    required this.fabricSeats,
    required this.commentsOnElectricals,
    required this.meterConsoleWithEngineOn,
    required this.sunroofImages,
    required this.frontSeatsFromDriverSideDoorOpen,
    required this.rearSeatsFromRightSideDoorOpen,
    required this.dashboardFromRearSeat,
    required this.reverseCamera,
    required this.additionalImages2,
    required this.airConditioningManual,
    required this.airConditioningClimateControl,
    required this.commentsOnAc,
    required this.approvedBy,
    required this.approvalDate,
    required this.approvalTime,
    required this.approvalStatus,
    required this.contactNumber,
    required this.newArrivalMessage,
    required this.budgetCar,
    required this.status,
    required this.priceDiscovery,
    required this.priceDiscoveryBy,
    required this.latlong,
    required this.retailAssociate,
    required this.kmRangeLevel,
    required this.highestBidder,
    required this.v,
    required this.version,
    this.attesterRawCarDetails,

    // ✅ New fields (all nullable)
    required this.ieName,
    required this.inspectionCity,
    required this.rcBookAvailabilityDropdownList,
    required this.fitnessValidity,
    required this.yearAndMonthOfManufacture,
    required this.mismatchInRcDropdownList,
    required this.insuranceDropdownList,
    required this.policyNumber,
    required this.mismatchInInsuranceDropdownList,
    required this.additionalDetailsDropdownList,
    required this.rcTokenImages,
    required this.insuranceImages,
    required this.duplicateKeyImages,
    required this.form26AndGdCopyIfRcIsLostImages,
    required this.bonnetDropdownList,
    required this.frontWindshieldDropdownList,
    required this.roofDropdownList,
    required this.frontBumperDropdownList,
    required this.lhsHeadlampDropdownList,
    required this.lhsFoglampDropdownList,
    required this.rhsHeadlampDropdownList,
    required this.rhsFoglampDropdownList,
    required this.lhsFenderDropdownList,
    required this.lhsOrvmDropdownList,
    required this.lhsAPillarDropdownList,
    required this.lhsBPillarDropdownList,
    required this.lhsCPillarDropdownList,
    required this.lhsFrontWheelDropdownList,
    required this.lhsFrontTyreDropdownList,
    required this.lhsRearWheelDropdownList,
    required this.lhsRearTyreDropdownList,
    required this.lhsFrontDoorDropdownList,
    required this.lhsRearDoorDropdownList,
    required this.lhsRunningBorderDropdownList,
    required this.lhsQuarterPanelDropdownList,
    required this.rearBumperDropdownList,
    required this.lhsTailLampDropdownList,
    required this.rhsTailLampDropdownList,
    required this.rearWindshieldDropdownList,
    required this.bootDoorDropdownList,
    required this.spareTyreDropdownList,
    required this.bootFloorDropdownList,
    required this.rhsRearWheelDropdownList,
    required this.rhsRearTyreDropdownList,
    required this.rhsFrontWheelDropdownList,
    required this.rhsFrontTyreDropdownList,
    required this.rhsQuarterPanelDropdownList,
    required this.rhsAPillarDropdownList,
    required this.rhsBPillarDropdownList,
    required this.rhsCPillarDropdownList,
    required this.rhsRunningBorderDropdownList,
    required this.rhsRearDoorDropdownList,
    required this.rhsFrontDoorDropdownList,
    required this.rhsOrvmDropdownList,
    required this.rhsFenderDropdownList,
    required this.commentsOnExteriorDropdownList,
    required this.frontMainImages,
    required this.bonnetClosedImages,
    required this.bonnetOpenImages,
    required this.frontBumperLhs45DegreeImages,
    required this.frontBumperRhs45DegreeImages,
    required this.lhsFullViewImages,
    required this.lhsFrontWheelImages,
    required this.lhsRearWheelImages,
    required this.lhsQuarterPanelWithRearDoorOpenImages,
    required this.lhsQuarterPanelWithRearDoorClosedImages,
    required this.rearMainImages,
    required this.rearWithBootDoorOpenImages,
    required this.bootDoorImages,
    required this.rearBumperLhs45DegreeImages,
    required this.rearBumperRhs45DegreeImages,
    required this.rhsFullViewImages,
    required this.rhsQuarterPanelWithRearDoorOpenImages,
    required this.rhsQuarterPanelWithRearDoorClosedImages,
    required this.rhsRearWheelImages,
    required this.rhsFrontWheelImages,
    required this.upperCrossMemberDropdownList,
    required this.radiatorSupportDropdownList,
    required this.headlightSupportDropdownList,
    required this.lowerCrossMemberDropdownList,
    required this.lhsApronDropdownList,
    required this.rhsApronDropdownList,
    required this.firewallDropdownList,
    required this.cowlTopDropdownList,
    required this.engineDropdownList,
    required this.batteryDropdownList,
    required this.coolantDropdownList,
    required this.engineOilLevelDipstickDropdownList,
    required this.engineOilDropdownList,
    required this.engineMountDropdownList,
    required this.enginePermisableBlowByDropdownList,
    required this.exhaustSmokeDropdownList,
    required this.clutchDropdownList,
    required this.gearShiftDropdownList,
    required this.commentsOnEngineDropdownList,
    required this.commentsOnEngineOilDropdownList,
    required this.commentsOnTowingDropdownList,
    required this.commentsOnTransmissionDropdownList,
    required this.commentsOnRadiatorDropdownList,
    required this.commentsOnOthersDropdownList,
    required this.engineBayImages,
    required this.lhsApronImages,
    required this.rhsApronImages,
    required this.additionalEngineImages,
    required this.engineVideo,
    required this.exhaustSmokeVideo,
    required this.steeringDropdownList,
    required this.brakesDropdownList,
    required this.suspensionDropdownList,
    required this.odometerReadingBeforeTestDrive,
    required this.rearWiperWasherDropdownList,
    required this.rearDefoggerDropdownList,
    required this.infotainmentSystemDropdownList,
    required this.steeringMountedMediaControls,
    required this.steeringMountedSystemControls,
    required this.rhsFrontDoorFeaturesDropdownList,
    required this.lhsFrontDoorFeaturesDropdownList,
    required this.rhsRearDoorFeaturesDropdownList,
    required this.lhsRearDoorFeaturesDropdownList,
    required this.commentOnInteriorDropdownList,
    required this.driverAirbag,
    required this.coDriverAirbag,
    required this.coDriverSeatAirbag,
    required this.lhsCurtainAirbag,
    required this.lhsRearSideAirbag,
    required this.driverSeatAirbag,
    required this.rhsCurtainAirbag,
    required this.rhsRearSideAirbag,
    required this.sunroofDropdownList,
    required this.seatsUpholstery,
    required this.meterConsoleWithEngineOnImages,
    required this.airbagImages,
    required this.frontSeatsFromDriverSideImages,
    required this.rearSeatsFromRightSideImages,
    required this.dashboardImages,
    required this.reverseCameraDropdownList,
    required this.additionalInteriorImages,
    required this.acTypeDropdownList,
    required this.acCoolingDropdownList,
    required this.chassisEmbossmentImages,
    required this.chassisDetails,
    required this.vinPlateImages,
    required this.vinPlateDetails,
    required this.roadTaxImages,
    required this.seatingCapacity,
    required this.color,
    required this.numberOfCylinders,
    required this.norms,
    required this.hypothecatedTo,
    required this.insurer,
    required this.pucImages,
    required this.pucValidity,
    required this.pucNumber,
    required this.rcStatus,
    required this.blacklistStatus,
    required this.rtoNocImages,
    required this.rtoForm28Images,
    required this.frontWiperAndWasherDropdownList,
    required this.frontWiperAndWasherImages,
    required this.lhsRearFogLampDropdownList,
    required this.lhsRearFogLampImages,
    required this.rhsRearFogLampDropdownList,
    required this.rhsRearFogLampImages,
    required this.rearWiperAndWasherImages,
    required this.spareWheelDropdownList,
    required this.spareWheelImages,
    required this.cowlTopImages,
    required this.firewallImages,
    required this.lhsSideMemberDropdownList,
    required this.rhsSideMemberDropdownList,
    required this.transmissionTypeDropdownList,
    required this.driveTrainDropdownList,
    required this.commentsOnClusterMeterDropdownList,
    required this.irvm,
    required this.dashboardDropdownList,
    required this.acImages,
    required this.reverseCameraImages,
    required this.driverSideKneeAirbag,
    required this.coDriverKneeSeatAirbag,
    required this.driverSeatDropdownList,
    required this.coDriverSeatDropdownList,
    required this.frontCentreArmRestDropdownList,
    required this.rearSeatsDropdownList,
    required this.thirdRowSeatsDropdownList,
    required this.odometerReadingAfterTestDriveImages,
    required this.odometerReadingAfterTestDriveInKms,
  });

  factory CarModel.fromJson({
    required Map<String, dynamic> json,
    required String documentId,
  }) {
    return CarModel(
      id: documentId,
      timestamp: parseMongoDbDate(json["timestamp"]),
      emailAddress: json["emailAddress"] ?? 'N/A',
      appointmentId: json["appointmentId"] ?? 'N/A',
      city: json["city"] ?? 'N/A',
      inspectionDate: parseMongoDbDate(json["inspectionDate"]),
      registrationType: json["registrationType"] ?? 'N/A',
      rcBookAvailability: json["rcBookAvailability"] ?? 'N/A',
      rcCondition: json["rcCondition"] ?? 'N/A',
      registrationNumber: json["registrationNumber"] ?? 'N/A',
      registrationDate: parseMongoDbDate(json["registrationDate"]),
      fitnessTill: parseMongoDbDate(json["fitnessTill"]),
      toBeScrapped: json["toBeScrapped"] ?? 'N/A',
      registrationState: json["registrationState"] ?? 'N/A',
      registeredRto: json["registeredRto"] ?? 'N/A',
      ownerSerialNumber: json["ownerSerialNumber"] ?? 0,
      make: json["make"] ?? 'N/A',
      model: json["model"] ?? 'N/A',
      variant: json["variant"] ?? 'N/A',
      engineNumber: json["engineNumber"] ?? 'N/A',
      chassisNumber: json["chassisNumber"] ?? 'N/A',
      registeredOwner: json["registeredOwner"] ?? 'N/A',
      registeredAddressAsPerRc: json["registeredAddressAsPerRc"] ?? 'N/A',
      yearMonthOfManufacture: parseMongoDbDate(json["yearMonthOfManufacture"]),
      fuelType: json["fuelType"] ?? 'N/A',
      cubicCapacity: json["cubicCapacity"] ?? 0,
      hypothecationDetails: json["hypothecationDetails"] ?? 'N/A',
      mismatchInRc: json["mismatchInRc"] ?? 'N/A',
      roadTaxValidity: json["roadTaxValidity"] ?? 'N/A',
      taxValidTill: parseMongoDbDate(json["taxValidTill"]),
      insurance: json["insurance"] ?? 'N/A',
      insurancePolicyNumber: json["insurancePolicyNumber"] ?? 'N/A',
      insuranceValidity: parseMongoDbDate(json["insuranceValidity"]),
      noClaimBonus: json["noClaimBonus"] ?? 'N/A',
      mismatchInInsurance: json["mismatchInInsurance"] ?? 'N/A',
      duplicateKey: json["duplicateKey"] ?? 'N/A',
      rtoNoc: json["rtoNoc"] ?? 'N/A',
      rtoForm28: json["rtoForm28"] ?? 'N/A',
      partyPeshi: json["partyPeshi"] ?? 'N/A',
      additionalDetails: json["additionalDetails"] ?? 'N/A',
      rcTaxToken: parseStringList(json["rcTaxToken"]),
      insuranceCopy: parseStringList(json["insuranceCopy"]),
      bothKeys: parseStringList(json["bothKeys"]),
      form26GdCopyIfRcIsLost: parseStringList(json["form26GdCopyIfRcIsLost"]),
      bonnet: json["bonnet"] ?? 'N/A',
      frontWindshield: json["frontWindshield"] ?? 'N/A',
      roof: json["roof"] ?? 'N/A',
      frontBumper: json["frontBumper"] ?? 'N/A',
      lhsHeadlamp: json["lhsHeadlamp"] ?? 'N/A',
      lhsFoglamp: json["lhsFoglamp"] ?? 'N/A',
      rhsHeadlamp: json["rhsHeadlamp"] ?? 'N/A',
      rhsFoglamp: json["rhsFoglamp"] ?? 'N/A',
      lhsFender: json["lhsFender"] ?? 'N/A',
      lhsOrvm: json["lhsOrvm"] ?? 'N/A',
      lhsAPillar: json["lhsAPillar"] ?? 'N/A',
      lhsBPillar: json["lhsBPillar"] ?? 'N/A',
      lhsCPillar: json["lhsCPillar"] ?? 'N/A',
      lhsFrontAlloy: json["lhsFrontAlloy"] ?? 'N/A',
      lhsFrontTyre: json["lhsFrontTyre"] ?? 'N/A',
      lhsRearAlloy: json["lhsRearAlloy"] ?? 'N/A',
      lhsRearTyre: json["lhsRearTyre"] ?? 'N/A',
      lhsFrontDoor: json["lhsFrontDoor"] ?? 'N/A',
      lhsRearDoor: json["lhsRearDoor"] ?? 'N/A',
      lhsRunningBorder: json["lhsRunningBorder"] ?? 'N/A',
      lhsQuarterPanel: json["lhsQuarterPanel"] ?? 'N/A',
      rearBumper: json["rearBumper"] ?? 'N/A',
      lhsTailLamp: json["lhsTailLamp"] ?? 'N/A',
      rhsTailLamp: json["rhsTailLamp"] ?? 'N/A',
      rearWindshield: json["rearWindshield"] ?? 'N/A',
      bootDoor: json["bootDoor"] ?? 'N/A',
      spareTyre: json["spareTyre"] ?? 'N/A',
      bootFloor: json["bootFloor"] ?? 'N/A',
      rhsRearAlloy: json["rhsRearAlloy"] ?? 'N/A',
      rhsRearTyre: json["rhsRearTyre"] ?? 'N/A',
      rhsFrontAlloy: json["rhsFrontAlloy"] ?? 'N/A',
      rhsFrontTyre: json["rhsFrontTyre"] ?? 'N/A',
      rhsQuarterPanel: json["rhsQuarterPanel"] ?? 'N/A',
      rhsAPillar: json["rhsAPillar"] ?? 'N/A',
      rhsBPillar: json["rhsBPillar"] ?? 'N/A',
      rhsCPillar: json["rhsCPillar"] ?? 'N/A',
      rhsRunningBorder: json["rhsRunningBorder"] ?? 'N/A',
      rhsRearDoor: json["rhsRearDoor"] ?? 'N/A',
      rhsFrontDoor: json["rhsFrontDoor"] ?? 'N/A',
      rhsOrvm: json["rhsOrvm"] ?? 'N/A',
      rhsFender: json["rhsFender"] ?? 'N/A',
      comments: json["comments"] ?? 'N/A',
      frontMain: parseStringList(json["frontMain"]),
      bonnetImages: parseStringList(json["bonnetImages"]),
      frontWindshieldImages: parseStringList(json["frontWindshieldImages"]),
      roofImages: parseStringList(json["roofImages"]),
      frontBumperImages: parseStringList(json["frontBumperImages"]),
      lhsHeadlampImages: parseStringList(json["lhsHeadlampImages"]),
      lhsFoglampImages: parseStringList(json["lhsFoglampImages"]),
      rhsHeadlampImages: parseStringList(json["rhsHeadlampImages"]),
      rhsFoglampImages: parseStringList(json["rhsFoglampImages"]),
      lhsFront45Degree: parseStringList(json["lhsFront45Degree"]),
      lhsFenderImages: parseStringList(json["lhsFenderImages"]),
      lhsFrontAlloyImages: parseStringList(json["lhsFrontAlloyImages"]),
      lhsFrontTyreImages: parseStringList(json["lhsFrontTyreImages"]),
      lhsRunningBorderImages: parseStringList(json["lhsRunningBorderImages"]),
      lhsOrvmImages: parseStringList(json["lhsOrvmImages"]),
      lhsAPillarImages: parseStringList(json["lhsAPillarImages"]),
      lhsFrontDoorImages: parseStringList(json["lhsFrontDoorImages"]),
      lhsBPillarImages: parseStringList(json["lhsBPillarImages"]),
      lhsRearDoorImages: parseStringList(json["lhsRearDoorImages"]),
      lhsCPillarImages: parseStringList(json["lhsCPillarImages"]),
      lhsRearTyreImages: parseStringList(json["lhsRearTyreImages"]),
      lhsRearAlloyImages: parseStringList(json["lhsRearAlloyImages"]),
      lhsQuarterPanelImages: parseStringList(json["lhsQuarterPanelImages"]),
      rearMain: parseStringList(json["rearMain"]),
      rearWithBootDoorOpen: json["rearWithBootDoorOpen"] ?? 'N/A',
      rearBumperImages: parseStringList(json["rearBumperImages"]),
      lhsTailLampImages: parseStringList(json["lhsTailLampImages"]),
      rhsTailLampImages: parseStringList(json["rhsTailLampImages"]),
      rearWindshieldImages: parseStringList(json["rearWindshieldImages"]),
      spareTyreImages: parseStringList(json["spareTyreImages"]),
      bootFloorImages: parseStringList(json["bootFloorImages"]),
      rhsRear45Degree: parseStringList(json["rhsRear45Degree"]),
      rhsRearAlloyImages: parseStringList(json["rhsRearAlloyImages"]),
      rhsRearTyreImages: parseStringList(json["rhsRearTyreImages"]),
      rhsCPillarImages: parseStringList(json["rhsCPillarImages"]),
      rhsRearDoorImages: parseStringList(json["rhsRearDoorImages"]),
      rhsBPillarImages: parseStringList(json["rhsBPillarImages"]),
      rhsFrontDoorImages: parseStringList(json["rhsFrontDoorImages"]),
      rhsAPillarImages: parseStringList(json["rhsAPillarImages"]),
      rhsRunningBorderImages: parseStringList(json["rhsRunningBorderImages"]),
      rhsFrontAlloyImages: parseStringList(json["rhsFrontAlloyImages"]),
      rhsFrontTyreImages: parseStringList(json["rhsFrontTyreImages"]),
      rhsOrvmImages: parseStringList(json["rhsOrvmImages"]),
      rhsFenderImages: parseStringList(json["rhsFenderImages"]),
      upperCrossMember: json["upperCrossMember"] ?? 'N/A',
      radiatorSupport: json["radiatorSupport"] ?? 'N/A',
      headlightSupport: json["headlightSupport"] ?? 'N/A',
      lowerCrossMember: json["lowerCrossMember"] ?? 'N/A',
      lhsApron: json["lhsApron"] ?? 'N/A',
      rhsApron: json["rhsApron"] ?? 'N/A',
      firewall: json["firewall"] ?? 'N/A',
      cowlTop: json["cowlTop"] ?? 'N/A',
      engine: json["engine"] ?? 'N/A',
      battery: json["battery"] ?? 'N/A',
      coolant: json["coolant"] ?? 'N/A',
      engineOilLevelDipstick: json["engineOilLevelDipstick"] ?? 'N/A',
      engineOil: json["engineOil"] ?? 'N/A',
      engineMount: json["engineMount"] ?? 'N/A',
      enginePermisableBlowBy: json["enginePermisableBlowBy"] ?? 'N/A',
      exhaustSmoke: json["exhaustSmoke"] ?? 'N/A',
      clutch: json["clutch"] ?? 'N/A',
      gearShift: json["gearShift"] ?? 'N/A',
      commentsOnEngine: json["commentsOnEngine"] ?? 'N/A',
      commentsOnEngineOil: json["commentsOnEngineOil"] ?? 'N/A',
      commentsOnTowing: json["commentsOnTowing"] ?? 'N/A',
      commentsOnTransmission: json["commentsOnTransmission"] ?? 'N/A',
      commentsOnRadiator: json["commentsOnRadiator"] ?? 'N/A',
      commentsOnOthers: json["commentsOnOthers"] ?? 'N/A',
      engineBay: parseStringList(json["engineBay"]),
      apronLhsRhs: parseStringList(json["apronLhsRhs"]),
      batteryImages: parseStringList(json["batteryImages"]),
      additionalImages: parseStringList(json["additionalImages"]),
      engineSound: parseStringList(json["engineSound"]),
      exhaustSmokeImages: parseStringList(json["exhaustSmokeImages"]),
      steering: json["steering"] ?? 'N/A',
      brakes: json["brakes"] ?? 'N/A',
      suspension: json["suspension"] ?? 'N/A',
      odometerReadingInKms: json["odometerReadingInKms"] ?? 0,
      fuelLevel: json["fuelLevel"] ?? 'N/A',
      abs: json["abs"] ?? 'N/A',
      electricals: json["electricals"] ?? 'N/A',
      rearWiperWasher: json["rearWiperWasher"] ?? 'N/A',
      rearDefogger: json["rearDefogger"] ?? 'N/A',
      musicSystem: json["musicSystem"] ?? 'N/A',
      stereo: json["stereo"] ?? 'N/A',
      inbuiltSpeaker: json["inbuiltSpeaker"] ?? 'N/A',
      externalSpeaker: json["externalSpeaker"] ?? 'N/A',
      steeringMountedAudioControl: json["steeringMountedAudioControl"] ?? 'N/A',
      noOfPowerWindows: json["noOfPowerWindows"] ?? 'N/A',
      powerWindowConditionRhsFront:
          json["powerWindowConditionRhsFront"] ?? 'N/A',
      powerWindowConditionLhsFront:
          json["powerWindowConditionLhsFront"] ?? 'N/A',
      powerWindowConditionRhsRear: json["powerWindowConditionRhsRear"] ?? 'N/A',
      powerWindowConditionLhsRear: json["powerWindowConditionLhsRear"] ?? 'N/A',
      commentOnInterior: json["commentOnInterior"] ?? 'N/A',
      noOfAirBags: json["noOfAirBags"] ?? 0,
      airbagFeaturesDriverSide: json["airbagFeaturesDriverSide"] ?? 'N/A',
      airbagFeaturesCoDriverSide: json["airbagFeaturesCoDriverSide"] ?? 'N/A',
      airbagFeaturesLhsAPillarCurtain:
          json["airbagFeaturesLhsAPillarCurtain"] ?? 'N/A',
      airbagFeaturesLhsBPillarCurtain:
          json["airbagFeaturesLhsBPillarCurtain"] ?? 'N/A',
      airbagFeaturesLhsCPillarCurtain:
          json["airbagFeaturesLhsCPillarCurtain"] ?? 'N/A',
      airbagFeaturesRhsAPillarCurtain:
          json["airbagFeaturesRhsAPillarCurtain"] ?? 'N/A',
      airbagFeaturesRhsBPillarCurtain:
          json["airbagFeaturesRhsBPillarCurtain"] ?? 'N/A',
      airbagFeaturesRhsCPillarCurtain:
          json["airbagFeaturesRhsCPillarCurtain"] ?? 'N/A',
      sunroof: json["sunroof"] ?? 'N/A',
      leatherSeats: json["leatherSeats"] ?? 'N/A',
      fabricSeats: json["fabricSeats"] ?? 'N/A',
      commentsOnElectricals: json["commentsOnElectricals"] ?? 'N/A',
      meterConsoleWithEngineOn: parseStringList(
        json["meterConsoleWithEngineOn"],
      ),
      sunroofImages: parseStringList(json["sunroofImages"]),
      frontSeatsFromDriverSideDoorOpen: parseStringList(
        json["frontSeatsFromDriverSideDoorOpen"],
      ),
      rearSeatsFromRightSideDoorOpen: parseStringList(
        json["rearSeatsFromRightSideDoorOpen"],
      ),
      dashboardFromRearSeat: parseStringList(json["dashboardFromRearSeat"]),
      reverseCamera: json["reverseCamera"] ?? 'N/A',
      additionalImages2: parseStringList(json["additionalImages2"]),
      airConditioningManual: json["airConditioningManual"] ?? 'N/A',
      airConditioningClimateControl:
          json["airConditioningClimateControl"] ?? 'N/A',
      commentsOnAc: json["commentsOnAC"] ?? 'N/A',
      approvedBy: json["approvedBy"] ?? 'N/A',
      approvalDate: parseMongoDbDate(json["approvalDate"]),
      approvalTime: parseMongoDbDate(json["approvalTime"]),
      approvalStatus: json["approvalStatus"] ?? 'N/A',
      contactNumber: json["contactNumber"] ?? 'N/A',
      newArrivalMessage: parseMongoDbDate(json["newArrivalMessage"]),
      budgetCar: json["budgetCar"] ?? 'N/A',
      status: json["status"] ?? 'N/A',
      priceDiscovery: json["priceDiscovery"] ?? 0,
      priceDiscoveryBy: json["priceDiscoveryBy"] ?? 'N/A',
      latlong: json["latlong"] ?? 'N/A',
      retailAssociate: json["retailAssociate"] ?? 'N/A',
      kmRangeLevel: json["kmRangeLevel"] ?? 0,
      highestBidder: json["highestBidder"] ?? 'N/A',
      v: json["__v"] ?? 0,

      // ✅ New fields all (nullable)
      ieName: json["ieName"] ?? 'N/A',
      inspectionCity: json["inspectionCity"] ?? 'N/A',
      rcBookAvailabilityDropdownList: parseStringList(
        json["rcBookAvailabilityDropdownList"],
      ),
      fitnessValidity: parseMongoDbDate(json["fitnessValidity"]),
      yearAndMonthOfManufacture: parseMongoDbDate(
        json["yearAndMonthOfManufacture"],
      ),
      mismatchInRcDropdownList: parseStringList(
        json["mismatchInRcDropdownList"],
      ),
      insuranceDropdownList: parseStringList(json["insuranceDropdownList"]),
      policyNumber: json["policyNumber"] ?? 'N/A',
      mismatchInInsuranceDropdownList: parseStringList(
        json["mismatchInInsuranceDropdownList"],
      ),
      additionalDetailsDropdownList: parseStringList(
        json["additionalDetailsDropdownList"],
      ),
      rcTokenImages: parseStringList(json["rcTokenImages"]),
      insuranceImages: parseStringList(json["insuranceImages"]),
      duplicateKeyImages: parseStringList(json["duplicateKeyImages"]),
      form26AndGdCopyIfRcIsLostImages: parseStringList(
        json["form26AndGdCopyIfRcIsLostImages"],
      ),
      bonnetDropdownList: parseStringList(json["bonnetDropdownList"]),
      frontWindshieldDropdownList: parseStringList(
        json["frontWindshieldDropdownList"],
      ),
      roofDropdownList: parseStringList(json["roofDropdownList"]),
      frontBumperDropdownList: parseStringList(json["frontBumperDropdownList"]),
      lhsHeadlampDropdownList: parseStringList(json["lhsHeadlampDropdownList"]),
      lhsFoglampDropdownList: parseStringList(json["lhsFoglampDropdownList"]),
      rhsHeadlampDropdownList: parseStringList(json["rhsHeadlampDropdownList"]),
      rhsFoglampDropdownList: parseStringList(json["rhsFoglampDropdownList"]),
      lhsFenderDropdownList: parseStringList(json["lhsFenderDropdownList"]),
      lhsOrvmDropdownList: parseStringList(json["lhsOrvmDropdownList"]),
      lhsAPillarDropdownList: parseStringList(json["lhsAPillarDropdownList"]),
      lhsBPillarDropdownList: parseStringList(json["lhsBPillarDropdownList"]),
      lhsCPillarDropdownList: parseStringList(json["lhsCPillarDropdownList"]),
      lhsFrontWheelDropdownList: parseStringList(
        json["lhsFrontWheelDropdownList"],
      ),
      lhsFrontTyreDropdownList: parseStringList(
        json["lhsFrontTyreDropdownList"],
      ),
      lhsRearWheelDropdownList: parseStringList(
        json["lhsRearWheelDropdownList"],
      ),
      lhsRearTyreDropdownList: parseStringList(json["lhsRearTyreDropdownList"]),
      lhsFrontDoorDropdownList: parseStringList(
        json["lhsFrontDoorDropdownList"],
      ),
      lhsRearDoorDropdownList: parseStringList(json["lhsRearDoorDropdownList"]),
      lhsRunningBorderDropdownList: parseStringList(
        json["lhsRunningBorderDropdownList"],
      ),
      lhsQuarterPanelDropdownList: parseStringList(
        json["lhsQuarterPanelDropdownList"],
      ),
      rearBumperDropdownList: parseStringList(json["rearBumperDropdownList"]),
      lhsTailLampDropdownList: parseStringList(json["lhsTailLampDropdownList"]),
      rhsTailLampDropdownList: parseStringList(json["rhsTailLampDropdownList"]),
      rearWindshieldDropdownList: parseStringList(
        json["rearWindshieldDropdownList"],
      ),
      bootDoorDropdownList: parseStringList(json["bootDoorDropdownList"]),
      spareTyreDropdownList: parseStringList(json["spareTyreDropdownList"]),
      bootFloorDropdownList: parseStringList(json["bootFloorDropdownList"]),
      rhsRearWheelDropdownList: parseStringList(
        json["rhsRearWheelDropdownList"],
      ),
      rhsRearTyreDropdownList: parseStringList(json["rhsRearTyreDropdownList"]),
      rhsFrontWheelDropdownList: parseStringList(
        json["rhsFrontWheelDropdownList"],
      ),
      rhsFrontTyreDropdownList: parseStringList(
        json["rhsFrontTyreDropdownList"],
      ),
      rhsQuarterPanelDropdownList: parseStringList(
        json["rhsQuarterPanelDropdownList"],
      ),
      rhsAPillarDropdownList: parseStringList(json["rhsAPillarDropdownList"]),
      rhsBPillarDropdownList: parseStringList(json["rhsBPillarDropdownList"]),
      rhsCPillarDropdownList: parseStringList(json["rhsCPillarDropdownList"]),
      rhsRunningBorderDropdownList: parseStringList(
        json["rhsRunningBorderDropdownList"],
      ),
      rhsRearDoorDropdownList: parseStringList(json["rhsRearDoorDropdownList"]),
      rhsFrontDoorDropdownList: parseStringList(
        json["rhsFrontDoorDropdownList"],
      ),
      rhsOrvmDropdownList: parseStringList(json["rhsOrvmDropdownList"]),
      rhsFenderDropdownList: parseStringList(json["rhsFenderDropdownList"]),
      commentsOnExteriorDropdownList: parseStringList(
        json["commentsOnExteriorDropdownList"],
      ),
      frontMainImages: parseStringList(json["frontMainImages"]),
      bonnetClosedImages: parseStringList(json["bonnetClosedImages"]),
      bonnetOpenImages: parseStringList(json["bonnetOpenImages"]),
      frontBumperLhs45DegreeImages: parseStringList(
        json["frontBumperLhs45DegreeImages"],
      ),
      frontBumperRhs45DegreeImages: parseStringList(
        json["frontBumperRhs45DegreeImages"],
      ),
      lhsFullViewImages: parseStringList(json["lhsFullViewImages"]),
      lhsFrontWheelImages: parseStringList(json["lhsFrontWheelImages"]),
      lhsRearWheelImages: parseStringList(json["lhsRearWheelImages"]),
      lhsQuarterPanelWithRearDoorOpenImages: parseStringList(
        json["lhsQuarterPanelWithRearDoorOpenImages"],
      ),
      lhsQuarterPanelWithRearDoorClosedImages: parseStringList(
        json["lhsQuarterPanelWithRearDoorClosedImages"],
      ),
      rearMainImages: parseStringList(json["rearMainImages"]),
      rearWithBootDoorOpenImages: parseStringList(
         json["rearWithBootDoorOpenImages"],
       ),
      bootDoorImages: parseStringList(json["bootdoorimages"] ?? json["bootDoorImages"]),
      rearBumperLhs45DegreeImages: parseStringList(
        json["rearBumperLhs45DegreeImages"],
      ),
      rearBumperRhs45DegreeImages: parseStringList(
        json["rearBumperRhs45DegreeImages"],
      ),
      rhsFullViewImages: parseStringList(json["rhsFullViewImages"]),
      rhsQuarterPanelWithRearDoorOpenImages: parseStringList(
        json["rhsQuarterPanelWithRearDoorOpenImages"],
      ),
      rhsQuarterPanelWithRearDoorClosedImages: parseStringList(
        json["rhsQuarterPanelWithRearDoorClosedImages"],
      ),
      rhsQuarterPanelImages: parseStringList(json["rhsQuarterPanelImages"]),
      rhsRearWheelImages: parseStringList(json["rhsRearWheelImages"]),
      rhsFrontWheelImages: parseStringList(json["rhsFrontWheelImages"]),
      upperCrossMemberDropdownList: parseStringList(
        json["upperCrossMemberDropdownList"],
      ),
      radiatorSupportDropdownList: parseStringList(
        json["radiatorSupportDropdownList"],
      ),
      headlightSupportDropdownList: parseStringList(
        json["headlightSupportDropdownList"],
      ),
      lowerCrossMemberDropdownList: parseStringList(
        json["lowerCrossMemberDropdownList"],
      ),
      lhsApronDropdownList: parseStringList(json["lhsApronDropdownList"]),
      rhsApronDropdownList: parseStringList(json["rhsApronDropdownList"]),
      firewallDropdownList: parseStringList(json["firewallDropdownList"]),
      cowlTopDropdownList: parseStringList(json["cowlTopDropdownList"]),
      engineDropdownList: parseStringList(json["engineDropdownList"]),
      batteryDropdownList: parseStringList(json["batteryDropdownList"]),
      coolantDropdownList: parseStringList(json["coolantDropdownList"]),
      engineOilLevelDipstickDropdownList: parseStringList(
        json["engineOilLevelDipstickDropdownList"],
      ),
      engineOilDropdownList: parseStringList(json["engineOilDropdownList"]),
      engineMountDropdownList: parseStringList(json["engineMountDropdownList"]),
      enginePermisableBlowByDropdownList: parseStringList(
        json["enginePermisableBlowByDropdownList"],
      ),
      exhaustSmokeDropdownList: parseStringList(
        json["exhaustSmokeDropdownList"],
      ),
      clutchDropdownList: parseStringList(json["clutchDropdownList"]),
      gearShiftDropdownList: parseStringList(json["gearShiftDropdownList"]),
      commentsOnEngineDropdownList: parseStringList(
        json["commentsOnEngineDropdownList"],
      ),
      commentsOnEngineOilDropdownList: parseStringList(
        json["commentsOnEngineOilDropdownList"],
      ),
      commentsOnTowingDropdownList: parseStringList(
        json["commentsOnTowingDropdownList"],
      ),
      commentsOnTransmissionDropdownList: parseStringList(
        json["commentsOnTransmissionDropdownList"],
      ),
      commentsOnRadiatorDropdownList: parseStringList(
        json["commentsOnRadiatorDropdownList"],
      ),
      commentsOnOthersDropdownList: parseStringList(
        json["commentsOnOthersDropdownList"],
      ),
      engineBayImages: parseStringList(json["engineBayImages"]),
      lhsApronImages: parseStringList(json["lhsApronImages"]),
      rhsApronImages: parseStringList(json["rhsApronImages"]),
      additionalEngineImages: parseStringList(json["additionalEngineImages"]),
      engineVideo: parseStringList(json["engineVideo"]),
      exhaustSmokeVideo: parseStringList(json["exhaustSmokeVideo"]),
      steeringDropdownList: parseStringList(json["steeringDropdownList"]),
      brakesDropdownList: parseStringList(json["brakesDropdownList"]),
      suspensionDropdownList: parseStringList(json["suspensionDropdownList"]),
      odometerReadingBeforeTestDrive:
          json["odometerReadingBeforeTestDrive"] ?? 0,
      rearWiperWasherDropdownList: parseStringList(
        json["rearWiperWasherDropdownList"],
      ),
      rearDefoggerDropdownList: parseStringList(
        json["rearDefoggerDropdownList"],
      ),
      infotainmentSystemDropdownList: parseStringList(
        json["infotainmentSystemDropdownList"],
      ),
      steeringMountedMediaControls:
          json["steeringMountedMediaControls"] ?? 'N/A',
      steeringMountedSystemControls:
          json["steeringMountedSystemControls"] ?? 'N/A',
      rhsFrontDoorFeaturesDropdownList: parseStringList(
        json["rhsFrontDoorFeaturesDropdownList"],
      ),
      lhsFrontDoorFeaturesDropdownList: parseStringList(
        json["lhsFrontDoorFeaturesDropdownList"],
      ),
      rhsRearDoorFeaturesDropdownList: parseStringList(
        json["rhsRearDoorFeaturesDropdownList"],
      ),
      lhsRearDoorFeaturesDropdownList: parseStringList(
        json["lhsRearDoorFeaturesDropdownList"],
      ),
      commentOnInteriorDropdownList: parseStringList(
        json["commentOnInteriorDropdownList"],
      ),
      driverAirbag: json["driverAirbag"] ?? 'N/A',
      coDriverAirbag: json["coDriverAirbag"] ?? 'N/A',
      coDriverSeatAirbag: json["coDriverSeatAirbag"] ?? 'N/A',
      lhsCurtainAirbag: json["lhsCurtainAirbag"] ?? 'N/A',
      lhsRearSideAirbag: json["lhsRearSideAirbag"] ?? 'N/A',
      driverSeatAirbag: json["driverSeatAirbag"] ?? 'N/A',
      rhsCurtainAirbag: json["rhsCurtainAirbag"] ?? 'N/A',
      rhsRearSideAirbag: json["rhsRearSideAirbag"] ?? 'N/A',
      sunroofDropdownList: parseStringList(json["sunroofDropdownList"]),
      seatsUpholstery: json["seatsUpholstery"] ?? 'N/A',
      meterConsoleWithEngineOnImages: parseStringList(
        json["meterConsoleWithEngineOnImages"],
      ),
      airbagImages: parseStringList(
        json["airbagImages"] ?? json["airbagimages"] ?? json["airbags"],
      ),
      frontSeatsFromDriverSideImages: parseStringList(
        json["frontSeatsFromDriverSideImages"],
      ),
      rearSeatsFromRightSideImages: parseStringList(
        json["rearSeatsFromRightSideImages"],
      ),
      dashboardImages: parseStringList(json["dashboardImages"]),
      reverseCameraDropdownList: parseStringList(
        json["reverseCameraDropdownList"],
      ),
      additionalInteriorImages: parseStringList(
        json["additionalInteriorImages"],
      ),
      acTypeDropdownList: json["acTypeDropdownList"] ?? 'N/A',
      acCoolingDropdownList: json["acCoolingDropdownList"] ?? 'N/A',
      chassisEmbossmentImages: parseStringList(json["chassisEmbossmentImages"]),
      chassisDetails: json["chassisDetails"] ?? 'N/A',
      vinPlateImages: parseStringList(json["vinPlateImages"]),
      vinPlateDetails: json["vinPlateDetails"] ?? 'N/A',
      roadTaxImages: parseStringList(json["roadTaxImages"]),
      seatingCapacity: json["seatingCapacity"] ?? 0,
      color: json["color"] ?? 'N/A',
      numberOfCylinders: json["numberOfCylinders"] ?? 0,
      norms: json["norms"] ?? 'N/A',
      hypothecatedTo: json["hypothecatedTo"] ?? 'N/A',
      insurer: json["insurer"] ?? 'N/A',
      pucImages: parseStringList(json["pucImages"]),
      pucValidity: parseMongoDbDate(json["pucValidity"]),
      pucNumber: json["pucNumber"] ?? 'N/A',
      rcStatus: json["rcStatus"] ?? 'N/A',
      blacklistStatus: json["blacklistStatus"] ?? 'N/A',
      rtoNocImages: parseStringList(json["rtoNocImages"]),
      rtoForm28Images: parseStringList(json["rtoForm28Images"]),
      frontWiperAndWasherDropdownList: parseStringList(
        json["frontWiperAndWasherDropdownList"],
      ),
      frontWiperAndWasherImages: parseStringList(
        json["frontWiperAndWasherImages"],
      ),
      lhsRearFogLampDropdownList: parseStringList(
        json["lhsRearFogLampDropdownList"],
      ),
      lhsRearFogLampImages: parseStringList(json["lhsRearFogLampImages"]),
      rhsRearFogLampDropdownList: parseStringList(
        json["rhsRearFogLampDropdownList"],
      ),
      rhsRearFogLampImages: parseStringList(json["rhsRearFogLampImages"]),
      rearWiperAndWasherImages: parseStringList(
        json["rearWiperAndWasherImages"],
      ),
      spareWheelDropdownList: parseStringList(json["spareWheelDropdownList"]),
      spareWheelImages: parseStringList(json["spareWheelImages"]),
      cowlTopImages: parseStringList(json["cowlTopImages"]),
      firewallImages: parseStringList(json["firewallImages"]),
      lhsSideMemberDropdownList: parseStringList(
        json["lhsSideMemberDropdownList"],
      ),
      rhsSideMemberDropdownList: parseStringList(
        json["rhsSideMemberDropdownList"],
      ),
      transmissionTypeDropdownList: parseStringList(
        json["transmissionTypeDropdownList"],
      ),
      driveTrainDropdownList: parseStringList(json["driveTrainDropdownList"]),
      commentsOnClusterMeterDropdownList: parseStringList(
        json["commentsOnClusterMeterDropdownList"],
      ),
      irvm: json["irvm"] ?? 'N/A',
      dashboardDropdownList: parseStringList(json["dashboardDropdownList"]),
      acImages: parseStringList(json["acImages"]),
      reverseCameraImages: parseStringList(json["reverseCameraImages"]),
      driverSideKneeAirbag: json["driverSideKneeAirbag"] ?? 'N/A',
      coDriverKneeSeatAirbag: json["coDriverKneeSeatAirbag"] ?? 'N/A',
      driverSeatDropdownList: parseStringList(json["driverSeatDropdownList"]),
      coDriverSeatDropdownList: parseStringList(
        json["coDriverSeatDropdownList"],
      ),
      frontCentreArmRestDropdownList: parseStringList(
        json["frontCentreArmRestDropdownList"],
      ),
      rearSeatsDropdownList: parseStringList(json["rearSeatsDropdownList"]),
      thirdRowSeatsDropdownList: parseStringList(
        json["thirdRowSeatsDropdownList"],
      ),
      odometerReadingAfterTestDriveImages: parseStringList(
        json["odometerReadingAfterTestDriveImages"],
      ),
      odometerReadingAfterTestDriveInKms:
          json["odometerReadingAfterTestDriveInKms"] ?? 0,
      version: json["version"] ?? json["appVersion"] ?? 'Unknown',
    );
  }

  /// Converts a nullable DateTime to a UTC ISO 8601 string.
  /// If the date is local (IST), it is converted to UTC before stringification.
  static String _dateToIstUtcIso(DateTime? dt) =>
      dt != null ? dt.toUtc().toIso8601String() : '';

  Map<String, dynamic> toJson() => {
    // "_id": id?.toJson(),
    "timestamp": _dateToIstUtcIso(timestamp),
    "emailAddress": emailAddress,
    "appointmentId": appointmentId,
    "city": city,
    // "registrationType": registrationType,
    "rcBookAvailability": rcBookAvailability,
    "rcCondition": rcCondition,
    "registrationNumber": registrationNumber,
    "registrationDate": _dateToIstUtcIso(registrationDate),
    "fitnessTill": _dateToIstUtcIso(fitnessTill),
    "toBeScrapped": toBeScrapped,
    "registrationState": registrationState,
    "registeredRto": registeredRto,
    "ownerSerialNumber": ownerSerialNumber,
    "make": make,
    "model": model,
    "variant": variant,
    "engineNumber": engineNumber,
    "chassisNumber": chassisNumber,
    "registeredOwner": registeredOwner,
    "registeredAddressAsPerRc": registeredAddressAsPerRc,
    "yearMonthOfManufacture": _dateToIstUtcIso(yearMonthOfManufacture),
    "fuelType": fuelType,
    "cubicCapacity": cubicCapacity,
    "hypothecationDetails": hypothecationDetails,
    "mismatchInRc": mismatchInRc,
    "roadTaxValidity": roadTaxValidity,
    "taxValidTill": _dateToIstUtcIso(taxValidTill),
    "insurance": insurance,
    "insurancePolicyNumber": insurancePolicyNumber,
    "insuranceValidity": _dateToIstUtcIso(insuranceValidity),
    "noClaimBonus": noClaimBonus,
    "mismatchInInsurance": mismatchInInsurance,
    "duplicateKey": duplicateKey,
    "rtoNoc": rtoNoc,
    "rtoForm28": rtoForm28,
    "partyPeshi": partyPeshi,
    "additionalDetails": additionalDetails,
    "rcTaxToken": rcTaxToken.map((x) => x).toList(),
    "insuranceCopy": insuranceCopy.map((x) => x).toList(),
    "bothKeys": bothKeys,
    "form26GdCopyIfRcIsLost": form26GdCopyIfRcIsLost,
    "bonnet": bonnet,
    "frontWindshield": frontWindshield,
    "roof": roof,
    "frontBumper": frontBumper,
    "lhsHeadlamp": lhsHeadlamp,
    "lhsFoglamp": lhsFoglamp,
    "rhsHeadlamp": rhsHeadlamp,
    "rhsFoglamp": rhsFoglamp,
    "lhsFender": lhsFender,
    "lhsOrvm": lhsOrvm,
    "lhsAPillar": lhsAPillar,
    "lhsBPillar": lhsBPillar,
    "lhsCPillar": lhsCPillar,
    "lhsFrontAlloy": lhsFrontAlloy,
    "lhsFrontTyre": lhsFrontTyre,
    "lhsRearAlloy": lhsRearAlloy,
    "lhsRearTyre": lhsRearTyre,
    "lhsFrontDoor": lhsFrontDoor,
    "lhsRearDoor": lhsRearDoor,
    "lhsRunningBorder": lhsRunningBorder,
    "lhsQuarterPanel": lhsQuarterPanel,
    "rearBumper": rearBumper,
    "lhsTailLamp": lhsTailLamp,
    "rhsTailLamp": rhsTailLamp,
    "rearWindshield": rearWindshield,
    "bootDoor": bootDoor,
    "spareTyre": spareTyre,
    "bootFloor": bootFloor,
    "rhsRearAlloy": rhsRearAlloy,
    "rhsRearTyre": rhsRearTyre,
    "rhsFrontAlloy": rhsFrontAlloy,
    "rhsFrontTyre": rhsFrontTyre,
    "rhsQuarterPanel": rhsQuarterPanel,
    "rhsAPillar": rhsAPillar,
    "rhsBPillar": rhsBPillar,
    "rhsCPillar": rhsCPillar,
    "rhsRunningBorder": rhsRunningBorder,
    "rhsRearDoor": rhsRearDoor,
    "rhsFrontDoor": rhsFrontDoor,
    "rhsOrvm": rhsOrvm,
    "rhsFender": rhsFender,
    "comments": comments,
    "frontMain": frontMain.map((x) => x).toList(),
    "bonnetImages": bonnetImages.map((x) => x).toList(),
    "frontWindshieldImages": frontWindshieldImages,
    "roofImages": roofImages,
    "frontBumperImages": frontBumperImages.map((x) => x).toList(),
    "lhsHeadlampImages": lhsHeadlampImages,
    "lhsFoglampImages": lhsFoglampImages,
    "rhsHeadlampImages": rhsHeadlampImages,
    "rhsFoglampImages": rhsFoglampImages,
    "lhsFront45Degree": lhsFront45Degree.map((x) => x).toList(),
    "lhsFenderImages": lhsFenderImages.map((x) => x).toList(),
    "lhsFrontAlloyImages": lhsFrontAlloyImages,
    "lhsFrontTyreImages": lhsFrontTyreImages.map((x) => x).toList(),
    "lhsRunningBorderImages": lhsRunningBorderImages.map((x) => x).toList(),
    "lhsOrvmImages": lhsOrvmImages,
    "lhsAPillarImages": lhsAPillarImages,
    "lhsFrontDoorImages": lhsFrontDoorImages.map((x) => x).toList(),
    "lhsBPillarImages": lhsBPillarImages,
    "lhsRearDoorImages": lhsRearDoorImages.map((x) => x).toList(),
    "lhsCPillarImages": lhsCPillarImages,
    "lhsRearTyreImages": lhsRearTyreImages.map((x) => x).toList(),
    "lhsRearAlloyImages": lhsRearAlloyImages,
    "lhsQuarterPanelImages": lhsQuarterPanelImages.map((x) => x).toList(),
    "rearMain": rearMain.map((x) => x).toList(),
    "rearWithBootDoorOpen": rearWithBootDoorOpenImages.isNotEmpty ? rearWithBootDoorOpenImages.first : 'N/A',
    "rearBumperImages": rearBumperImages.map((x) => x).toList(),
    "lhsTailLampImages": lhsTailLampImages,
    "rhsTailLampImages": rhsTailLampImages,
    "rearWindshieldImages": rearWindshieldImages,
    "spareTyreImages": spareTyreImages.map((x) => x).toList(),
    "bootFloorImages": bootFloorImages.map((x) => x).toList(),
    "rhsRear45Degree": rhsRear45Degree.map((x) => x).toList(),
    "rhsRearAlloyImages": rhsRearAlloyImages,
    "rhsRearTyreImages": rhsRearTyreImages,
    "rhsCPillarImages": rhsCPillarImages,
    "rhsRearDoorImages": rhsRearDoorImages.map((x) => x).toList(),
    "rhsBPillarImages": rhsBPillarImages,
    "rhsFrontDoorImages": rhsFrontDoorImages.map((x) => x).toList(),
    "rhsAPillarImages": rhsAPillarImages,
    "rhsRunningBorderImages": rhsRunningBorderImages.map((x) => x).toList(),
    "rhsFrontAlloyImages": rhsFrontAlloyImages,
    "rhsFrontTyreImages": rhsFrontTyreImages.map((x) => x).toList(),
    "rhsOrvmImages": rhsOrvmImages,
    "rhsFenderImages": rhsFenderImages.map((x) => x).toList(),
    "upperCrossMember": upperCrossMember,
    "radiatorSupport": radiatorSupport,
    "headlightSupport": headlightSupport,
    "lowerCrossMember": lowerCrossMember,
    "lhsApron": lhsApron,
    "rhsApron": rhsApron,
    "firewall": firewall,
    "cowlTop": cowlTop,
    "engine": engine,
    "battery": battery,
    "coolant": coolant,
    "engineOilLevelDipstick": engineOilLevelDipstick,
    "engineOil": engineOil,
    "engineMount": engineMount,
    "enginePermisableBlowBy": enginePermisableBlowBy,
    "exhaustSmoke": exhaustSmoke,
    "clutch": clutch,
    "gearShift": gearShift,
    "commentsOnEngine": commentsOnEngine,
    "commentsOnEngineOil": commentsOnEngineOil,
    "commentsOnTowing": commentsOnTowing,
    "commentsOnTransmission": commentsOnTransmission,
    "commentsOnRadiator": commentsOnRadiator,
    "commentsOnOthers": commentsOnOthers,
    "engineBay": engineBay.map((x) => x).toList(),
    "apronLhsRhs": apronLhsRhs.map((x) => x).toList(),
    "batteryImages": batteryImages.map((x) => x).toList(),
    "additionalImages": additionalImages,
    "engineSound": engineSound.map((x) => x).toList(),
    "exhaustSmokeImages": exhaustSmokeImages.map((x) => x).toList(),
    "steering": steering,
    "brakes": brakes,
    "suspension": suspension,
    "odometerReadingInKms": odometerReadingInKms,
    "fuelLevel": fuelLevel,
    "abs": abs,
    "electricals": electricals,
    "rearWiperWasher": rearWiperWasher,
    "rearDefogger": rearDefogger,
    "musicSystem": musicSystem,
    "stereo": stereo,
    "inbuiltSpeaker": inbuiltSpeaker,
    "externalSpeaker": externalSpeaker,
    "steeringMountedAudioControl": steeringMountedAudioControl,
    "noOfPowerWindows": noOfPowerWindows,
    "powerWindowConditionRhsFront": powerWindowConditionRhsFront,
    "powerWindowConditionLhsFront": powerWindowConditionLhsFront,
    "powerWindowConditionRhsRear": powerWindowConditionRhsRear,
    "powerWindowConditionLhsRear": powerWindowConditionLhsRear,
    "commentOnInterior": commentOnInterior,
    "noOfAirBags": noOfAirBags,
    "airbagFeaturesDriverSide": airbagFeaturesDriverSide,
    "airbagFeaturesCoDriverSide": airbagFeaturesCoDriverSide,
    "airbagFeaturesLhsAPillarCurtain": airbagFeaturesLhsAPillarCurtain,
    "airbagFeaturesLhsBPillarCurtain": airbagFeaturesLhsBPillarCurtain,
    "airbagFeaturesLhsCPillarCurtain": airbagFeaturesLhsCPillarCurtain,
    "airbagFeaturesRhsAPillarCurtain": airbagFeaturesRhsAPillarCurtain,
    "airbagFeaturesRhsBPillarCurtain": airbagFeaturesRhsBPillarCurtain,
    "airbagFeaturesRhsCPillarCurtain": airbagFeaturesRhsCPillarCurtain,
    "sunroof": sunroof,
    "leatherSeats": leatherSeats,
    "fabricSeats": fabricSeats,
    "commentsOnElectricals": commentsOnElectricals,
    "meterConsoleWithEngineOn": meterConsoleWithEngineOn.map((x) => x).toList(),
    "sunroofImages": sunroofImages,
    "frontSeatsFromDriverSideDoorOpen":
        frontSeatsFromDriverSideDoorOpen.map((x) => x).toList(),
    "rearSeatsFromRightSideDoorOpen":
        rearSeatsFromRightSideDoorOpen.map((x) => x).toList(),
    "dashboardFromRearSeat": dashboardFromRearSeat.map((x) => x).toList(),
    "reverseCamera": reverseCamera,
    "additionalImages2": additionalImages2,
    "airConditioningManual": airConditioningManual,
    "airConditioningClimateControl": airConditioningClimateControl,
    "commentsOnAC": commentsOnAc,
    "approvedBy": approvedBy,
    "approvalDate": _dateToIstUtcIso(approvalDate),
    "approvalTime": _dateToIstUtcIso(approvalTime),
    "approvalStatus": approvalStatus,
    "contactNumber": contactNumber,
    "newArrivalMessage": _dateToIstUtcIso(newArrivalMessage),
    "budgetCar": budgetCar,
    "status": status,
    "priceDiscovery": priceDiscovery,
    "priceDiscoveryBy": priceDiscoveryBy,
    "latlong": latlong,
    "retailAssociate": retailAssociate,
    "kmRangeLevel": kmRangeLevel,
    "highestBidder": highestBidder,
    "__v": v,

    // ✅ New fields all (nullable-safe)
    "ieName": ieName,
    "inspectionCity": inspectionCity,
    "inspectionDate": _dateToIstUtcIso(inspectionDate),
    "rcBookAvailabilityDropdownList":
        rcBookAvailabilityDropdownList.join(', '),
    "fitnessValidity": _dateToIstUtcIso(fitnessValidity),
    "yearAndMonthOfManufacture": _dateToIstUtcIso(yearAndMonthOfManufacture),
    "mismatchInRcDropdownList": mismatchInRcDropdownList.join(', '),
    "insuranceDropdownList": insuranceDropdownList.join(', '),
    "policyNumber": policyNumber,
    "mismatchInInsuranceDropdownList":
        mismatchInInsuranceDropdownList.join(', '),
    "additionalDetailsDropdownList":
        additionalDetailsDropdownList.join(', '),
    "rcTokenImages": rcTokenImages.map((x) => x).toList(),
    "insuranceImages": insuranceImages.map((x) => x).toList(),
    "duplicateKeyImages": duplicateKeyImages.map((x) => x).toList(),
    "form26AndGdCopyIfRcIsLostImages":
        form26AndGdCopyIfRcIsLostImages.map((x) => x).toList(),
    "bonnetDropdownList": bonnetDropdownList.join(', '),
    "frontWindshieldDropdownList":
        frontWindshieldDropdownList.join(', '),
    "roofDropdownList": roofDropdownList.join(', '),
    "frontBumperDropdownList": frontBumperDropdownList.join(', '),
    "lhsHeadlampDropdownList": lhsHeadlampDropdownList.join(', '),
    "lhsFoglampDropdownList": lhsFoglampDropdownList.join(', '),
    "rhsHeadlampDropdownList": rhsHeadlampDropdownList.join(', '),
    "rhsFoglampDropdownList": rhsFoglampDropdownList.join(', '),
    "lhsFenderDropdownList": lhsFenderDropdownList.join(', '),
    "lhsOrvmDropdownList": lhsOrvmDropdownList.join(', '),
    "lhsAPillarDropdownList": lhsAPillarDropdownList.join(', '),
    "lhsBPillarDropdownList": lhsBPillarDropdownList.join(', '),
    "lhsCPillarDropdownList": lhsCPillarDropdownList.join(', '),
    "lhsFrontWheelDropdownList":
        lhsFrontWheelDropdownList.join(', '),
    "lhsFrontTyreDropdownList": lhsFrontTyreDropdownList.join(', '),
    "lhsRearWheelDropdownList": lhsRearWheelDropdownList.join(', '),
    "lhsRearTyreDropdownList": lhsRearTyreDropdownList.join(', '),
    "lhsFrontDoorDropdownList": lhsFrontDoorDropdownList.join(', '),
    "lhsRearDoorDropdownList": lhsRearDoorDropdownList.join(', '),
    "lhsRunningBorderDropdownList":
        lhsRunningBorderDropdownList.join(', '),
    "lhsQuarterPanelDropdownList":
        lhsQuarterPanelDropdownList.join(', '),
    "rearBumperDropdownList": rearBumperDropdownList.join(', '),
    "lhsTailLampDropdownList": lhsTailLampDropdownList.join(', '),
    "rhsTailLampDropdownList": rhsTailLampDropdownList.join(', '),
    "rearWindshieldDropdownList":
        rearWindshieldDropdownList.join(', '),
    "bootDoorDropdownList": bootDoorDropdownList.join(', '),
    "spareTyreDropdownList": spareTyreDropdownList.join(', '),
    "bootFloorDropdownList": bootFloorDropdownList.join(', '),
    "rhsRearWheelDropdownList": rhsRearWheelDropdownList.join(', '),
    "rhsRearTyreDropdownList": rhsRearTyreDropdownList.join(', '),
    "rhsFrontWheelDropdownList":
        rhsFrontWheelDropdownList.join(', '),
    "rhsFrontTyreDropdownList": rhsFrontTyreDropdownList.join(', '),
    "rhsQuarterPanelDropdownList":
        rhsQuarterPanelDropdownList.join(', '),
    "rhsAPillarDropdownList": rhsAPillarDropdownList.join(', '),
    "rhsBPillarDropdownList": rhsBPillarDropdownList.join(', '),
    "rhsCPillarDropdownList": rhsCPillarDropdownList.join(', '),
    "rhsRunningBorderDropdownList":
        rhsRunningBorderDropdownList.join(', '),
    "rhsRearDoorDropdownList": rhsRearDoorDropdownList.join(', '),
    "rhsFrontDoorDropdownList": rhsFrontDoorDropdownList.join(', '),
    "rhsOrvmDropdownList": rhsOrvmDropdownList.join(', '),
    "rhsFenderDropdownList": rhsFenderDropdownList.join(', '),
    "commentsOnExteriorDropdownList":
        commentsOnExteriorDropdownList.join(', '),
    "frontMainImages": frontMainImages.map((x) => x).toList(),
    "bonnetClosedImages": bonnetClosedImages.map((x) => x).toList(),
    "bonnetOpenImages": bonnetOpenImages.map((x) => x).toList(),
    "frontBumperLhs45DegreeImages":
        frontBumperLhs45DegreeImages.map((x) => x).toList(),
    "frontBumperRhs45DegreeImages":
        frontBumperRhs45DegreeImages.map((x) => x).toList(),
    "lhsFullViewImages": lhsFullViewImages.map((x) => x).toList(),
    "lhsFrontWheelImages": lhsFrontWheelImages.map((x) => x).toList(),
    "lhsRearWheelImages": lhsRearWheelImages.map((x) => x).toList(),
    "lhsQuarterPanelWithRearDoorOpenImages":
        lhsQuarterPanelWithRearDoorOpenImages.map((x) => x).toList(),
    "lhsQuarterPanelWithRearDoorClosedImages":
        lhsQuarterPanelWithRearDoorClosedImages.map((x) => x).toList(),
    "rearMainImages": rearMainImages.map((x) => x).toList(),
    "rearWithBootDoorOpenImages":
        rearWithBootDoorOpenImages.map((x) => x).toList(),
    "bootDoorOpenImages":
        rearWithBootDoorOpenImages.map((x) => x).toList(),
    // "bootdoorimages": bootDoorImages.map((x) => x).toList(),
    "rearBumperLhs45DegreeImages":
        rearBumperLhs45DegreeImages.map((x) => x).toList(),
    "rearBumperRhs45DegreeImages":
        rearBumperRhs45DegreeImages.map((x) => x).toList(),
    "rhsFullViewImages": rhsFullViewImages.map((x) => x).toList(),
    "rhsQuarterPanelWithRearDoorOpenImages":
        rhsQuarterPanelWithRearDoorOpenImages.map((x) => x).toList(),
    "rhsQuarterPanelWithRearDoorClosedImages":
        rhsQuarterPanelWithRearDoorClosedImages.map((x) => x).toList(),
    "rhsQuarterPanelImages": rhsQuarterPanelImages.map((x) => x).toList(),
    "rhsRearWheelImages": rhsRearWheelImages.map((x) => x).toList(),
    "rhsFrontWheelImages": rhsFrontWheelImages.map((x) => x).toList(),
    "upperCrossMemberDropdownList":
        upperCrossMemberDropdownList.join(', '),
    "radiatorSupportDropdownList":
        radiatorSupportDropdownList.join(', '),
    "headlightSupportDropdownList":
        headlightSupportDropdownList.join(', '),
    "lowerCrossMemberDropdownList":
        lowerCrossMemberDropdownList.join(', '),
    "lhsApronDropdownList": lhsApronDropdownList.join(', '),
    "rhsApronDropdownList": rhsApronDropdownList.join(', '),
    "firewallDropdownList": firewallDropdownList.join(', '),
    "cowlTopDropdownList": cowlTopDropdownList.join(', '),
    "engineDropdownList": engineDropdownList.join(', '),
    "batteryDropdownList": batteryDropdownList.join(', '),
    "coolantDropdownList": coolantDropdownList.join(', '),
    "engineOilLevelDipstickDropdownList":
        engineOilLevelDipstickDropdownList.join(', '),
    "engineOilDropdownList": engineOilDropdownList.join(', '),
    "engineMountDropdownList": engineMountDropdownList.join(', '),
    "enginePermisableBlowByDropdownList":
        enginePermisableBlowByDropdownList.join(', '),
    "exhaustSmokeDropdownList": exhaustSmokeDropdownList.join(', '),
    "clutchDropdownList": clutchDropdownList.join(', '),
    "gearShiftDropdownList": gearShiftDropdownList.join(', '),
    "commentsOnEngineDropdownList":
        commentsOnEngineDropdownList.join(', '),
    "commentsOnEngineOilDropdownList":
        commentsOnEngineOilDropdownList.join(', '),
    "commentsOnTowingDropdownList":
        commentsOnTowingDropdownList.join(', '),
    "commentsOnTransmissionDropdownList":
        commentsOnTransmissionDropdownList.join(', '),
    "commentsOnRadiatorDropdownList":
        commentsOnRadiatorDropdownList.join(', '),
    "commentsOnOthersDropdownList":
        commentsOnOthersDropdownList.join(', '),
    "engineBayImages": engineBayImages.map((x) => x).toList(),
    "lhsApronImages": lhsApronImages.map((x) => x).toList(),
    "rhsApronImages": rhsApronImages.map((x) => x).toList(),
    "additionalEngineImages": additionalEngineImages.map((x) => x).toList(),
    "engineVideo": engineVideo.map((x) => x).toList(),
    "exhaustSmokeVideo": exhaustSmokeVideo.map((x) => x).toList(),
    "steeringDropdownList": steeringDropdownList.join(', '),
    "brakesDropdownList": brakesDropdownList.join(', '),
    "suspensionDropdownList": suspensionDropdownList.join(', '),
    "odometerReadingBeforeTestDrive": odometerReadingBeforeTestDrive,
    "rearWiperWasherDropdownList":
        rearWiperWasherDropdownList.join(', '),
    "rearDefoggerDropdownList": rearDefoggerDropdownList.join(', '),
    "infotainmentSystemDropdownList":
        infotainmentSystemDropdownList.join(', '),
    "steeringMountedMediaControls": steeringMountedMediaControls,
    "steeringMountedSystemControls": steeringMountedSystemControls,
    "rhsFrontDoorFeaturesDropdownList":
        rhsFrontDoorFeaturesDropdownList.join(', '),
    "lhsFrontDoorFeaturesDropdownList":
        lhsFrontDoorFeaturesDropdownList.join(', '),
    "rhsRearDoorFeaturesDropdownList":
        rhsRearDoorFeaturesDropdownList.join(', '),
    "lhsRearDoorFeaturesDropdownList":
        lhsRearDoorFeaturesDropdownList.join(', '),
    "commentOnInteriorDropdownList":
        commentOnInteriorDropdownList.join(', '),
    "driverAirbag": driverAirbag,
    "coDriverAirbag": coDriverAirbag,
    "coDriverSeatAirbag": coDriverSeatAirbag,
    "lhsCurtainAirbag": lhsCurtainAirbag,
    "lhsRearSideAirbag": lhsRearSideAirbag,
    "driverSeatAirbag": driverSeatAirbag,
    "rhsCurtainAirbag": rhsCurtainAirbag,
    "rhsRearSideAirbag": rhsRearSideAirbag,
    "sunroofDropdownList": sunroofDropdownList.join(', '),
    "seatsUpholstery": seatsUpholstery,
    "meterConsoleWithEngineOnImages":
        meterConsoleWithEngineOnImages.map((x) => x).toList(),
    "airbagImages": airbagImages.map((x) => x).toList(),
    "frontSeatsFromDriverSideImages":
        frontSeatsFromDriverSideImages.map((x) => x).toList(),
    "rearSeatsFromRightSideImages":
        rearSeatsFromRightSideImages.map((x) => x).toList(),
    "dashboardImages": dashboardImages.map((x) => x).toList(),
    "reverseCameraDropdownList":
        reverseCameraDropdownList.join(', '),
    "additionalInteriorImages": additionalInteriorImages.map((x) => x).toList(),
    "acTypeDropdownList": acTypeDropdownList,
    "acCoolingDropdownList": acCoolingDropdownList,
    "chassisEmbossmentImages": chassisEmbossmentImages.map((x) => x).toList(),
    "chassisDetails": chassisDetails,
    "vinPlateImages": vinPlateImages.map((x) => x).toList(),
    "vinPlateDetails": vinPlateDetails,
    "roadTaxImages": roadTaxImages.map((x) => x).toList(),
    "seatingCapacity": seatingCapacity,
    "color": color,
    "numberOfCylinders": numberOfCylinders,
    "norms": norms,
    "hypothecatedTo": hypothecatedTo,
    "insurer": insurer,
    "pucImages": pucImages.map((x) => x).toList(),
    "pucValidity": _dateToIstUtcIso(pucValidity),
    "pucNumber": pucNumber,
    "rcStatus": rcStatus,
    "blacklistStatus": blacklistStatus,
    "rtoNocImages": rtoNocImages.map((x) => x).toList(),
    "rtoForm28Images": rtoForm28Images.map((x) => x).toList(),
    "frontWiperAndWasherDropdownList":
        frontWiperAndWasherDropdownList.join(', '),
    "frontWiperAndWasherImages":
        frontWiperAndWasherImages.map((x) => x).toList(),
    "lhsRearFogLampDropdownList":
        lhsRearFogLampDropdownList.join(', '),
    "lhsRearFogLampImages": lhsRearFogLampImages.map((x) => x).toList(),
    "rhsRearFogLampDropdownList":
        rhsRearFogLampDropdownList.join(', '),
    "rhsRearFogLampImages": rhsRearFogLampImages.map((x) => x).toList(),
    "rearWiperAndWasherImages": rearWiperAndWasherImages.map((x) => x).toList(),
    "spareWheelDropdownList": spareWheelDropdownList.join(', '),
    "spareWheelImages": spareWheelImages.map((x) => x).toList(),
    "cowlTopImages": cowlTopImages.map((x) => x).toList(),
    "firewallImages": firewallImages.map((x) => x).toList(),
    "lhsSideMemberDropdownList":
        lhsSideMemberDropdownList.join(', '),
    "rhsSideMemberDropdownList":
        rhsSideMemberDropdownList.join(', '),
    "transmissionTypeDropdownList":
        transmissionTypeDropdownList.join(', '),
    "driveTrainDropdownList": driveTrainDropdownList.join(', '),
    "commentsOnClusterMeterDropdownList":
        commentsOnClusterMeterDropdownList.join(', '),
    "irvm": irvm,
    "dashboardDropdownList": dashboardDropdownList.join(', '),
    "acImages": acImages.map((x) => x).toList(),
    "reverseCameraImages": reverseCameraImages.map((x) => x).toList(),
    "driverSideKneeAirbag": driverSideKneeAirbag,
    "coDriverKneeSeatAirbag": coDriverKneeSeatAirbag,
    "driverSeatDropdownList": driverSeatDropdownList.join(', '),
    "coDriverSeatDropdownList": coDriverSeatDropdownList.join(', '),
    "frontCentreArmRestDropdownList":
        frontCentreArmRestDropdownList.join(', '),
    "rearSeatsDropdownList": rearSeatsDropdownList.join(', '),
    "thirdRowSeatsDropdownList":
        thirdRowSeatsDropdownList.join(', '),
    "odometerReadingAfterTestDriveImages":
        odometerReadingAfterTestDriveImages.map((x) => x).toList(),
    "odometerReadingAfterTestDriveInKms": odometerReadingAfterTestDriveInKms,
    "version": version,
    "appVersion": version,
    "attesterRawCarDetails": attesterRawCarDetails,
  };
}

DateTime? parseMongoDbDate(dynamic v) {
  try {
    if (v == null) return null;

    // 1) ISO string: "2025-08-11T10:50:00.000Z" or "+00:00" or no offset
    if (v is String) {
      // numeric string? treat as epoch ms
      final maybeNum = int.tryParse(v);
      if (maybeNum != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          maybeNum,
          isUtc: true,
        ).toLocal();
      }

      final dt = DateTime.parse(
        v,
      ); // Dart sets isUtc=true if Z or +/-offset present
      return dt.isUtc ? dt.toLocal() : dt; // normalize to local
    }

    // 2) Epoch milliseconds (int)
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();
    }

    // 3) Extended JSON: {"$date": "..."} or {"$date": 1723363800000} or {"$date":{"$numberLong":"..."}}
    if (v is Map) {
      final raw = v[r'$date'];
      if (raw == null) return null;

      if (raw is String) {
        // could be ISO or numeric string
        final maybeNum = int.tryParse(raw);
        if (maybeNum != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            maybeNum,
            isUtc: true,
          ).toLocal();
        }
        final dt = DateTime.parse(raw);
        return dt.isUtc ? dt.toLocal() : dt;
      }

      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true).toLocal();
      }

      if (raw is Map && raw[r'$numberLong'] != null) {
        final ms = int.tryParse(raw[r'$numberLong'].toString());
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
        }
      }
    }
  } catch (e) {
    // optional:  // debugPrint('parseMongoDbDate error: $e  (value: $v)');
  }
  return null;
}

// DateTime? parseMongoDbDate(dynamic dateJson) {
//   try {
//     if (dateJson == null) return null;

//     if (dateJson is String) {
//       return DateTime.tryParse(dateJson);
//     }

//     if (dateJson is Map<String, dynamic> && dateJson['\$date'] is String) {
//       return DateTime.tryParse(dateJson['\$date']);
//     }

//     if (dateJson is Map<String, dynamic> &&
//         dateJson['\$date'] is Map<String, dynamic>) {
//       final millisStr = dateJson['\$date']['\$numberLong'];
//       final millis = int.tryParse(millisStr ?? '');
//       return millis != null
//           ? DateTime.fromMillisecondsSinceEpoch(millis)
//           : null;
//     }
//   } catch (e) {
//     print('parseMongoDbDate error: $e');
//   }

//   return null;
// }

List<String> parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is String && value.trim().isNotEmpty) {
    if (value.contains(',')) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [value];
  }
  return [];
}
