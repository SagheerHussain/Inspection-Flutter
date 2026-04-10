import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/api/api_service.dart';
import '../../../utils/constants/api_constants.dart';
import '../models/car_details_model.dart';

class CarDetailsController extends GetxController {
  final String appointmentId;

  CarDetailsController({required this.appointmentId});

  final Rxn<CarDetailsModel> carDetails = Rxn<CarDetailsModel>();
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final currentImageIndex = 0.obs;

  @override
  void onInit() {
    fetchCarDetails();
    super.onInit();
  }

  Future<void> fetchCarDetails() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await ApiService.get(
        ApiConstants.carDetailsUrl(appointmentId),
      );

      // TEMPORARY DEBUG RESPONSE VIEW
      debugPrint(const JsonEncoder.withIndent('  ').convert(response));

      final carData = response['carDetails'];

      if (carData != null) {
        carDetails.value = CarDetailsModel.fromJson(carData);
      } else {
        hasError.value = true;
        errorMessage.value = 'No car details found';
      }
    } catch (e) {
      debugPrint('❌ Error fetching car details: $e');
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await fetchCarDetails();
  }
}
