import 'package:bda_project/controller/chef_departement/validation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DepartmentValidationWorkflow extends StatelessWidget {
  const DepartmentValidationWorkflow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DepartmentValidationWorkflowController());

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
                      'Department Validation Workflow',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1a237e),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                          '${controller.departmentName.value} • Official exam schedule approval',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 32),


              // Main Content Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Schedule Summary
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildScheduleSummaryCard(controller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right: Actions & History
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildValidationActionsCard(controller),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Exam Schedule Preview
              _buildExamSchedulePreviewCard(controller),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildScheduleSummaryCard(
      DepartmentValidationWorkflowController controller) {
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
          Text(
            'Schedule Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.event_note,
                      label: 'Total Exams',
                      value: '${controller.totalExams.value}',
                      color: const Color(0xFF5C6BC0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.people,
                      label: 'Students',
                      value: '${controller.totalStudents.value}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.supervisor_account,
                      label: 'Professors',
                      value: '${controller.totalProfessors.value}',
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.meeting_room,
                      label: 'Rooms',
                      value: '${controller.totalRooms.value}',
                      color: Colors.orange,
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 24),
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.date_range,
                      label: 'Exam Period',
                      value: controller.examPeriod.value,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.warning_amber,
                      label: 'Conflicts',
                      value: '${controller.totalConflicts.value}',
                      color: controller.totalConflicts.value > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildValidationActionsCard(
      DepartmentValidationWorkflowController controller) {
    return Obx(() {
      final status = controller.validationStatus.value;
      final isPending = status == 'pending';

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
            Text(
              'Validation Actions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            if (isPending) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.showApprovalDialog(),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    'Approve Schedule',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.showRejectionDialog(),
                  icon: const Icon(Icons.cancel, size: 20),
                  label: Text(
                    'Reject with Comment',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status == 'approved'
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'approved'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: status == 'approved' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status == 'approved'
                            ? 'Schedule has been approved'
                            : 'Schedule has been rejected',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: status == 'approved'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 20),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildExamSchedulePreviewCard(
      DepartmentValidationWorkflowController controller) {
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
              Text(
                'Exam Schedule Preview',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton.icon(
                onPressed: () => controller.viewFullSchedule(),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  'View Full Schedule',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5C6BC0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.examSchedule.length,
                itemBuilder: (context, index) {
                  final exam = controller.examSchedule[index];
                  return _buildExamItem(exam);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildExamItem(Map<String, dynamic> exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  exam['day'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
                Text(
                  exam['month'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam['module'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      exam['time'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.meeting_room,
                        size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      exam['room'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${exam['students']} students',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              exam['supervisor'] as String,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}