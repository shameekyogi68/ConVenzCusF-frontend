import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/secondary_button.dart';
import 'vendor_not_found_screen.dart';

class VendorSearchScreen extends StatefulWidget {
  final String bookingId;
  final String serviceName;
  
  const VendorSearchScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
  });

  @override
  State<VendorSearchScreen> createState() => _VendorSearchScreenState();
}

class _VendorSearchScreenState extends State<VendorSearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double progress = 0.0;
  Timer? _progressTimer;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          progress += 0.0016; // Progress over 60 seconds
          if (progress >= 1.0) {
            timer.cancel();
          }
        });
      }
    });

    // Navigate to vendor not found after 1 minute (60 seconds)
    _navigationTimer = Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VendorNotFoundScreen(
              bookingId: widget.bookingId,
              serviceName: widget.serviceName,
            ),
          ),
        );
      }
    }) as Timer?;
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌊 Waves animation with avatar
            SizedBox(
              width: 380,
              height: 380,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated waves
                      ...List.generate(3, (i) {
                        final value = (_controller.value + i * 0.33) % 1;
                        return Container(
                          width: 200 + (value * 280),
                          height: 200 + (value * 280),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryTeal.withOpacity(
                              (1 - value * 1.4).clamp(0.0, 0.25),
                            ),
                          ),
                        );
                      }),

                      // 📷 Center Avatar
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryTeal.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/images/avatar.png",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primaryTeal.withOpacity(0.1),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primaryTeal,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Searching for Vendor...",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Looking for ${widget.serviceName} vendor near you",
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              "Booking ID: #${widget.bookingId.substring(widget.bookingId.length > 8 ? widget.bookingId.length - 8 : 0)}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 30),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 18,
                  backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SecondaryButton(
                text: "Cancel Search",
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
