import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/datetime_picker.dart';
import '../../../widgets/text_input.dart';
import 'vendor_search.dart'; // ✅ Import Vendor Search Screen

class ServiceDetailsScreen extends StatefulWidget {
  final String address;

  const ServiceDetailsScreen({super.key, required this.address});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _descriptionController = TextEditingController();

  // Note: _isLoading removed as we navigate immediately

  void _searchVendors() {   // 🔥 Corrected method name
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both Date and Time"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VendorSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Service Details", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.03),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Service Location",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              const Text(
                "When do you need the service?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              CustomDatePicker(
                label: "Select Date",
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),

              CustomTimePicker(
                label: "Select Time",
                selectedTime: _selectedTime,
                onTimeSelected: (time) {
                  setState(() => _selectedTime = time);
                },
              ),

              SizedBox(height: screenHeight * 0.04),

              const Text(
                "Job Description:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextInput(
                controller: _descriptionController,
                labelText: "Describe the issue...",
                icon: Icons.description_outlined,
                maxLines: 4,
              ),

              SizedBox(height: screenHeight * 0.05),

              PrimaryButton(
                text: "Search vendors",
                onPressed: _searchVendors, // 🔥 Correct call
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
