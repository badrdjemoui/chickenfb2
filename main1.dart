import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chicken Farm Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _chickenCountController = TextEditingController();
  final TextEditingController _totalWeightController = TextEditingController();
  final TextEditingController _pricePerKgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chicken Farm Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'اسم المربي'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل اسم المربي';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(labelText: 'التاريخ'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل التاريخ';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _chickenCountController,
                decoration: InputDecoration(labelText: 'عدد الدجاج'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل عدد الدجاج';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _totalWeightController,
                decoration: InputDecoration(labelText: 'وزن الدجاج الكلي (كجم)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'من فضلك أدخل وزن الدجاج الكلي';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _pricePerKgController,
                decoration: InputDecoration(labelText: 'سعر الكيلوغرام الواحد'),
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
                      'name': _nameController.text,
                      'date': _dateController.text,
                      'chickenCount': int.parse(_chickenCountController.text),
                      'totalWeight': double.parse(_totalWeightController.text),
                      'pricePerKg': double.parse(_pricePerKgController.text),
                    }).then((value) {
                      _nameController.clear();
                      _dateController.clear();
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
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChickenList(),
                    ),
                  );
                },
                child: Text('عرض البيانات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChickenList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عرض البيانات'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chickens').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل البيانات'));
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('لا توجد بيانات'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text('اسم المربي: ${doc['name']}'),
                subtitle: Text(
                  'التاريخ: ${doc['date']}\nعدد الدجاج: ${doc['chickenCount']}\nوزن الكلي: ${doc['totalWeight']} كجم\nسعر الكيلوغرام: ${doc['pricePerKg']}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('chickens')
                        .doc(doc.id)
                        .delete()
                        .then((value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حذف السجل'),
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('خطأ أثناء حذف السجل'),
                        ),
                      );
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
