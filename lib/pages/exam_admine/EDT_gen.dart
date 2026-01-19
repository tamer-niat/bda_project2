import 'package:bda_project/controller/exam_admin/exam_gen_con.dart';
import 'package:bda_project/pages/exam_admine/exam_viewer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AutomaticTimetableGenerationPage extends StatelessWidget {
  const AutomaticTimetableGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TimetableGenerationController());

    return Expanded(
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Exam Timetable Generation',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1a237e),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure and generate optimized exam schedules automatically',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Configuration
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildConfigurationCard(controller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column - Status & Actions
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildGenerateActionCard(controller),
                        const SizedBox(height: 24),
                        _buildExecutionStatusCard(controller),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Last Generation Results (if available)
              Obx(() {
                if (controller.lastGenerationResult.value != null) {
                  return _buildLastGenerationCard(controller);
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Configuration Card
  Widget _buildConfigurationCard(TimetableGenerationController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF5C6BC0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generation Configuration',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Semester Selection Only
          Text(
            'Semester',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
                children: controller.availableSemesters
                    .asMap()
                    .entries
                    .map((entry) {
                  final semester = entry.value;
                  final isSelected =
                      controller.selectedSemester.value == semester;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.selectedSemester.value = semester;
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          left: entry.key == 0 ? 0 : 8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5C6BC0)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF5C6BC0)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          semester,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Exam Period
          Text(
            'Exam Period',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildDateSelector(
                      label: 'Start Date',
                      date: controller.startDate.value,
                      onTap: () => controller.selectStartDate(),
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => _buildDateSelector(
                      label: 'End Date',
                      date: controller.endDate.value,
                      onTap: () => controller.selectEndDate(),
                    )),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Time Slots Configuration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Slots Configuration',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => controller.addTimeSlot(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Slot',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.timeSlots.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No time slots added yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Click "Add Slot" to create your first time slot',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: controller.timeSlots.asMap().entries.map((entry) {
                final index = entry.key;
                final slot = entry.value;
                return _buildTimeSlotItem(controller, index, slot);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // Time Slot Item with customization
  Widget _buildTimeSlotItem(
    TimetableGenerationController controller,
    int index,
    Map<String, dynamic> slot,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '${slot['start']} - ${slot['end']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: const Color(0xFF5C6BC0),
                    onPressed: () => _showEditTimeSlotDialog(controller, index, slot),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red.shade400,
                    onPressed: () => controller.removeTimeSlot(index),
                    tooltip: 'Remove',
                  ),
                  Checkbox(
                    value: slot['enabled'] as bool,
                    onChanged: (value) {
                      controller.toggleTimeSlot(index);
                    },
                    activeColor: const Color(0xFF5C6BC0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Edit Time Slot Dialog
  void _showEditTimeSlotDialog(
    TimetableGenerationController controller,
    int index,
    Map<String, dynamic> slot,
  ) {
    final labelController = TextEditingController(text: slot['label'] as String);
    final startController = TextEditingController(text: slot['start'] as String);
    final endController = TextEditingController(text: slot['end'] as String);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Time Slot',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        hintText: 'HH:MM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        hintText: 'HH:MM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      controller.updateTimeSlot(
                        index,
                        labelController.text,
                        startController.text,
                        endController.text,
                      );
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Date Selector Widget
  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: const Color(0xFF5C6BC0),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Generate Action Card
  Widget _buildGenerateActionCard(TimetableGenerationController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Actions',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Configuration Summary
          Obx(() {
            final summary = controller.getConfigurationSummary();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5C6BC0).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    icon: Icons.school,
                    label: 'Academic Year',
                    value: summary['academicYear'],
                    isAutoGenerated: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    icon: Icons.book,
                    label: 'Semester',
                    value: summary['semester'],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    icon: Icons.calendar_month,
                    label: 'Duration',
                    value: '${summary['examPeriod']['duration']} days',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    icon: Icons.schedule,
                    label: 'Time Slots',
                    value: '${summary['timeSlots']} enabled',
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Generate Button
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isGenerating.value || !controller.canGenerate
                      ? null
                      : () => controller.generateTimetable(),
                  icon: controller.isGenerating.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    controller.isGenerating.value
                        ? 'Generating...'
                        : !controller.canGenerate
                            ? 'Add Time Slots to Generate'
                            : 'Generate Timetable',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              )),

          const SizedBox(height: 12),

          // Reset Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => controller.resetConfiguration(),
              icon: const Icon(Icons.restart_alt, size: 20),
              label: Text(
                'Reset Configuration',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool isAutoGenerated = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5C6BC0)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (isAutoGenerated)
              Text(
                'auto',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Execution Status Card
  Widget _buildExecutionStatusCard(TimetableGenerationController controller) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(controller.executionStatus.value)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(controller.executionStatus.value),
                      color: _getStatusColor(controller.executionStatus.value),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(controller.executionStatus.value)
                      .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(controller.executionStatus.value)
                        .withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.executionStatus.value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(
                                controller.executionStatus.value),
                          ),
                        ),
                        Text(
                          '${(controller.progress.value * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: controller.progress.value,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(controller.executionStatus.value),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isGenerating.value) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'Generation Steps',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...controller.generationSteps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isCurrent = controller.currentStep.value == index;
                  final isCompleted = controller.currentStep.value > index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF5C6BC0).withOpacity(0.05)
                          : isCompleted
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF5C6BC0).withOpacity(0.3)
                            : isCompleted
                                ? Colors.green.shade200
                                : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isCurrent
                                  ? Icons.sync
                                  : Icons.circle_outlined,
                          size: 18,
                          color: isCompleted
                              ? Colors.green.shade600
                              : isCurrent
                                  ? const Color(0xFF5C6BC0)
                                  : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          step,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ));
  }

  // Last Generation Results Card
  Widget _buildLastGenerationCard(TimetableGenerationController controller) {
    final result = controller.lastGenerationResult.value!;
    
    // Helper to safely get values with fallback
    String safeGetValue(dynamic value, [String fallback = '0']) {
      if (value == null) return fallback;
      return value.toString();
    }
    
    int safeGetInt(dynamic value, [int fallback = 0]) {
      if (value == null) return fallback;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? fallback;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Last Generation Results',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Success',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildResultStat(
                  'Exams Scheduled',
                  safeGetValue(result['examsScheduled']),
                  Icons.event_available,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultStat(
                  'Formations',
                  safeGetValue(result['formationsAffected'], '-'),
                  Icons.school,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultStat(
                  'Days Used',
                  safeGetValue(result['daysUsed'], '-'),
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultStat(
                  'Conflicts',
                  safeGetValue(result['totalConflicts'], '0'),
                  Icons.warning,
                  safeGetInt(result['totalConflicts']) > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          
          // Show conflict breakdown if available
          if (safeGetInt(result['totalConflicts']) > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Conflict Breakdown',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildConflictBadge(
                        'Student',
                        safeGetInt(result['studentConflicts']),
                        Colors.red,
                      ),
                      _buildConflictBadge(
                        'Teacher',
                        safeGetInt(result['teacherConflicts']),
                        Colors.orange,
                      ),
                      _buildConflictBadge(
                        'Room',
                        safeGetInt(result['roomConflicts']),
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to schedule viewer
                    Get.to(() => ScheduleViewerScreen(
                      academicYear: controller.academicYear,
                      semester: controller.selectedSemester.value,
                    ));
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: Text(
                    'View Schedule',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Export action
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(
                    'Export Results',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5C6BC0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF5C6BC0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ready':
        return Colors.grey;
      case 'Generating...':
        return const Color(0xFF5C6BC0);
      case 'Success':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildConflictBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Ready':
        return Icons.schedule;
      case 'Generating...':
        return Icons.sync;
      case 'Success':
        return Icons.check_circle;
      case 'Failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}