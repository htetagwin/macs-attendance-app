import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? uid = auth.currentUser?.uid;
  String? email = auth.currentUser?.email;
  if (email == null) {
    print('No authenticated user. Please log in.');
    return;
  }
  await firestore.collection('users').doc(uid).set({
    'email': email,
    'role': 'admin',
    'created_at': Timestamp.now(),
  }, SetOptions(merge: true));
  print('Admin role set for $email');
}