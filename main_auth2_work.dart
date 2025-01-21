import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/chicken_form.dart';

void main() async {
  // Ensures Firebase is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initializes Firebase
  runApp(MyApp()); // Runs the app
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The root widget of the application
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disables the debug banner
      home: UserListScreen(), // Sets the initial screen of the app
    );
  }
}

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState(); // Creates the state for the screen
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Reference to Firestore
  List<DocumentSnapshot> users = []; // List to store user documents from Firestore
  bool isLoading = true; // Indicates if data is still being loaded
  String errorMessage = ''; // Stores error message, if any

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users from Firestore when the widget is initialized
  }

  // Fetches users from Firestore and updates the UI accordingly
  Future<void> _fetchUsers() async {
    try {
      var snapshot = await _firestore.collection('users').get(); // Fetches data from 'users' collection
      setState(() {
        users = snapshot.docs; // Updates the users list with fetched documents
        isLoading = false; // Data has finished loading
      });
      print("Fetched ${users.length} users.");
    } catch (e) {
      // Handles any errors that occur during fetching
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching users: $e"; // Sets the error message
      });
      print("Error fetching users: $e");
    }
  }

  // Adds a user to Firestore with the provided details
  Future<void> _addUser(
      String name, String email, String password, bool isAdmin) async {
    try {
      var userRef = _firestore.collection('users').doc(email); // Reference to the user's document
      await userRef.set({
        'name': name,
        'email': email,
        'password': password, // Storing the password (note: avoid storing passwords in plain text)
        'isAdmin': isAdmin,
      });
      print("User added: $email");
      _fetchUsers(); // Refreshes the user list after adding
    } catch (e) {
      print("Error adding user: $e");
    }
  }

  // Deletes a user from Firestore by their email
  Future<void> _deleteUser(String email) async {
    try {
      await _firestore.collection('users').doc(email).delete(); // Deletes the user document
      print("User deleted: $email");
      _fetchUsers(); // Refreshes the user list after deletion
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  // Verifies the user's password and navigates to a new screen if correct
  void _verifyPasswordAndNavigate(String email) async {
    TextEditingController passwordController = TextEditingController();
    bool _isPasswordVisible = false; // Flag to toggle password visibility

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text field for entering the password
                  TextField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible, // Hides password text when false
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          // Toggles the password visibility
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                // Action button to cancel and close the dialog
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                // Action button to submit the entered password
                TextButton(
                  onPressed: () async {
                    var userDoc =
                        await _firestore.collection('users').doc(email).get();
                    if (userDoc.exists) {
                      var data = userDoc.data() as Map<String, dynamic>;
                      print("Input Password: ${passwordController.text}");
                      print("Stored Password: ${data['password']}");
                      // Compares the entered password with the stored one
                      if (data['password'] == passwordController.text.trim()) {
                        Navigator.pop(context); // Close the dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChickenForm()),
                        ); // Navigate to the next screen if passwords match
                      } else {
                        // Shows a snack bar if the password is incorrect
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incorrect password!')),
                        );
                      }
                    } else {
                      // Shows a snack bar if the user does not exist
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User does not exist!')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'), // App bar title
        actions: [
          // Add user button, when clicked adds a new user
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await _addUser('New User', 'admin@admin.com', 'Ss123456', true);
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator while data is being fetched
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage)) // Displays error message if any
              : users.isEmpty
                  ? Center(child: Text('No users found.')) // Message when no users exist
                  : ListView.builder(
                      itemCount: users.length, // Displays users in a list
                      itemBuilder: (context, index) {
                        var user = users[index].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? 'No Email'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteUser(user['email']),
                          ),
                          onTap: () =>
                              _verifyPasswordAndNavigate(user['email']),
                        );
                      },
                    ),
    );
  }
}
