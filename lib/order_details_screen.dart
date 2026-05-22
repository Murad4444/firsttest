import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String garmentType;
  final String designDescription;
  final String color;
  final String customerNotes;
  final Map<String, dynamic> measurements;

  const OrderDetailsScreen({
    super.key,
    required this.garmentType,
    required this.designDescription,
    required this.color,
    required this.customerNotes,
    required this.measurements,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final TextEditingController _addressController = TextEditingController();
  String? _selectedCourierOption;

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _clientNameController.text = userDoc.data()?['username'] ?? '';
          _clientEmailController.text = user.email ?? userDoc.data()?['email'] ?? '';
        });
      } else {
        setState(() {
          _clientEmailController.text = user.email ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose(); // Теперь память очищается корректно!
    super.dispose();
  }

  Future<void> _submitOrderToFirestore() async {
    final String courierOption = _selectedCourierOption ?? "Не выбран";
    final String address = _addressController.text.trim();
    final String clientName = _clientNameController.text.trim();
    final String clientEmail = _clientEmailController.text.trim();
    final String clientNumber = _clientPhoneController.text.trim();

    if (courierOption == "Не выбран") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa kuryer seçimini edin.')),
      );
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa ünvanınızı daxil edin.')),
      );
      return;
    }
    if (clientName.isEmpty || clientEmail.isEmpty || clientNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa əlaqə məlumatlarınızı daxil edin.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xəta: İstifadəçi daxil olmayıb.')),
      );
      return;
    }

    try {
      CollectionReference customOrders = FirebaseFirestore.instance.collection('custom_orders');

      await customOrders.add({
        'userId': user.uid,
        'Materyal': widget.garmentType,
        'designDescription': widget.designDescription,
        'color': widget.color,
        'customerNotes': widget.customerNotes,
        'measurements': widget.measurements,
        'Novu': courierOption,
        'Address': address,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'Yeni Sifariş',
        'Müştəri': clientName,
        'Phone number': clientNumber,
        'clientEmail': clientEmail,
        'qiymət': 0.0,
      });

      print("Заказ успешно добавлен в Firestore!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sifarişiniz uğurla göndərildi!')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Ошибка при добавлении заказа в Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sifariş göndərilərkən xəта baş verdi: $e')),
      );
    }
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
      appBar: AppBar(title: const Text('Sifariş Detalları')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Sifarişiniz haqqında məlumat:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Paltar növü: ${widget.garmentType}', style: const TextStyle(fontSize: 16)),
            Text('Dizayn: ${widget.designDescription}', style: const TextStyle(fontSize: 16)),
            Text('Rəng: ${widget.color}', style: const TextStyle(fontSize: 16)),
            Text('Qeydlər: ${widget.customerNotes.isEmpty ? 'Yoxdur' : widget.customerNotes}', style: const TextStyle(fontSize: 16)),
            Text(
              'Ölçülər: ${widget.measurements.entries.map((e) => '${_getMeasurementLabel(e.key)}: ${e.value} sm').join(', ')}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text('Kuryer seçimi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: <Widget>[
                _buildCourierOptionButton('Kuryer'),
                _buildCourierOptionButton('Qəl-al'),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Əlaqə məlumatları:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: _clientNameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _clientEmailController,
              decoration: const InputDecoration(labelText: 'E-poçt', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _clientPhoneController,
              decoration: const InputDecoration(labelText: 'Nömrə', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone, // Изменено на ввод телефона!
            ),
            const SizedBox(height: 30),
            const Text('Ünvan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Tam ünvanınızı daxil edin', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitOrderToFirestore,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('Sifarişi təsdiqlə'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierOptionButton(String option) {
    return ChoiceChip(
      label: Text(option),
      selected: _selectedCourierOption == option,
      onSelected: (selected) {
        setState(() {
          _selectedCourierOption = selected ? option : null;
        });
      },
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: _selectedCourierOption == option ? Colors.blue[900] : Colors.black,
        fontWeight: _selectedCourierOption == option ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
