import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/futsal_provider.dart';
import '../../services/api_service.dart';
import 'dart:typed_data';
import '../../widgets/operating_hours_input.dart';

class AddFutsalScreen extends StatefulWidget {
  final Map<String, dynamic>? futsalToEdit;
  const AddFutsalScreen({super.key, this.futsalToEdit});

  @override
  State<AddFutsalScreen> createState() => _AddFutsalScreenState();
}

class _AddFutsalScreenState extends State<AddFutsalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isGettingLocation = false;

  // Operating Hours
  Map<String, dynamic> _operatingHours = {};

  // Images
  final List<XFile> _newImages = []; // newly picked images
  List<String> _existingImageUrls = []; // already uploaded URLs (edit mode)
  final ImagePicker _picker = ImagePicker();

  // Location
  double? _latitude;
  double? _longitude;
  bool _locationSet = false;

  @override
  void initState() {
    super.initState();
    if (widget.futsalToEdit != null) {
      _isEditing = true;
      _nameController.text = widget.futsalToEdit!['name'] ?? '';
      _descriptionController.text = widget.futsalToEdit!['description'] ?? '';
      _addressController.text = widget.futsalToEdit!['address'] ?? '';
      _existingImageUrls =
          List<String>.from(widget.futsalToEdit!['images'] ?? []);
      _latitude = widget.futsalToEdit!['latitude'];
      _longitude = widget.futsalToEdit!['longitude'];
      _locationSet = _latitude != null && _longitude != null;
      _operatingHours = Map<String, dynamic>.from(
          widget.futsalToEdit!['operatingHours'] ?? {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ============================================
  // PICK IMAGES
  // ============================================
  Future<void> _pickImages() async {
    final totalImages = _newImages.length + _existingImageUrls.length;
    if (totalImages >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    final remaining = 5 - totalImages;
    final picked = await _picker.pickMultiImage(limit: remaining);

    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked));
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  // ============================================
  // GET LOCATION
  // ============================================
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Enable in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationSet = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 Location set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // ============================================
  // SUBMIT FORM
  // ============================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Step 1: Upload new images if any
      List<String> uploadedUrls = [];
      if (_newImages.isNotEmpty) {
        uploadedUrls = await ApiService.uploadImages(_newImages);
        if (uploadedUrls.isEmpty && _newImages.isNotEmpty) {
          throw Exception('Image upload failed');
        }
      }

      // Step 2: Combine existing + newly uploaded URLs
      final allImageUrls = [..._existingImageUrls, ...uploadedUrls];

      // Step 3: Prepare futsal data
      final futsalData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'images': allImageUrls,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        'operatingHours': _operatingHours.isNotEmpty ? _operatingHours : null,
      };

      // Step 4: Create or update futsal
      final futsalProvider =
          Provider.of<FutsalProvider>(context, listen: false);
      late final Map<String, dynamic> response;

      if (_isEditing) {
        response = await futsalProvider.updateFutsal(
          widget.futsalToEdit!['id'],
          futsalData,
        );
      } else {
        response = await futsalProvider.createFutsal(futsalData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Operation completed'),
          backgroundColor:
              response['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );

      if (response['status'] == 'success') {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Futsal' : 'Add New Futsal'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // IMAGE PICKER SECTION
              _buildImageSection(),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Futsal Name *',
                  hintText: 'e.g., Green Field Futsal',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.sports_soccer),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter futsal name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell players about your futsal...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address *',
                  hintText: 'e.g., Lakeside, Pokhara',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter address'
                    : null,
              ),
              const SizedBox(height: 16),

              // LOCATION BUTTON
              _buildLocationButton(),
              const SizedBox(height: 16),

              // Operating Hours
              OperatingHoursInput(
                initialHours:
                    _operatingHours.isNotEmpty ? _operatingHours : null,
                onChanged: (hours) {
                  setState(() {
                    _operatingHours = hours;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Changes will be updated immediately.'
                            : 'Your futsal will need admin approval before players can see it.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              _isSubmitting
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Saving...'),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        _isEditing ? 'Update Futsal' : 'Add Futsal',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // IMAGE SECTION WIDGET
  // ============================================
  Widget _buildImageSection() {
    final totalImages = _existingImageUrls.length + _newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos ($totalImages/5)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (totalImages < 5)
              TextButton.icon(
                onPressed: _pickImages,
                icon:
                    const Icon(Icons.add_photo_alternate, color: Colors.green),
                label: const Text('Add Photos',
                    style: TextStyle(color: Colors.green)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (totalImages == 0)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Tap to add photos',
                      style: TextStyle(color: Colors.grey.shade500)),
                  Text('Up to 5 images',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing images (edit mode)
                ..._existingImageUrls.asMap().entries.map((entry) {
                  return _buildExistingImageTile(entry.key, entry.value);
                }),
                // New images
                ..._newImages.asMap().entries.map((entry) {
                  return _buildNewImageTile(entry.key, entry.value);
                }),
                // Add more button
                if (totalImages < 5)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(Icons.add,
                          color: Colors.grey.shade400, size: 32),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageTile(int index, String url) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: () => _removeExistingImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageTile(int index, XFile imageFile) {
    return Stack(
      children: [
        FutureBuilder<Uint8List>(
          future: imageFile.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                color: Colors.grey.shade200,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: MemoryImage(snapshot.data!),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: () => _removeNewImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // LOCATION BUTTON WIDGET
  // ============================================
  Widget _buildLocationButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _locationSet ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _locationSet ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _locationSet ? Icons.location_on : Icons.location_off,
            color: _locationSet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationSet ? 'Location Set ✅' : 'Location Not Set',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _locationSet
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                if (_locationSet)
                  Text(
                    '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                else
                  Text(
                    'Players can find your futsal nearby',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          _isGettingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _getCurrentLocation,
                  child: Text(
                    _locationSet ? 'Update' : 'Use GPS',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
        ],
      ),
    );
  }
}
