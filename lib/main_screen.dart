import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _selectedClothingType;
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _designDescriptionController = TextEditingController();
  final TextEditingController _customerNotesController = TextEditingController();

  final Map<String, TextEditingController> _measurementControllers = {};
  List<String> _currentMeasurementFields = [];

  final Map<String, List<String>> _garmentMeasurements = {
    'T-şirt': ['chest', 'waist'],
    'Şalvar': ['waist', 'hips', 'inseam', 'legLength'],
    'Don': ['chest', 'waist', 'hips', 'length'],
    'Ətək': ['waist', 'hips', 'length'],
    'Uzun qol': ['chest', 'waist', 'sleeveLength', 'length'],
    'Şərf': ['length', 'width'],
  };

  @override
  void initState() {
    super.initState();
    _garmentMeasurements.values.expand((x) => x).toSet().forEach((measurementName) {
      _measurementControllers[measurementName] = TextEditingController();
    });
  }

  @override
  void dispose() {
    _colorController.dispose();
    _designDescriptionController.dispose();
    _customerNotesController.dispose();
    _measurementControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  String _formatMeasurementName(String name) {
    return name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]!.toLowerCase()}')
        .replaceFirst(name[0], name[0].toUpperCase());
  }

  String _getMeasurementLabel(String measurementName) {
    switch (measurementName) {
      case 'chest': return 'Sinə';
      case 'waist': return 'Bel';
      case 'hips': return 'Yanlar';
      case 'length': return 'Uzunluq';
      case 'sleeveLength': return 'Qol uzunluğu';
      case 'inseam': return 'Daxili tikiş';
      case 'legLength': return 'Ayaq uzunluğu';
      case 'width': return 'En';
      default: return measurementName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leylanın paltarları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Çıxış edildi!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Xoş gəlmisiniz!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text(
              'Zəhmət olmasa paltar növü seçin.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _garmentMeasurements.keys.map((String type) {
                return _buildClothingTypeButton(type);
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text(
              'Dizayn təsviri:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _designDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Məsələn: Üstündə zərlər olsun.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Rəng yazın',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Məsələn: Qırmızı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Müştəri Qeydləri:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customerNotesController,
              decoration: const InputDecoration(
                labelText: 'Əlavə istəklər (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            if (_selectedClothingType != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ölçülər:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  ..._currentMeasurementFields.map((measurementName) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _measurementControllers[measurementName],
                        decoration: InputDecoration(
                          labelText: '${_formatMeasurementName(measurementName)} (${_getMeasurementLabel(measurementName)}) (sm)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    );
                  }),
                ],
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (_selectedClothingType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zəhmət olmasa paltar növü seçin.')),
                  );
                  return;
                }
                if (_designDescriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zəhmət olmasa dizayn təsvirini daxil edin.')),
                  );
                  return;
                }
                if (_colorController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zəhmət olmasa rəngi daxil edin.')),
                  );
                  return;
                }

                Map<String, dynamic> measurementsData = {};
                for (String measurementName in _currentMeasurementFields) {
                  final controller = _measurementControllers[measurementName];
                  if (controller != null && controller.text.isNotEmpty) {
                    final value = double.tryParse(controller.text);
                    if (value != null) {
                      measurementsData[measurementName] = value;
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Zəhmət olmasa, "${_getMeasurementLabel(measurementName)}" üçün rəqəm daxil edin.')),
                      );
                      return;
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Zəhmət olmasa, "${_getMeasurementLabel(measurementName)}" üçün ölçü daxil edin.')),
                    );
                    return;
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailsScreen(
                      garmentType: _selectedClothingType!,
                      designDescription: _designDescriptionController.text.trim(),
                      color: _colorController.text.trim(),
                      customerNotes: _customerNotesController.text.trim(),
                      measurements: measurementsData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('Sifarişə davam et!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClothingTypeButton(String type) {
    return ChoiceChip(
      label: Text(type),
      selected: _selectedClothingType == type,
      onSelected: (selected) {
        setState(() {
          _selectedClothingType = selected ? type : null;
          for (var controller in _measurementControllers.values) {
            controller.clear();
          }
          _currentMeasurementFields = _garmentMeasurements[_selectedClothingType] ?? [];
        });
      },
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: _selectedClothingType == type ? Colors.blue[900] : Colors.black,
        fontWeight: _selectedClothingType == type ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
