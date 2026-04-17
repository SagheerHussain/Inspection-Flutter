/// Model representing the full car inspection details from the API.
/// Maps to the `carDetails` object in the response from `car/details/{carId}`.
class CarDetailsModel {
  // ─── Identity ───
  final String id;
  final String appointmentId;
  final String registrationNumber;
  final String registrationDate;
  final String registrationState;
  final String registeredRto;
  final String registrationType;
  final String registeredOwner;
  final String registeredAddressAsPerRc;

  // ─── Vehicle Info ───
  final String make;
  final String model;
  final String variant;
  final String fuelType;
  final int cubicCapacity;
  final String color;
  final int numberOfCylinders;
  final String norms;
  final int odometerReadingInKms;
  final int ownerSerialNumber;
  final String yearMonthOfManufacture;
  final String engineNumber;
  final String chassisNumber;
  final String city;
  final String emailAddress;
  final String contactNumber;
  final String fuelLevel;
  final int seatingCapacity;

  // ─── Document Details ───
  final String rcBookAvailability;
  final String rcCondition;
  final String rcStatus;
  final String blacklistStatus;
  final String hypothecationDetails;
  final String hypothecatedTo;
  final String mismatchInRc;
  final String roadTaxValidity;
  final String insurance;
  final String insurancePolicyNumber;
  final String insuranceValidity;
  final String noClaimBonus;
  final String mismatchInInsurance;
  final String duplicateKey;
  final String rtoNoc;
  final String rtoForm28;
  final String partyPeshi;
  final String additionalDetails;
  final String pucNumber;
  final String pucValidity;
  final String fitnessTill;
  final String toBeScrapped;

  // ─── Exterior ───
  final String bonnet;
  final String frontWindshield;
  final String roof;
  final String frontBumper;
  final String lhsHeadlamp;
  final String lhsFoglamp;
  final String rhsHeadlamp;
  final String rhsFoglamp;
  final String lhsFender;
  final String lhsOrvm;
  final String lhsAPillar;
  final String lhsBPillar;
  final String lhsCPillar;
  final String lhsFrontAlloy;
  final String lhsFrontTyre;
  final String lhsRearAlloy;
  final String lhsRearTyre;
  final String lhsFrontDoor;
  final String lhsRearDoor;
  final String lhsRunningBorder;
  final String lhsQuarterPanel;
  final String rearBumper;
  final String lhsTailLamp;
  final String rhsTailLamp;
  final String rearWindshield;
  final String bootDoor;
  final String spareTyre;
  final String bootFloor;
  final String rhsRearAlloy;
  final String rhsRearTyre;
  final String rhsFrontAlloy;
  final String rhsFrontTyre;
  final String rhsQuarterPanel;
  final String rhsAPillar;
  final String rhsBPillar;
  final String rhsCPillar;
  final String rhsRunningBorder;
  final String rhsRearDoor;
  final String rhsFrontDoor;
  final String rhsOrvm;
  final String rhsFender;
  final String comments;

  // ─── Engine / Mechanical ───
  final String upperCrossMember;
  final String radiatorSupport;
  final String headlightSupport;
  final String lowerCrossMember;
  final String lhsApron;
  final String rhsApron;
  final String firewall;
  final String cowlTop;
  final String engine;
  final String battery;
  final String coolant;
  final String engineOilLevelDipstick;
  final String engineOil;
  final String engineMount;
  final String enginePermisableBlowBy;
  final String exhaustSmoke;
  final String clutch;
  final String gearShift;
  final String commentsOnEngine;
  final String commentsOnEngineOil;
  final String commentsOnTowing;
  final String commentsOnTransmission;
  final String commentsOnRadiator;
  final String commentsOnOthers;

  // ─── Interior / Electricals ───
  final String steering;
  final String brakes;
  final String suspension;
  final String abs;
  final String electricals;
  final String rearWiperWasher;
  final String rearDefogger;
  final String stereo;
  final String inbuiltSpeaker;
  final String externalSpeaker;
  final String steeringMountedAudioControl;
  final String noOfPowerWindows;
  final String powerWindowConditionRhsFront;
  final String powerWindowConditionLhsFront;
  final String powerWindowConditionRhsRear;
  final String powerWindowConditionLhsRear;
  final String commentOnInterior;
  final int noOfAirBags;
  final String airbagFeaturesDriverSide;
  final String airbagFeaturesCoDriverSide;
  final String sunroof;
  final String leatherSeats;
  final String fabricSeats;
  final String commentsOnElectricals;
  final String reverseCamera;
  final String airConditioningManual;
  final String airConditioningClimateControl;

  // ─── Approval / Auction ───
  final String approvedBy;
  final String approvalDate;
  final String approvalStatus;
  final String status;
  final int priceDiscovery;
  final String priceDiscoveryBy;
  final String latlong;
  final String retailAssociate;
  final int kmRangeLevel;
  final int highestBid;
  final String auctionStatus;
  final int oneClickPrice;
  final int otobuyOffer;
  final int soldAt;
  final String soldTo;
  final String reasonOfRemoval;
  final int customerExpectedPrice;
  final int fixedMargin;
  final int variableMargin;
  final String ieName;
  final String inspectionCity;
  final String budgetCar;
  final int odometerReadingAfterTestDriveInKms;
  final List<String> odometerReadingAfterTestDriveImages;
  final Map<String, dynamic> rawData; // Added for dynamic access

  // ─── Images ───
  final List<String> rcTaxToken;
  final List<String> insuranceCopy;
  final List<String> bothKeys;
  final List<String> form26GdCopyIfRcIsLost;
  final List<String> frontMain;
  final List<String> bonnetImages;
  final List<String> frontWindshieldImages;
  final List<String> roofImages;
  final List<String> frontBumperImages;
  final List<String> lhsHeadlampImages;
  final List<String> lhsFoglampImages;
  final List<String> rhsHeadlampImages;
  final List<String> lhsFront45Degree;
  final List<String> lhsFenderImages;
  final List<String> lhsFrontAlloyImages;
  final List<String> lhsFrontTyreImages;
  final List<String> lhsRunningBorderImages;
  final List<String> lhsOrvmImages;
  final List<String> lhsAPillarImages;
  final List<String> lhsFrontDoorImages;
  final List<String> lhsRearDoorImages;
  final List<String> lhsRearTyreImages;
  final List<String> lhsRearAlloyImages;
  final List<String> lhsQuarterPanelImages;
  final List<String> rearMain;
  final String rearWithBootDoorOpen;
  final List<String> rearBumperImages;
  final List<String> spareTyreImages;
  final List<String> bootFloorImages;
  final List<String> rhsRear45Degree;
  final List<String> rhsQuarterPanelImages;
  final List<String> rhsCPillarImages;
  final List<String> rhsRearDoorImages;
  final List<String> rhsBPillarImages;
  final List<String> rhsFrontDoorImages;
  final List<String> rhsAPillarImages;
  final List<String> rhsRunningBorderImages;
  final List<String> rhsFrontAlloyImages;
  final List<String> rhsFrontTyreImages;
  final List<String> rhsOrvmImages;
  final List<String> rhsFenderImages;
  final List<String> engineBay;
  final List<String> apronLhsRhs;
  final List<String> batteryImages;
  final List<String> additionalImages;
  final List<String> engineSound;
  final List<String> exhaustSmokeImages;
  final List<String> meterConsoleWithEngineOn;
  final List<String> airbagimages;
  final List<String> sunroofImages;
  final List<String> frontSeatsFromDriverSideDoorOpen;
  final List<String> rearSeatsFromRightSideDoorOpen;
  final List<String> dashboardFromRearSeat;
  final List<String> additionalImages2;
  final List<String> pucImages;
  final List<String> chassisEmbossmentImages;
  final List<String> vinPlateImages;
  final List<String> roadTaxImages;

  // ─── Timestamps ───
  final String createdAt;
  final String updatedAt;
  final String timestamp;

  CarDetailsModel({
    required this.id,
    required this.appointmentId,
    required this.registrationNumber,
    required this.registrationDate,
    required this.registrationState,
    required this.registeredRto,
    required this.registrationType,
    required this.registeredOwner,
    required this.registeredAddressAsPerRc,
    required this.make,
    required this.model,
    required this.variant,
    required this.fuelType,
    required this.cubicCapacity,
    required this.color,
    required this.numberOfCylinders,
    required this.norms,
    required this.odometerReadingInKms,
    required this.ownerSerialNumber,
    required this.yearMonthOfManufacture,
    required this.engineNumber,
    required this.chassisNumber,
    required this.city,
    required this.emailAddress,
    required this.contactNumber,
    required this.fuelLevel,
    required this.seatingCapacity,
    required this.rcBookAvailability,
    required this.rcCondition,
    required this.rcStatus,
    required this.blacklistStatus,
    required this.hypothecationDetails,
    required this.hypothecatedTo,
    required this.mismatchInRc,
    required this.roadTaxValidity,
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
    required this.pucNumber,
    required this.pucValidity,
    required this.fitnessTill,
    required this.toBeScrapped,
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
    required this.steering,
    required this.brakes,
    required this.suspension,
    required this.abs,
    required this.electricals,
    required this.rearWiperWasher,
    required this.rearDefogger,
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
    required this.sunroof,
    required this.leatherSeats,
    required this.fabricSeats,
    required this.commentsOnElectricals,
    required this.reverseCamera,
    required this.airConditioningManual,
    required this.airConditioningClimateControl,
    required this.approvedBy,
    required this.approvalDate,
    required this.approvalStatus,
    required this.status,
    required this.priceDiscovery,
    required this.priceDiscoveryBy,
    required this.latlong,
    required this.retailAssociate,
    required this.kmRangeLevel,
    required this.highestBid,
    required this.auctionStatus,
    required this.oneClickPrice,
    required this.otobuyOffer,
    required this.soldAt,
    required this.soldTo,
    required this.reasonOfRemoval,
    required this.customerExpectedPrice,
    required this.fixedMargin,
    required this.variableMargin,
    required this.ieName,
    required this.inspectionCity,
    required this.budgetCar,
    required this.rcTaxToken,
    required this.insuranceCopy,
    required this.bothKeys,
    required this.form26GdCopyIfRcIsLost,
    required this.frontMain,
    required this.bonnetImages,
    required this.frontWindshieldImages,
    required this.roofImages,
    required this.frontBumperImages,
    required this.lhsHeadlampImages,
    required this.lhsFoglampImages,
    required this.rhsHeadlampImages,
    required this.lhsFront45Degree,
    required this.lhsFenderImages,
    required this.lhsFrontAlloyImages,
    required this.lhsFrontTyreImages,
    required this.lhsRunningBorderImages,
    required this.lhsOrvmImages,
    required this.lhsAPillarImages,
    required this.lhsFrontDoorImages,
    required this.lhsRearDoorImages,
    required this.lhsRearTyreImages,
    required this.lhsRearAlloyImages,
    required this.lhsQuarterPanelImages,
    required this.rearMain,
    required this.rearWithBootDoorOpen,
    required this.rearBumperImages,
    required this.spareTyreImages,
    required this.bootFloorImages,
    required this.rhsRear45Degree,
    required this.rhsQuarterPanelImages,
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
    required this.engineBay,
    required this.apronLhsRhs,
    required this.batteryImages,
    required this.additionalImages,
    required this.engineSound,
    required this.exhaustSmokeImages,
    required this.meterConsoleWithEngineOn,
    required this.airbagimages,
    required this.sunroofImages,
    required this.frontSeatsFromDriverSideDoorOpen,
    required this.rearSeatsFromRightSideDoorOpen,
    required this.dashboardFromRearSeat,
    required this.additionalImages2,
    required this.pucImages,
    required this.chassisEmbossmentImages,
    required this.vinPlateImages,
    required this.roadTaxImages,
    required this.odometerReadingAfterTestDriveInKms,
    required this.odometerReadingAfterTestDriveImages,
    required this.createdAt,
    required this.updatedAt,
    required this.timestamp,
    required this.rawData,
  });

  factory CarDetailsModel.fromJson(Map<String, dynamic> json) {
    return CarDetailsModel(
      id: json['_id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      registrationDate: json['registrationDate'] ?? '',
      registrationState: json['registrationState'] ?? '',
      registeredRto: json['registeredRto'] ?? '',
      registrationType: json['registrationType'] ?? '',
      registeredOwner: json['registeredOwner'] ?? '',
      registeredAddressAsPerRc: json['registeredAddressAsPerRc'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      variant: json['variant'] ?? '',
      fuelType: json['fuelType'] ?? '',
      cubicCapacity: json['cubicCapacity'] ?? 0,
      color: json['color'] ?? '',
      numberOfCylinders: json['numberOfCylinders'] ?? 0,
      norms: json['norms'] ?? '',
      odometerReadingInKms: json['odometerReadingInKms'] ?? 0,
      ownerSerialNumber: json['ownerSerialNumber'] ?? 0,
      yearMonthOfManufacture: json['yearMonthOfManufacture'] ?? '',
      engineNumber: json['engineNumber'] ?? '',
      chassisNumber: json['chassisNumber'] ?? '',
      city: json['city'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      fuelLevel: json['fuelLevel'] ?? '',
      seatingCapacity: json['seatingCapacity'] ?? 0,
      rcBookAvailability: json['rcBookAvailability'] ?? '',
      rcCondition: json['rcCondition'] ?? '',
      rcStatus: json['rcStatus'] ?? '',
      blacklistStatus: json['blacklistStatus'] ?? '',
      hypothecationDetails: json['hypothecationDetails'] ?? '',
      hypothecatedTo: json['hypothecatedTo'] ?? '',
      mismatchInRc: json['mismatchInRc'] ?? '',
      roadTaxValidity: json['roadTaxValidity'] ?? '',
      insurance: json['insurance'] ?? '',
      insurancePolicyNumber: json['insurancePolicyNumber'] ?? '',
      insuranceValidity: json['insuranceValidity'] ?? '',
      noClaimBonus: json['noClaimBonus'] ?? '',
      mismatchInInsurance: json['mismatchInInsurance'] ?? '',
      duplicateKey: json['duplicateKey'] ?? '',
      rtoNoc: json['rtoNoc'] ?? '',
      rtoForm28: json['rtoForm28'] ?? '',
      partyPeshi: json['partyPeshi'] ?? '',
      additionalDetails: json['additionalDetails'] ?? '',
      pucNumber: json['pucNumber'] ?? '',
      pucValidity: _safeString(json['pucValidity']),
      fitnessTill: _safeString(json['fitnessTill']),
      toBeScrapped: json['toBeScrapped'] ?? '',
      bonnet: json['bonnet'] ?? '',
      frontWindshield: json['frontWindshield'] ?? '',
      roof: json['roof'] ?? '',
      frontBumper: json['frontBumper'] ?? '',
      lhsHeadlamp: json['lhsHeadlamp'] ?? '',
      lhsFoglamp: json['lhsFoglamp'] ?? '',
      rhsHeadlamp: json['rhsHeadlamp'] ?? '',
      rhsFoglamp: json['rhsFoglamp'] ?? '',
      lhsFender: json['lhsFender'] ?? '',
      lhsOrvm: json['lhsOrvm'] ?? '',
      lhsAPillar: json['lhsAPillar'] ?? '',
      lhsBPillar: json['lhsBPillar'] ?? '',
      lhsCPillar: json['lhsCPillar'] ?? '',
      lhsFrontAlloy: json['lhsFrontAlloy'] ?? '',
      lhsFrontTyre: json['lhsFrontTyre'] ?? '',
      lhsRearAlloy: json['lhsRearAlloy'] ?? '',
      lhsRearTyre: json['lhsRearTyre'] ?? '',
      lhsFrontDoor: json['lhsFrontDoor'] ?? '',
      lhsRearDoor: json['lhsRearDoor'] ?? '',
      lhsRunningBorder: json['lhsRunningBorder'] ?? '',
      lhsQuarterPanel: json['lhsQuarterPanel'] ?? '',
      rearBumper: json['rearBumper'] ?? '',
      lhsTailLamp: json['lhsTailLamp'] ?? '',
      rhsTailLamp: json['rhsTailLamp'] ?? '',
      rearWindshield: json['rearWindshield'] ?? '',
      bootDoor: json['bootDoor'] ?? '',
      spareTyre: json['spareTyre'] ?? '',
      bootFloor: json['bootFloor'] ?? '',
      rhsRearAlloy: json['rhsRearAlloy'] ?? '',
      rhsRearTyre: json['rhsRearTyre'] ?? '',
      rhsFrontAlloy: json['rhsFrontAlloy'] ?? '',
      rhsFrontTyre: json['rhsFrontTyre'] ?? '',
      rhsQuarterPanel: json['rhsQuarterPanel'] ?? '',
      rhsAPillar: json['rhsAPillar'] ?? '',
      rhsBPillar: json['rhsBPillar'] ?? '',
      rhsCPillar: json['rhsCPillar'] ?? '',
      rhsRunningBorder: json['rhsRunningBorder'] ?? '',
      rhsRearDoor: json['rhsRearDoor'] ?? '',
      rhsFrontDoor: json['rhsFrontDoor'] ?? '',
      rhsOrvm: json['rhsOrvm'] ?? '',
      rhsFender: json['rhsFender'] ?? '',
      comments: json['comments'] ?? '',
      upperCrossMember: json['upperCrossMember'] ?? '',
      radiatorSupport: json['radiatorSupport'] ?? '',
      headlightSupport: json['headlightSupport'] ?? '',
      lowerCrossMember: json['lowerCrossMember'] ?? '',
      lhsApron: json['lhsApron'] ?? '',
      rhsApron: json['rhsApron'] ?? '',
      firewall: json['firewall'] ?? '',
      cowlTop: json['cowlTop'] ?? '',
      engine: json['engine'] ?? '',
      battery: json['battery'] ?? '',
      coolant: json['coolant'] ?? '',
      engineOilLevelDipstick: json['engineOilLevelDipstick'] ?? '',
      engineOil: json['engineOil'] ?? '',
      engineMount: json['engineMount'] ?? '',
      enginePermisableBlowBy: json['enginePermisableBlowBy'] ?? '',
      exhaustSmoke: json['exhaustSmoke'] ?? '',
      clutch: json['clutch'] ?? '',
      gearShift: json['gearShift'] ?? '',
      commentsOnEngine: json['commentsOnEngine'] ?? '',
      commentsOnEngineOil: json['commentsOnEngineOil'] ?? '',
      commentsOnTowing: json['commentsOnTowing'] ?? '',
      commentsOnTransmission: json['commentsOnTransmission'] ?? '',
      commentsOnRadiator: json['commentsOnRadiator'] ?? '',
      commentsOnOthers: json['commentsOnOthers'] ?? '',
      steering: json['steering'] ?? '',
      brakes: json['brakes'] ?? '',
      suspension: json['suspension'] ?? '',
      abs: json['abs'] ?? '',
      electricals: json['electricals'] ?? '',
      rearWiperWasher: json['rearWiperWasher'] ?? '',
      rearDefogger: json['rearDefogger'] ?? '',
      stereo: json['stereo'] ?? '',
      inbuiltSpeaker: json['inbuiltSpeaker'] ?? '',
      externalSpeaker: json['externalSpeaker'] ?? '',
      steeringMountedAudioControl: json['steeringMountedAudioControl'] ?? '',
      noOfPowerWindows: json['noOfPowerWindows'] ?? '',
      powerWindowConditionRhsFront: json['powerWindowConditionRhsFront'] ?? '',
      powerWindowConditionLhsFront: json['powerWindowConditionLhsFront'] ?? '',
      powerWindowConditionRhsRear: json['powerWindowConditionRhsRear'] ?? '',
      powerWindowConditionLhsRear: json['powerWindowConditionLhsRear'] ?? '',
      commentOnInterior: json['commentOnInterior'] ?? '',
      noOfAirBags: json['noOfAirBags'] ?? 0,
      airbagFeaturesDriverSide: json['airbagFeaturesDriverSide'] ?? '',
      airbagFeaturesCoDriverSide: json['airbagFeaturesCoDriverSide'] ?? '',
      sunroof: json['sunroof'] ?? '',
      leatherSeats: json['leatherSeats'] ?? '',
      fabricSeats: json['fabricSeats'] ?? '',
      commentsOnElectricals: json['commentsOnElectricals'] ?? '',
      reverseCamera: json['reverseCamera'] ?? '',
      airConditioningManual: json['airConditioningManual'] ?? '',
      airConditioningClimateControl:
          json['airConditioningClimateControl'] ?? '',
      approvedBy: json['approvedBy'] ?? '',
      approvalDate: _safeString(json['approvalDate']),
      approvalStatus: json['approvalStatus'] ?? '',
      status: json['status'] ?? '',
      priceDiscovery: json['priceDiscovery'] ?? 0,
      priceDiscoveryBy: json['priceDiscoveryBy'] ?? '',
      latlong: json['latlong'] ?? '',
      retailAssociate: json['retailAssociate'] ?? '',
      kmRangeLevel: json['kmRangeLevel'] ?? 0,
      highestBid: json['highestBid'] ?? 0,
      auctionStatus: json['auctionStatus'] ?? '',
      oneClickPrice: json['oneClickPrice'] ?? 0,
      otobuyOffer: json['otobuyOffer'] ?? 0,
      soldAt: json['soldAt'] ?? 0,
      soldTo: json['soldTo'] ?? '',
      reasonOfRemoval: json['reasonOfRemoval'] ?? '',
      customerExpectedPrice: json['customerExpectedPrice'] ?? 0,
      fixedMargin: json['fixedMargin'] ?? 0,
      variableMargin: json['variableMargin'] ?? 0,
      ieName: json['ieName'] ?? '',
      inspectionCity: json['inspectionCity'] ?? '',
      budgetCar: json['budgetCar'] ?? '',
      rcTaxToken: _safeStringList(json['rcTaxToken']),
      insuranceCopy: _safeStringList(json['insuranceCopy']),
      bothKeys: _safeStringList(json['bothKeys']),
      form26GdCopyIfRcIsLost: _safeStringList(json['form26GdCopyIfRcIsLost']),
      frontMain: _safeStringList(json['frontMain']),
      bonnetImages: _safeStringList(json['bonnetImages']),
      frontWindshieldImages: _safeStringList(json['frontWindshieldImages']),
      roofImages: _safeStringList(json['roofImages']),
      frontBumperImages: _safeStringList(json['frontBumperImages']),
      lhsHeadlampImages: _safeStringList(json['lhsHeadlampImages']),
      lhsFoglampImages: _safeStringList(json['lhsFoglampImages']),
      rhsHeadlampImages: _safeStringList(json['rhsHeadlampImages']),
      lhsFront45Degree: _safeStringList(json['lhsFront45Degree']),
      lhsFenderImages: _safeStringList(json['lhsFenderImages']),
      lhsFrontAlloyImages: _safeStringList(json['lhsFrontAlloyImages']),
      lhsFrontTyreImages: _safeStringList(json['lhsFrontTyreImages']),
      lhsRunningBorderImages: _safeStringList(json['lhsRunningBorderImages']),
      lhsOrvmImages: _safeStringList(json['lhsOrvmImages']),
      lhsAPillarImages: _safeStringList(json['lhsAPillarImages']),
      lhsFrontDoorImages: _safeStringList(json['lhsFrontDoorImages']),
      lhsRearDoorImages: _safeStringList(json['lhsRearDoorImages']),
      lhsRearTyreImages: _safeStringList(json['lhsRearTyreImages']),
      lhsRearAlloyImages: _safeStringList(json['lhsRearAlloyImages']),
      lhsQuarterPanelImages: _safeStringList(json['lhsQuarterPanelImages']),
      rearMain: _safeStringList(json['rearMain']),
      rearWithBootDoorOpen:
          json['rearWithBootDoorOpen'] is String
              ? json['rearWithBootDoorOpen']
              : '',
      rearBumperImages: _safeStringList(json['rearBumperImages']),
      spareTyreImages: _safeStringList(json['spareTyreImages']),
      bootFloorImages: _safeStringList(json['bootFloorImages']),
      rhsRear45Degree: _safeStringList(json['rhsRear45Degree']),
      rhsQuarterPanelImages: _safeStringList(json['rhsQuarterPanelImages']),
      rhsCPillarImages: _safeStringList(json['rhsCPillarImages']),
      rhsRearDoorImages: _safeStringList(json['rhsRearDoorImages']),
      rhsBPillarImages: _safeStringList(json['rhsBPillarImages']),
      rhsFrontDoorImages: _safeStringList(json['rhsFrontDoorImages']),
      rhsAPillarImages: _safeStringList(json['rhsAPillarImages']),
      rhsRunningBorderImages: _safeStringList(json['rhsRunningBorderImages']),
      rhsFrontAlloyImages: _safeStringList(json['rhsFrontAlloyImages']),
      rhsFrontTyreImages: _safeStringList(json['rhsFrontTyreImages']),
      rhsOrvmImages: _safeStringList(json['rhsOrvmImages']),
      rhsFenderImages: _safeStringList(json['rhsFenderImages']),
      engineBay: _safeStringList(json['engineBay']),
      apronLhsRhs: _safeStringList(json['apronLhsRhs']),
      batteryImages: _safeStringList(json['batteryImages']),
      additionalImages: _safeStringList(json['additionalImages']),
      engineSound: _safeStringList(json['engineSound']),
      exhaustSmokeImages: _safeStringList(json['exhaustSmokeImages']),
      meterConsoleWithEngineOn: _safeStringList(
        json['meterConsoleWithEngineOn'],
      ),
      airbagimages: _safeStringList(
        json['airbagImages'] ?? json['airbagimages'] ?? json['airbags'],
      ),
      sunroofImages: _safeStringList(json['sunroofImages']),
      frontSeatsFromDriverSideDoorOpen: _safeStringList(
        json['frontSeatsFromDriverSideDoorOpen'],
      ),
      rearSeatsFromRightSideDoorOpen: _safeStringList(
        json['rearSeatsFromRightSideDoorOpen'],
      ),
      dashboardFromRearSeat: _safeStringList(json['dashboardFromRearSeat']),
      additionalImages2: _safeStringList(json['additionalImages2']),
      pucImages: _safeStringList(json['pucImages']),
      chassisEmbossmentImages: _safeStringList(json['chassisEmbossmentImages']),
      vinPlateImages: _safeStringList(json['vinPlateImages']),
      roadTaxImages: _safeStringList(json['roadTaxImages']),
      odometerReadingAfterTestDriveInKms: json['odometerReadingAfterTestDriveInKms'] ?? 
                                         json['odometerAfterTestDriveInKms'] ?? 0,
      odometerReadingAfterTestDriveImages: _safeStringList(
        json['odometerReadingAfterTestDriveImages'] ?? json['odometerAfterTestDriveImages']
      ),
      createdAt: _safeString(json['createdAt']),
      updatedAt: _safeString(json['updatedAt']),
      timestamp: _safeString(json['timestamp']),
      rawData: json,
    );
  }

  /// Dynamic helper to get a field's value (String, List<String>, etc)
  dynamic getFieldValue(String key) {
    // 1. Direct match (Highest Priority)
    if (rawData.containsKey(key)) return rawData[key];

    // 2. Try common suffixes used in different API versions
    final List<String> variations = [
      '${key}DropdownList',
      '${key}Dropdown',
      '${key}List',
      '${key}Value',
      '${key}Text',
      '${key}InKms',
      key.replaceAll('InKms', ''),
    ];
    
    for (var v in variations) {
      if (rawData.containsKey(v)) {
        final val = rawData[v];
        if (val is List && val.isNotEmpty) return val.join(', ');
        return val;
      }
    }

    // 3. Case-insensitive / alternate mapping scan
    final lowerKey = key.toLowerCase();
    for (var entry in rawData.entries) {
      final entryKey = entry.key.toLowerCase();
      if (entryKey == lowerKey) return entry.value;
      
      // Handle mapping like "engineVideo" -> "engineSound" if value matches
      if (lowerKey.contains('video') && entryKey.contains('sound')) return entry.value;
      if (lowerKey.contains('sound') && entryKey.contains('video')) return entry.value;
    }

    // 4. Known hard mappings (as fallbacks only)
    switch (key) {
      case 'transmissionType': return rawData['transmission'] ?? rawData['transmissionType'];
      case 'driveTrain': return rawData['drivetrain'] ?? rawData['driveTrain'];
      case 'acType': 
        final val = rawData['acType'] ?? rawData['acTypeDropdownList'];
        if (val != null && val.toString().isNotEmpty) return val;
        return airConditioningClimateControl.isNotEmpty ? 'Climate Control' : airConditioningManual;
      case 'acCooling': return rawData['acCooling'] ?? rawData['acCoolingDropdownList'];
    }

    return null;
  }

  /// Helper to get images/videos for a specific field key
  List<String> getFieldImages(String key) {
    // Priority 1: Direct key if it's already a list/string in rawData
    final directValue = rawData[key];
    if (directValue is List && directValue.isNotEmpty) return _safeStringList(directValue);
    if (directValue is String && directValue.startsWith('http')) return [directValue];

    // Priority 2: Try stripping/adding suffixes
    final String baseKey = key.replaceAll('Images', '').replaceAll('Video', '').replaceAll('VideoImages', '');
    final List<String> patterns = [
      '${baseKey}Images', 
      '${baseKey}Video', 
      '${baseKey}VideoImages',
      '${baseKey}Sound', // Handle engineVideo -> engineSound
      baseKey,
      key.replaceAll('Video', 'Sound'),
      key.replaceAll('Sound', 'Video'),
    ];

    for (var pattern in patterns) {
      if (pattern == key) continue; // Already checked direct match
      final val = rawData[pattern];
      if (val is List && val.isNotEmpty) return _safeStringList(val);
      if (val is String && val.startsWith('http')) return [val];
    }

    // Priority 3: Special case mappings
    if (key == 'bootDoorImages' || key == 'bootDoor') {
      final val = rawData['bootDoorImages'] ?? rawData['bootImages'] ?? rawData['rearWithBootDoorOpen'];
      if (val is List && val.isNotEmpty) return _safeStringList(val);
      if (val is String && val.isNotEmpty) return [val];
    }
    if (key == 'rcTokenImages' || key == 'rcBookAvailability') return rcTaxToken;
    if (key == 'chassisDetails') return chassisEmbossmentImages;
    if (key == 'vinPlateDetails') return vinPlateImages;
    if (key == 'insurance' || key == 'insuranceImages') return insuranceCopy;
    if (key == 'duplicateKey' || key == 'duplicateKeyImages') return bothKeys;
    if (key == 'engine' || key == 'engineBayImages') return engineBay;

    // Priority 4: Airbag mapping
    final airbagMapping = {
      'airbagImages': 0,
      'coDriverAirbagImages': 1,
      'driverSeatAirbagImages': 2, 'airbagImages2': 2,
      'coDriverSeatAirbagImages': 3, 'airbagImages3': 3,
      'rhsCurtainAirbagImages': 4, 'airbagImages4': 4,
      'lhsCurtainAirbagImages': 5, 'airbagImages5': 5,
      'driverKneeAirbagImages': 6, 'airbagImages6': 6,
      'coDriverKneeAirbagImages': 7, 'airbagImages7': 7,
      'rhsRearSideAirbagImages': 8, 'airbagImages8': 8,
      'lhsRearSideAirbagImages': 9, 'airbagImages9': 9,
    };

    if (airbagMapping.containsKey(key)) {
      final index = airbagMapping[key]!;
      if (index < airbagimages.length) return [airbagimages[index]];
    }

    return [];
  }

  /// Safe conversion of any value to string, handling nulls
  static String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Safe conversion of a dynamic list to a string list
  static List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  /// Full car name
  String get fullCarName => '$make $model $variant'.trim();

  /// All exterior images combined for gallery
  List<String> get allExteriorImages => [
    ...frontMain,
    ...bonnetImages,
    ...frontWindshieldImages,
    ...roofImages,
    ...frontBumperImages,
    ...lhsHeadlampImages,
    ...lhsFoglampImages,
    ...rhsHeadlampImages,
    ...lhsFront45Degree,
    ...lhsFenderImages,
    ...lhsFrontAlloyImages,
    ...lhsFrontTyreImages,
    ...lhsRunningBorderImages,
    ...lhsOrvmImages,
    ...lhsAPillarImages,
    ...lhsFrontDoorImages,
    ...lhsRearDoorImages,
    ...lhsRearTyreImages,
    ...lhsRearAlloyImages,
    ...lhsQuarterPanelImages,
    ...rearMain,
    if (rearWithBootDoorOpen.isNotEmpty) rearWithBootDoorOpen,
    ...rearBumperImages,
    ...spareTyreImages,
    ...bootFloorImages,
    ...rhsRear45Degree,
    ...rhsQuarterPanelImages,
    ...rhsCPillarImages,
    ...rhsRearDoorImages,
    ...rhsBPillarImages,
    ...rhsFrontDoorImages,
    ...rhsAPillarImages,
    ...rhsRunningBorderImages,
    ...rhsFrontAlloyImages,
    ...rhsFrontTyreImages,
    ...rhsOrvmImages,
    ...rhsFenderImages,
  ];

  /// All engine images
  List<String> get allEngineImages => [
    ...engineBay,
    ...apronLhsRhs,
    ...batteryImages,
    ...additionalImages,
  ];

  /// All interior images
  List<String> get allInteriorImages => [
    ...meterConsoleWithEngineOn,
    ...airbagimages,
    ...sunroofImages,
    ...frontSeatsFromDriverSideDoorOpen,
    ...rearSeatsFromRightSideDoorOpen,
    ...dashboardFromRearSeat,
    ...additionalImages2,
    ...odometerReadingAfterTestDriveImages,
  ];

  /// All document images
  List<String> get allDocumentImages => [
    ...rcTaxToken,
    ...insuranceCopy,
    ...bothKeys,
    ...form26GdCopyIfRcIsLost,
    ...pucImages,
    ...chassisEmbossmentImages,
    ...vinPlateImages,
    ...roadTaxImages,
  ];

  /// Get all images combined
  List<String> get allImages => [
    ...allExteriorImages,
    ...allEngineImages,
    ...allInteriorImages,
    ...allDocumentImages,
  ];
}
