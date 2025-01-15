import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تهيئة Firebase
  await ensureAdminExists(); // التحقق من وجود المستخدم admin
  runApp(MyApp()); // تشغيل التطبيق
}

// دالة للتحقق من وجود المستخدم admin
Future<void> ensureAdminExists() async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var adminEmail = 'admin@example.com'; // البريد الإلكتروني للمستخدم admin
  var adminPassword = 'admin'; // كلمة المرور للمستخدم admin

  try {
    var adminUser = await _auth.fetchSignInMethodsForEmail(adminEmail);

    // إذا كان المستخدم غير موجود، قم بإنشائه
    if (adminUser.isEmpty) {
      // تسجيل مستخدم admin في Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      // إضافة بيانات admin إلى Firestore
      var userRef = _firestore.collection('users').doc(adminEmail);
      await userRef.set({
        'name': 'Admin',
        'email': adminEmail,
        'isAdmin': true, // تعيين المستخدم كـ Admin
      });

      print("Admin user created and added to Firestore");
    }
  } catch (e) {
    print("Error ensuring admin user exists: $e");
  }
}

// تطبيق Flutter
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المزرعة', // عنوان التطبيق
      theme: ThemeData(
        primarySwatch: Colors.teal, // اللون الرئيسي للتطبيق
        scaffoldBackgroundColor: Colors.grey[100], // خلفية الشاشة
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal, // اللون الخلفي لشريط التطبيق
          foregroundColor: Colors.white, // اللون الأمامي لشريط التطبيق
        ),
      ),
      home: AdminPage(), // الصفحة الرئيسية هي صفحة المسؤول
    );
  }
}

// صفحة المسؤول لإدارة المستخدمين
class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة مستخدم إلى Firestore
  Future<void> addUser(String name, String email, bool isAdmin) async {
    try {
      var userRef = _firestore.collection('users').doc(email); // استخدام البريد الإلكتروني كـ ID
      await userRef.set({
        'name': name,
        'email': email,
        'isAdmin': isAdmin, // تحديد إذا كان المستخدم هو admin
      });
    } catch (e) {
      print("Error adding user: $e");
    }
  }

  // جلب جميع المستخدمين من Firestore
  Future<List<DocumentSnapshot>> _getUsers() async {
    var snapshot = await _firestore.collection('users').get();
    return snapshot.docs;
  }

  // حذف مستخدم من Firestore
  Future<void> _deleteUser(String email) async {
    try {
      await _firestore.collection('users').doc(email).delete(); // حذف المستخدم باستخدام البريد الإلكتروني
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  // التحقق مما إذا كان المستخدم هو admin
  Future<bool> checkIfAdmin(String email) async {
    var snapshot = await _firestore.collection('users').doc(email).get();
    return snapshot.exists && snapshot['isAdmin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة المستخدمين'), // عنوان الصفحة
        actions: [
          // زر تسجيل الخروج
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signOut(); // تسجيل الخروج
            },
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: checkIfAdmin(_auth.currentUser?.email ?? ""), // التحقق مما إذا كان المستخدم هو admin
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // انتظار النتائج
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ!')); // إذا حدث خطأ
          }

          bool isAdmin = snapshot.data ?? false;

          return Column(
            children: [
              // عرض زر إضافة مستخدم إذا كان المستخدم هو admin
              if (isAdmin)
                ElevatedButton(
                  onPressed: () {
                    _showAddUserDialog(); // عرض نافذة إضافة مستخدم جديد
                  },
                  child: Text("إضافة مستخدم جديد"),
                ),
              Expanded(
                child: FutureBuilder<List<DocumentSnapshot>>(
                  future: _getUsers(), // جلب المستخدمين
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator()); // انتظار النتائج
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('حدث خطأ!')); // إذا حدث خطأ
                    }

                    var users = snapshot.data;

                    return ListView.builder(
                      itemCount: users?.length ?? 0,
                      itemBuilder: (context, index) {
                        var user = users![index];
                        return ListTile(
                          title: Text(user['name']), // عرض اسم المستخدم
                          subtitle: Text(user['email']), // عرض البريد الإلكتروني
                          trailing: IconButton(
                            icon: Icon(Icons.delete), // زر الحذف
                            onPressed: () => _deleteUser(user['email']), // حذف المستخدم عند الضغط
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // نافذة إضافة مستخدم جديد
  void _showAddUserDialog() {
    String name = '';
    String email = '';
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('إضافة مستخدم'), // عنوان النافذة
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // حقل إدخال الاسم
              TextField(
                decoration: InputDecoration(labelText: 'الاسم'),
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
              ),
              // حقل إدخال البريد الإلكتروني
              TextField(
                decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              // اختيار إذا كان المستخدم هو admin
              SwitchListTile(
                title: Text("هل هو Admin؟"),
                value: isAdmin,
                onChanged: (value) {
                  setState(() {
                    isAdmin = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            // زر إلغاء
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('إلغاء'),
            ),
            // زر إضافة
            TextButton(
              onPressed: () {
                addUser(name, email, isAdmin); // إضافة المستخدم
                Navigator.pop(context);
              },
              child: Text('إضافة'),
            ),
          ],
        );
      },
    );
  }
}
