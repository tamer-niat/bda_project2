import 'package:bda_project/controller/exam_admin/exam_dash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';


class ExamSchedulingDashboard extends StatelessWidget {
  const ExamSchedulingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExamSchedulingController());
    
    return Expanded(
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Obx(() {
          if (controller.isLoading.value && controller.departments.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Session Selector and Auto-refresh indicator
                  _buildHeader(controller),
                  const SizedBox(height: 32),

                  // Main Statistics Row
                  _buildMainStatsRow(controller),

                  const SizedBox(height: 24),

                  // Two Column Layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column - Status Overview
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildSchedulingProgressCard(controller),
                            const SizedBox(height: 24),
                            _buildConflictBreakdownCard(controller),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right Column - Recent Activities
                      Expanded(
                        flex: 2,
                        child: _buildRecentActivitiesCard(controller),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // Header with Session Selector and Auto-refresh indicator
  Widget _buildHeader(ExamSchedulingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam Scheduling Control Panel',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a237e),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Obx(() => Text(
                  'Readiness Score: ${controller.readinessScore.value}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                )),
                const SizedBox(width: 16),
                // Auto-refresh indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-refresh ON',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // Session Selector
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: controller.selectedSession.value,
            underline: const SizedBox(),
            items: controller.sessions.map((session) {
              return DropdownMenuItem(
                value: session,
                child: Text(
                  session,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.changeSession(value);
              }
            },
          ),
        )),
      ],
    );
  }

  // Main Statistics Row
  Widget _buildMainStatsRow(ExamSchedulingController controller) {
    return Obx(() => Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.event_available,
          label: 'Exams Generated',
          value: '${controller.totalExamsGenerated.value}',
          change: controller.totalExamsTarget.value > 0 
            ? '+${((controller.totalExamsGenerated.value / controller.totalExamsTarget.value) * 100).toStringAsFixed(0)}%'
            : '+0%',
          changeType: 'positive',
          subtitle: 'of ${controller.totalExamsTarget.value} total',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Remaining Conflicts',
          value: '${controller.remainingConflicts.value}',
          change: controller.criticalConflicts.value > 0 ? '-${controller.criticalConflicts.value}' : '0',
          changeType: controller.remainingConflicts.value > 0 ? 'negative' : 'positive',
          subtitle: '${controller.criticalConflicts.value} critical, ${controller.mediumConflicts.value} medium',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(
          icon: Icons.schedule,
          label: 'Pending Actions',
          value: '${controller.pendingActions.value}',
          change: controller.pendingActions.value > 0 ? '+${controller.pendingActions.value}' : '0',
          changeType: controller.pendingActions.value > 0 ? 'negative' : 'positive',
          subtitle: 'Require attention',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(
          icon: Icons.check_circle_outline,
          label: 'Completion Rate',
          value: '${controller.completionPercentage.toStringAsFixed(0)}%',
          change: '+${controller.completedDepartments}',
          changeType: 'positive',
          subtitle: 'Overall progress',
        )),
      ],
    ));
  }

  // Stat Card Widget
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String change,
    required String changeType,
    required String subtitle,
  }) {
    final isPositive = changeType == 'positive';
    
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF5C6BC0),
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1a237e),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Scheduling Progress Card
  Widget _buildSchedulingProgressCard(ExamSchedulingController controller) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheduling Progress by Department',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${controller.totalExamsGenerated.value} / ${controller.totalExamsTarget.value} Total',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (controller.departments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No department data available'),
              ),
            )
          else
            ...controller.departments.map((dept) {
              final name = dept['name'] ?? 'Unknown';
              final generated = dept['generated'] ?? 0;
              final total = dept['total'] ?? 1;
              final conflicts = dept['conflicts'] ?? 0;
              final percentage = total > 0 ? ((generated / total) * 100).toStringAsFixed(0) : '0';
              final status = dept['status'] ?? 'Pending';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(status),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusTextColor(status),
                                ),
                              ),
                            ),
                            if (conflicts > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 10,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$conflicts',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              '  $generated / $total',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: double.parse(percentage) / 100,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        conflicts > 0 ? Colors.orange : const Color(0xFF5C6BC0),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    ));
  }

  // Conflict Breakdown Card
  Widget _buildConflictBreakdownCard(ExamSchedulingController controller) {
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
          Text(
            'Conflict Analysis',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),

          // Conflict Type Breakdown
          _buildConflictRow(
            'Critical Conflicts',
            controller.criticalConflicts.value,
            Colors.red,
            'Require immediate action',
          ),
          const SizedBox(height: 12),
          _buildConflictRow(
            'Medium Conflicts',
            controller.mediumConflicts.value,
            Colors.orange,
            'Can be scheduled later',
          ),
          const SizedBox(height: 12),
          _buildConflictRow(
            'Low Conflicts',
            controller.lowConflicts.value,
            Colors.yellow.shade700,
            'Minor adjustments needed',
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Conflict by Type
          Text(
            'By Conflict Type',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          if (controller.conflictsByType.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No conflicts detected',
                      style: GoogleFonts.inter(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...controller.conflictsByType.map((conflict) {
              final name = conflict['name'] ?? 'Unknown';
              final count = conflict['count'] ?? 0;
              final icon = _getIconForConflictType(name);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildConflictTypeRow(name, count, icon),
              );
            }),
        ],
      ),
    ));
  }

  Widget _buildConflictRow(String label, int count, Color color, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConflictTypeRow(String label, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: count > 0 ? Colors.orange.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: count > 0 ? Colors.orange.shade700 : Colors.green.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // Recent Activities Card
  Widget _buildRecentActivitiesCard(ExamSchedulingController controller) {
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
          Text(
            'Recent Activities',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),
          
          if (controller.recentActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No recent activities'),
              ),
            )
          else
            ...controller.recentActivities.map((activity) {
              final action = activity['action'] ?? 'Unknown action';
              final department = activity['department'] ?? 'Unknown';
              final time = activity['time'] ?? 'Unknown time';
              final iconName = activity['icon'] ?? 'info';
              final colorName = activity['color'] ?? 'blue';
              
              return _buildActivityItem(
                action,
                department,
                time,
                _getIconFromName(iconName),
                _getColorFromName(colorName),
              );
            }),
        ],
      ),
    ));
  }

  Widget _buildActivityItem(
    String action,
    String department,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  department,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade50;
      case 'In Progress':
        return Colors.orange.shade50;
      case 'Pending':
        return Colors.grey.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade700;
      case 'In Progress':
        return Colors.orange.shade700;
      case 'Pending':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getIconForConflictType(String conflictType) {
    if (conflictType.toLowerCase().contains('student')) {
      return Icons.people;
    } else if (conflictType.toLowerCase().contains('teacher') || 
               conflictType.toLowerCase().contains('professor')) {
      return Icons.person;
    } else if (conflictType.toLowerCase().contains('room') || 
               conflictType.toLowerCase().contains('capacity')) {
      return Icons.meeting_room;
    } else if (conflictType.toLowerCase().contains('equipment')) {
      return Icons.devices;
    } else {
      return Icons.warning_amber_rounded;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'auto_fix_high':
        return Icons.auto_fix_high;
      case 'check_circle':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'tune':
        return Icons.tune;
      default:
        return Icons.info;
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}