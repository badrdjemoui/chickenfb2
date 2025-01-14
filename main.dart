import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لإدارة التاريخ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المزرعة',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: ChickenForm(),
    );
  }
}

class ChickenForm extends StatefulWidget {
  @override
  _ChickenFormState createState() => _ChickenFormState();
}

class _ChickenFormState extends State<ChickenForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _chickenCountController = TextEditingController();
  final TextEditingController _totalWeightController = TextEditingController();
  final TextEditingController _pricePerKgController = TextEditingController();
  String? _selectedFarmer;
  List<String> _farmers = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // تعيين تاريخ اليوم
    _loadFarmers();
  }

  // تحميل قائمة المربيين مع التحديث التلقائي
  Future<void> _loadFarmers() async {
    FirebaseFirestore.instance.collection('farmers').snapshots().listen((snapshot) {
      setState(() {
        _farmers = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

void _addFarmerDialog(BuildContext context) {
  TextEditingController farmerNameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('إضافة مربي جديد'),
        content: TextField(
          controller: farmerNameController,
          decoration: InputDecoration(
            labelText: 'اسم المربي',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('إضافة'),
            onPressed: () {
              String farmerName = farmerNameController.text.trim();
              if (farmerName.isNotEmpty) {
                FirebaseFirestore.instance.collection('farmers').add({
                  'name': farmerName,
                }).then((value) {
                  setState(() {
                    _selectedFarmer = null; // إعادة تعيين القيمة
                    _loadFarmers(); // تحديث القائمة
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تمت إضافة المربي بنجاح')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء الإضافة')),
                  );
                });
              }
            },
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة مزرعة الدجاج'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addFarmerDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedFarmer,
                hint: Text('اختر اسم المربي'),
                items: _farmers
                    .map((farmer) => DropdownMenuItem(
                          value: farmer,
                          child: Text(farmer),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFarmer = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'من فضلك اختر اسم المربي';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'اسم المربي',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'التاريخ',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // لجعل الحقل للقراءة فقط
                onTap: () => _selectDate(context), // عرض أداة اختيار التاريخ عند الضغط
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل التاريخ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _chickenCountController,
                decoration: InputDecoration(
                  labelText: 'عدد الدجاج',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل عدد الدجاج';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _totalWeightController,
                decoration: InputDecoration(
                  labelText: 'وزن الدجاج الكلي (كجم)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل وزن الدجاج الكلي';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pricePerKgController,
                decoration: InputDecoration(
                  labelText: 'سعر الكيلوغرام الواحد',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل سعر الكيلوغرام الواحد';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    FirebaseFirestore.instance.collection('chickens').add({
                      'name': _selectedFarmer,
                      'date': _dateController.text,
                      'chickenCount': int.parse(_chickenCountController.text),
                      'totalWeight': double.parse(_totalWeightController.text),
                      'pricePerKg': double.parse(_pricePerKgController.text),
                    }).then((value) {
                      _chickenCountController.clear();
                      _totalWeightController.clear();
                      _pricePerKgController.clear();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حفظ البيانات بنجاح'),
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ أثناء حفظ البيانات'),
                        ),
                      );
                    });
                  }
                },
                child: Text('حفظ'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
