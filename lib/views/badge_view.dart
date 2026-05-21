import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/badge_data.dart';
import '../utils/text_styles.dart';

class BadgeView extends StatelessWidget {
  final BadgeData badgeData;
  final VoidCallback onImageTap;
  final VoidCallback onNameTap;
  final VoidCallback onRoleTap;
  final VoidCallback onDepartmentTap;

  const BadgeView({
    super.key,
    required this.badgeData,
    required this.onImageTap,
    required this.onNameTap,
    required this.onRoleTap,
    required this.onDepartmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/CRACHA.png',
            width: 333.4,
            height: 523.19,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: 175,
          child: _buildPhotoSection(),
        ),
        Positioned(
          bottom: 17,
          child: _buildInfoSection(),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: onImageTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: badgeData.photo != null
              ? Image.memory(
                  badgeData.photo!,
                  width: 153,
                  height: 189,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/placeholder.png',
                  width: 153,
                  height: 189,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      width: 153,
                      height: 189,
                      child: Icon(Icons.person, size: 60, color: Colors.grey),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: 280,
      height: 135,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Spacer(),
          _buildTextSection(),
          const Spacer(),
          const Divider(
              color: Colors.black, thickness: 2, indent: 15, endIndent: 15),
          const Spacer(),
          _buildDepartmentText(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTextSection() {
    final bool isNameEmpty = badgeData.name.trim().isEmpty;
    final bool isRoleEmpty = badgeData.role.trim().isEmpty;

    return Flex(
      direction: Axis.vertical,
      spacing: 4,
      children: [
        GestureDetector(
          onTap: onNameTap,
          child: AutoSizeText(
            isNameEmpty ? 'NOME DO FUNCIONÁRIO' : badgeData.name,
            textScaleFactor: 0.9,
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 8,
            style: isNameEmpty
                ? AppTextStyles.nameStyle.copyWith(color: Colors.grey.shade400)
                : AppTextStyles.nameStyle,
          ),
        ),
        GestureDetector(
          onTap: onRoleTap,
          child: AutoSizeText(
            isRoleEmpty ? 'CARGO / FUNÇÃO' : badgeData.role,
            textScaleFactor: 0.9,
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 8,
            style: isRoleEmpty
                ? AppTextStyles.roleStyle.copyWith(color: Colors.grey.shade400)
                : AppTextStyles.roleStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentText() {
    final bool isDeptEmpty = badgeData.department.trim().isEmpty;

    return GestureDetector(
      onTap: onDepartmentTap,
      child: AutoSizeText(
        isDeptEmpty ? 'SECRETARIA / DEPARTAMENTO' : badgeData.department,
        textAlign: TextAlign.center,
        maxLines: 2,
        minFontSize: 8,
        style: isDeptEmpty
            ? AppTextStyles.departmentStyle.copyWith(color: Colors.grey.shade400)
            : AppTextStyles.departmentStyle,
      ),
    );
  }
}
