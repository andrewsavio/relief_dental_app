import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:relief_dental_app/main.dart'; // For supabase
import 'dart:io' show Platform; // CRITICAL: For the platform check

class AppointmentBookingPage extends StatefulWidget {
  final String appointmentType;
  // --- ADDED OPTIONAL PARAMETERS FOR RESCHEDULING ---
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialReason;

  const AppointmentBookingPage({
    Key? key,
    required this.appointmentType,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
    this.initialReason,
  }) : super(key: key);
  // -------------------------------------------------

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // --- PRE-FILL LOGIC (New booking vs. Reschedule) ---
    if (widget.initialName != null) {
      // If initial data is provided (Reschedule), use it and stop loading
      _nameController.text = widget.initialName!;
      _emailController.text = widget.initialEmail!;
      _phoneController.text = widget.initialPhone!;
      _reasonController.text = widget.initialReason ?? '';
      _isLoading = false;
    } else {
      // If no initial data (New Booking), fetch the logged-in user's info
      _fetchPatientData();
    }
  }

  // Fetches user data from either the patient or doctor table
  Future<void> _fetchPatientData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    _emailController.text = user.email ?? '';

    // Check tables for profile name
    try {
      final patientData = await supabase
          .from('patients')
          .select('full_name')
          .eq('id', user.id)
          .single();
      _nameController.text = patientData['full_name'] ?? 'No name found';
    } catch (e) {
      // Check doctors table if not found in patients
      try {
        final doctorData = await supabase
            .from('doctors')
            .select('full_name')
            .eq('id', user.id)
            .single();
        _nameController.text = doctorData['full_name'] ?? 'No name found';
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error fetching profile data.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- SUBMIT APPOINTMENT FUNCTION ---
  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final String name = _nameController.text;
    final String reason = _reasonController.text;
    final DateTime appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      12, // Default time (Noon)
      0,
      0,
    );

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User is not logged in.');
      }

      // 1. Save to Supabase
      await supabase.from('appointments').insert({
        'patient_id': userId,
        'appointment_date': _selectedDate!.toIso8601String().split('T')[0],
        'reason': reason,
        'contact_name': name,
        'contact_email': _emailController.text,
        'contact_phone': _phoneController.text,
        'status': 'pending',
        'appointment_type': widget.appointmentType,
      });

      // 2. --- PLATFORM CHECK FOR CALENDAR ---
      const bool isMobile = bool.fromEnvironment(
        'dart.library.io',
        defaultValue: false,
      );

      if (isMobile) {
        final Event event = Event(
          title:
              '${widget.appointmentType == 'video-call' ? 'Telehealth' : 'In-Person'} Appointment: $reason',
          description: 'Appointment with Relief Dental Hospital.',
          location: 'Relief Dental Hospital (Check app for details)',
          startDate: appointmentDateTime,
          endDate: appointmentDateTime.add(const Duration(hours: 1)),
          iosParams: const IOSParams(reminder: Duration(minutes: 30)),
        );

        await Add2Calendar.addEvent2Cal(event);
      }
      // ------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Appointment requested! Please check your mobile calendar.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving appointment: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.appointmentType == 'video-call'
        ? 'Schedule Meeting'
        : 'Book Appointment';
    final IconData titleIcon = widget.appointmentType == 'video-call'
        ? Icons.videocam_outlined
        : Icons.calendar_month;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [Icon(titleIcon), SizedBox(width: 8), Text(title)],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your contact number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Appointment Reason',
                        hintText: 'e.g., Check-up, tooth pain, etc.',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please state a reason for your visit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: ListTile(
                        title: Text(
                          _selectedDate == null
                              ? 'Select Appointment Date'
                              : 'Date: ${_selectedDate!.toIso8601String().split('T')[0]}',
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _pickDate(context),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAppointment,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Request',
                              style: TextStyle(fontSize: 16),
                            ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFFA5D6A7) // Light green for dark mode
                            : Color(0xFF00796B), // Dark green for light mode
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors
                                  .black // Dark text for dark mode
                            : Colors.white, // Light text for light mode
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
