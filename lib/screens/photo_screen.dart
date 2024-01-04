import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/photo_controller.dart';
import 'package:flutter_app/model/photo.dart';
import 'package:flutter_app/screens/preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoCaptureView extends StatefulWidget {
  @override
  _PhotoCaptureViewState createState() => _PhotoCaptureViewState();
}

class _PhotoCaptureViewState extends State<PhotoCaptureView> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  late PhotoController _photoController;
  late AuthController _authController;
  late CameraController _cameraController;
  late Future<void> _cameraInitialization;
  File? _image;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _photoController = PhotoController();
    _initializeAuthController();
  }

  Future<void> _initializeAuthController() async {
    _authController = AuthController(await SharedPreferences.getInstance());
  }

  @override
  void dispose() {
    if (_cameraController.value.isInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Photo Capture')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image != null
                  ? _buildImagePreview()
                  : ElevatedButton(
                      onPressed: () async {
                        await _initializeCamera();
                        await _takePicture();
                      },
                      child: Text('Take Picture'),
                    ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_image == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please take a picture first.'),
                      ),
                    );
                    return;
                  } else {
                    _savePhoto();
                  }
                },
                child: const Text('Save Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Image.file(_image!, fit: BoxFit.cover),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _image = null;
            });
          },
          child: Text('Remove Photo'),
        ),
      ],
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await _cameraController.initialize();
    } else {
      print('No cameras available');
    }
  }

  Future<bool> _openPreviewScreen(File imageFile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewPhotoView(
          file: imageFile,
          cameraController: _cameraController,
        ),
      ),
    );

    return result == true;
  }

  Future<void> _takePicture() async {
    String? userId = await _authController.getUserId();

    if (userId != null) {
      final XFile image = await _cameraController.takePicture();

      setState(() {
        _image = File(image.path);
        _openPreviewScreen(_image!);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save photo. User ID is null.'),
        ),
      );
    }
  }

  Future<void> _savePhoto() async {
    if (_image != null) {
      String? userId = await _authController.getUserId();

      if (userId != null) {
        var photo = Photo(
          id: '',
          name: nameController.text,
          description: descriptionController.text,
          rating: 0,
          imagePath: File(_image!.path).path,
          latitude: 0.0, //  latitude real
          longitude: 0.0, // longitude real
          timestamp: DateTime.now(),
        );

        await _authController.savePhoto(photo);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved successfully!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save photo. User ID is null.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a picture first.'),
        ),
      );
    }
  }
}
