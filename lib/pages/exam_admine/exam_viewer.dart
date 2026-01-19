import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ScheduleViewerScreen extends StatefulWidget {
  final String academicYear;
  final String semester;

  const ScheduleViewerScreen({
    Key? key,
    required this.academicYear,
    required this.semester,
  }) : super(key: key);

  @override
  State<ScheduleViewerScreen> createState() => _ScheduleViewerScreenState();
}

class _ScheduleViewerScreenState extends State<ScheduleViewerScreen> {
  bool _isLoading = true;
  List<dynamic> _schedules = [];
  List<dynamic> _allSchedules = []; // Store all schedules
  Map<String, List<dynamic>> _groupedByDate = {};
  List<String> _formations = []; // Changed from Set to List
  String? _selectedFormation; // Current filter
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get ALL exam details for this year/semester
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/exams/all?annee=${widget.academicYear}&semester=${widget.semester}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final allExams = data['exams'] ?? [];
          
          // Extract unique formations WITHOUT using Set
          final List<String> formations = [];
          for (var exam in allExams) {
            final formation = exam['formation']?.toString() ?? 'Unknown';
            if (!formations.contains(formation)) {
              formations.add(formation);
            }
          }
          
          setState(() {
            _allSchedules = allExams;
            _formations = formations;
            _selectedFormation = null; // Show all by default
            _applyFilter();
            _isLoading = false;
          });
          
          if (_allSchedules.isEmpty) {
            setState(() {
              _errorMessage = 'No exams found for ${widget.academicYear} ${widget.semester}.\nGenerate a schedule first!';
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load exams');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load exams');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading schedule:\n$e\n\nMake sure:\n1. Backend is running\n2. Schedule has been generated';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFormation == null) {
      _schedules = List.from(_allSchedules);
    } else {
      _schedules = _allSchedules
          .where((exam) => exam['formation'] == _selectedFormation)
          .toList();
    }
    _groupByDate();
  }

  void _groupByDate() {
    _groupedByDate.clear();
    for (var exam in _schedules) {
      final date = exam['date_exam'] ?? 'Unknown';
      if (!_groupedByDate.containsKey(date)) {
        _groupedByDate[date] = [];
      }
      _groupedByDate[date]!.add(exam);
    }
    
    // Sort by time within each date
    _groupedByDate.forEach((date, exams) {
      exams.sort((a, b) {
        final timeA = a['heure_debut'] ?? '';
        final timeB = b['heure_debut'] ?? '';
        return timeA.compareTo(timeB);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Viewer',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.academicYear} - ${widget.semester}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Export to PDF/Excel
              Get.snackbar('Export', 'Export functionality coming soon');
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading schedule...',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6BC0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No exams scheduled',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _groupedByDate.length,
            itemBuilder: (context, index) {
              final date = _groupedByDate.keys.toList()[index];
              final exams = _groupedByDate[date]!;
              return _buildDateSection(date, exams);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar() {
    final totalExams = _schedules.length;
    final totalDays = _groupedByDate.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Formation Filter
          if (_formations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Formation:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String?>(
                      value: _selectedFormation,
                      isExpanded: true,
                      underline: Container(),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Formations (${_allSchedules.length})',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                        ..._formations.map((formation) {
                          final count = _allSchedules
                              .where((e) => e['formation'] == formation)
                              .length;
                          return DropdownMenuItem<String?>(
                            value: formation,
                            child: Text(
                              '$formation ($count)',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFormation = value;
                          _applyFilter();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(Icons.event, 'Entries', totalExams.toString(), Colors.blue),
              _buildSummaryItem(Icons.calendar_month, 'Days', totalDays.toString(), Colors.green),
              _buildSummaryItem(Icons.school, 'Formations', _formations.length.toString(), Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
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
        ),
      ],
    );
  }

  Widget _buildDateSection(String date, List<dynamic> exams) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (e) {
      // Invalid date
    }

    final formattedDate = parsedDate != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(parsedDate)
        : date;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${exams.length} exams',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...exams.map((exam) => _buildExamCard(exam)).toList(),
        ],
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time, Duration, and Department Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      exam['heure_debut'] ?? 'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (exam['duree_minutes'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${exam['duree_minutes']} min',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              const Spacer(),
              if (exam['department'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    exam['department'],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Subject Name
          Text(
            exam['matiere'] ?? 'Unknown Subject',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          
          // Subject Code
          if (exam['matiere_code'] != null) ...[
            const SizedBox(height: 4),
            Text(
              exam['matiere_code'],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Formation, Niveau, and Group
          Row(
            children: [
              if (exam['formation'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school, size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        exam['formation'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              if (exam['niveau'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    exam['niveau'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              if (exam['groupe'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    exam['groupe'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Room
          if (exam['salle'] != null && exam['salle'].toString().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.meeting_room, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exam['salle'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (exam['salle_capacite'] != null)
                    Text(
                      '(${exam['salle_capacite']} seats)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Supervisor
          if (exam['surveillant'] != null && exam['surveillant'].toString().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.indigo.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exam['surveillant'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.indigo.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}