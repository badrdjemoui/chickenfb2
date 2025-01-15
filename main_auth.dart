import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ensureAdminExists(); // التحقق من وجود المستخدم admin
  runApp(MyApp());
}

Future<void> ensureAdminExists() async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تحقق من وجود مستخدم admin
  var adminEmail = 'admin@example.com';
  var adminPassword = 'admin';

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
        'isAdmin': true,
      });

      print("Admin user created and added to Firestore");
    }
  } catch (e) {
    print("Error ensuring admin user exists: $e");
  }
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
      home: AdminPage(),
    );
  }
}

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة مستخدم admin أو مستخدم آخر إلى Firestore
  Future<void> addUser(String name, String email, bool isAdmin) async {
    try {
      var userRef = _firestore.collection('users').doc(email); // استخدام البريد الإلكتروني كـ ID
      await userRef.set({
        'name': name,
        'email': email,
        'isAdmin': isAdmin,
      });
    } catch (e) {
      print("Error adding user: $e");
    }
  }

  // جلب المستخدمين من Firestore
  Future<List<DocumentSnapshot>> _getUsers() async {
    var snapshot = await _firestore.collection('users').get();
    return snapshot.docs;
  }

  // حذف مستخدم من Firestore
  Future<void> _deleteUser(String email) async {
    try {
      await _firestore.collection('users').doc(email).delete();
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
        title: Text('قائمة المستخدمين'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: checkIfAdmin(_auth.currentUser?.email ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ!'));
          }

          bool isAdmin = snapshot.data ?? false;

          return Column(
            children: [
              if (isAdmin)
                ElevatedButton(
                  onPressed: () {
                    _showAddUserDialog();
                  },
                  child: Text("إضافة مستخدم جديد"),
                ),
              Expanded(
                child: FutureBuilder<List<DocumentSnapshot>>(
                  future: _getUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('حدث خطأ!'));
                    }

                    var users = snapshot.data;

                    return ListView.builder(
                      itemCount: users?.length ?? 0,
                      itemBuilder: (context, index) {
                        var user = users![index];
                        return ListTile(
                          title: Text(user['name']),
                          subtitle: Text(user['email']),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteUser(user['email']),
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
          title: Text('إضافة مستخدم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'الاسم'),
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                addUser(name, email, isAdmin);
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
