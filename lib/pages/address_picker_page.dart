import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app/bindings/address_picker_binding.dart';
import '../app/controllers/address_picker_controller.dart';
import '../app/theme/app_colors.dart';

/// Halaman "Pilih Alamat" — dipakai saat navigasi langsung (route).
class AddressPickerPage extends StatelessWidget {
  const AddressPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(child: _AddressPickerContent()),
    );
  }
}

/// Bottom sheet version — dipakai dari location permission page.
class AddressPickerSheet extends StatelessWidget {
  const AddressPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    AddressPickerBinding().dependencies();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddressPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    return Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: screenHeight - statusBarHeight - 39,
        child: const _AddressPickerContent(),
      ),
    );
  }
}

class _AddressPickerContent extends StatelessWidget {
  const _AddressPickerContent();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddressPickerController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Pilih Alamat',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SearchField(controller: c),
        const SizedBox(height: 8),
        _MapPickTile(onTap: c.pickOnMap),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        Expanded(child: _ResultsList(controller: c)),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final AddressPickerController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onQueryChanged,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: 'Ketik jalan, perumahan, atau gedung',
          hintStyle: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          suffixIcon: Obx(
            () => controller.query.value.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    onPressed: controller.clearQuery,
                  ),
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _MapPickTile extends StatelessWidget {
  const _MapPickTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Image.asset('assets/images/map.png', width: 24, height: 24),
      title: Text(
        'Pilih lewat peta',
        style: GoogleFonts.poppins(
          color: AppColors.primary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.controller});
  final AddressPickerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE5E7EB),
          highlightColor: const Color(0xFFF9FAFB),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: 6,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 60, color: Color(0xFFF0F2F5)),
            itemBuilder: (_, _) => ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              title: Container(
                height: 14,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              ),
              subtitle: Container(
                height: 12,
                width: 160,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          ),
        );
      }

      if (controller.results.isEmpty) return const SizedBox.shrink();

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: controller.results.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 60, color: Color(0xFFF0F2F5)),
        itemBuilder: (context, index) {
          final address = controller.results[index];
          return ListTile(
            onTap: () => controller.selectAddress(address),
            leading: const Icon(Icons.location_on),
            title: Text(
              address.main,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF111827)),
            ),
            subtitle: address.detail.isEmpty
                ? null
                : Text(
                    address.detail,
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          );
        },
      );
    });
  }
}
