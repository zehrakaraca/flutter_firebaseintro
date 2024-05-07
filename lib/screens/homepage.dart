import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebaseintro/models/userModel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  File? _selectedAvatar;

  Future<UserModel> _getUser() async {
    User? loggedInUser = FirebaseAuth.instance.currentUser;

    if (loggedInUser != null) {
      FirebaseFirestore db = FirebaseFirestore.instance;

      var userInfo = await db.collection("users").doc(loggedInUser.uid).get();
      var userJson = userInfo.data();
      UserModel userModel = UserModel.fromMap(userJson!);

      return userModel;
    }

    throw Exception("");
  }

  void _openImagePicker() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedAvatar = File(image.path);
      });
    }
  }

  void _uploadImage() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseStorage storage = FirebaseStorage.instance;
    final avatarPath = storage.ref().child("avatars").child("$userId.jpg");
    await avatarPath.putFile(_selectedAvatar!);
    final url = await avatarPath.getDownloadURL();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update({'avatarUrl': url});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase App"),
        actions: [
          IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: FutureBuilder(
          future: _getUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("Veri Yükleniyor..");
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedAvatar != null)
                    CircleAvatar(
                      foregroundImage: FileImage(_selectedAvatar!),
                      radius: 40,
                    ),
                  if (snapshot.data!.avatarUrl != null &&
                      _selectedAvatar == null)
                    CircleAvatar(
                      foregroundImage: NetworkImage(snapshot.data!.avatarUrl!),
                      radius: 40,
                    ),
                  IconButton(
                    onPressed: () {
                      _openImagePicker();
                    },
                    icon: Icon((_selectedAvatar != null ||
                            snapshot.data!.avatarUrl != null)
                        ? Icons.update
                        : Icons.add),
                  ),
                  if (_selectedAvatar != null)
                    TextButton(
                      onPressed: () {
                        _uploadImage();
                      },
                      child: const Text("Yükle"),
                    ),
                  Text(
                      "Hoşgeldiniz ${snapshot.data!.firstName} ${snapshot.data!.lastName}"),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
