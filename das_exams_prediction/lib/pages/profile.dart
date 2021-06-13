import 'dart:convert';
import 'dart:io';

import 'package:das_exams_prediction/includes/config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';
import 'package:crypto/crypto.dart';


void main(){
  runApp(Profile());
}

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Config appConfiguration = Config();
  var _userData;
  var _loading = true;
  File _image;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  String region = "Ashanti";
  String examsType = "BECE";
  var updating = false;

  //set form textfield controllers
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkUserSession();
  }

  Future<void> checkUserSession() async {
    SharedPreferences storage = await SharedPreferences.getInstance();
    var userData = storage.getString("userData");
    if (userData != null) {
      //open home page
      setState(() {
        _userData = jsonDecode(userData);
        _loading = false;
        region = _userData['region'];
        examsType = _userData['typeOfExams'];
        userNameController.text = _userData['username'];
        phoneNumberController.text = _userData['phonenumber'];
        emailController.text = _userData['email'];
      });
    }
  }

  Future getImage() async {
    try{
      final pickedFile = await picker.getImage(source: ImageSource.gallery);

      setState(() {
        if (pickedFile != null) {
          setState(() {
            _image = File(pickedFile.path);
          });
        } else {
          print('No image selected.');
        }
      });
    }catch(e){
      print(e);
    }
  }

  updateProfile()async{
    if(_formKey.currentState.validate()){
      try{
        setState(() {
          updating = true;
        });

        var data = {
          "user_id": _userData['user_id'].toString(),
          "username": userNameController.text,
          "email": emailController.text,
          "typeOfExams": examsType,
          "region": region,
          "phonenumber": phoneNumberController.text,
          "password": passwordController.text,
          "photo":"",
          "photoName":""
        };

        String url = '${appConfiguration.apiBaseUrl}auth/users/updateprofile';

        var request = new http.MultipartRequest("POST", Uri.parse(url));
        request.fields.addAll(data);

        if(_image != null){

          http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
              'photo', _image.path);
          request.files.add(multipartFile);
          String fileName = _image.path.split("/").last;

          data['photoName'] = fileName;
        }

        http.StreamedResponse response = await request.send();

        if (!mounted) return;
        setState(() {
          updating = false;
        });

        var responseData = await response.stream.bytesToString();

        if(response.stream =="error"){
          Toast.show('Oops! it seems your new email is already available', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
        }else{



          Toast.show('Profile updated', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
          SharedPreferences storage = await SharedPreferences.getInstance();
          storage.setString("userData", responseData);
          storage.commit();

        }
      }catch(e){
        if (!mounted) return;
        setState(() {
          _loading  = false;
          updating = false;
        });
        Toast.show('Oops! connection failed, please try again later', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "My Profile",
        theme: ThemeData(
            primaryColor: appConfiguration.appPrimaryColor
        ),
        debugShowCheckedModeBanner: false,
      home: LoadingOverlay(
        isLoading: updating,
        child: SafeArea(
          child: Scaffold(
              appBar: AppBar(
                leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
                  Navigator.pop(context);
                },),
                backgroundColor: appConfiguration.appPrimaryColor,
                title: Text("Profile"),
              ),
              body: _loading ? Container() : profileContent()
          ),
        ),
      ),
    );
  }

  Widget profileContent(){
     return ListView(
       children: [
         Padding(
           padding: EdgeInsets.only(top: 40),
           child: Align(
             alignment: Alignment.center,
             child: Stack(
               children: [
                 CircleAvatar(
                   radius: 75,
                   backgroundImage: _image == null ? NetworkImage(
                       appConfiguration.usersImageFolder + '/' +
                           _userData['photo']) : FileImage(_image),
                 ),
                 Container(
                   decoration: BoxDecoration(
                     color: Colors.deepOrange,
                     borderRadius: BorderRadius.circular(100)
                   ),
                   margin: EdgeInsets.only(top: 100, left: 100),
                   child: IconButton(
                     onPressed: (){
                       getImage();
                     },
                     icon: Icon(Icons.camera_alt, color: Colors.white,),
                   ),
                 )
               ],
             ),
           ),
         ),
         Padding(
           padding: EdgeInsets.all(20),
           child: Form(
             key: _formKey,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text("User Name",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                 Padding(
                   padding: EdgeInsets.only(top:10,bottom: 20),
                   child: TextFormField(
                     controller: userNameController,
                     validator: (value){
                       return value.length < 1  ? "Username required" : null;
                     },
                     style: TextStyle(fontFamily: "Mont",fontSize: 13),
                     decoration: InputDecoration(
                       contentPadding: EdgeInsets.fromLTRB(20,10,10,20),
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius:BorderRadius.circular(100)),
                     ),
                   ),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top: 10),
                   child: Text("Phone Number",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top:10,bottom: 20),
                   child: TextFormField(
                     controller: phoneNumberController,
                     validator: (value){
                       if(!(RegExp(r"^[+][0-9]*$").hasMatch(value))){
                         return 'Please start with your country code eg. (+x xxx-xxx-xxxx)';
                       }
                       return null;
                     },
                     keyboardType: TextInputType.phone,
                     style: TextStyle(fontFamily: "Mont",fontSize: 13),
                     decoration: InputDecoration(
                       contentPadding: EdgeInsets.fromLTRB(20,10,10,20),
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius:BorderRadius.circular(100)),
                     ),
                   ),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top: 10),
                   child: Text("Email",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top:10,bottom: 20),
                   child: TextFormField(
                     controller: emailController,
                     validator: (value){
                       if( !(RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) || value.isEmpty){
                         return 'Please your a valid Email';
                       }
                       return null;
                     },
                     style: TextStyle(fontFamily: "Mont",fontSize: 13),
                     decoration: InputDecoration(
                       contentPadding: EdgeInsets.fromLTRB(20,10,10,20),
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius:BorderRadius.circular(100)),
                     ),
                   ),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top: 10),
                   child: Text("Type of exams",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top:10,bottom: 20),
                   child: DropdownButtonFormField<String>(
                     decoration: InputDecoration(
                       contentPadding: EdgeInsets.all(10),
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius:BorderRadius.circular(100)),
                     ),
                     isExpanded: true,
                     value: examsType,
                     iconSize: 24,
                     elevation: 16,
                     onChanged: (String newValue) {
                       setState(() {
                         examsType = newValue;
                       });
                     },
                     items: <String>['BECE', 'WASSCE']
                         .map<DropdownMenuItem<String>>((String value) {
                       return DropdownMenuItem<String>(
                         value: value,
                         child: Text(value,style: TextStyle(fontFamily: "Mont",fontSize: 13)),
                       );
                     }).toList(),
                   ),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top: 10),
                   child: Text("Region",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top:10,bottom: 20),
                   child: DropdownButtonFormField<String>(
                     decoration: InputDecoration(
                       contentPadding: EdgeInsets.all(10),
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius:BorderRadius.circular(100)),
                     ),
                     isExpanded: true,
                     value: region,
                     iconSize: 24,
                     elevation: 16,
                     onChanged: (String newValue) {
                       setState(() {
                         region = newValue;
                       });
                     },
                     items: appConfiguration.regions
                         .map<DropdownMenuItem<String>>((String value) {
                       return DropdownMenuItem<String>(
                         value: value,
                         child: Text(value,style: TextStyle(fontFamily: "Mont",fontSize: 13)),
                       );
                     }).toList(),
                   ),
                 ),
                 Container(
                   padding: EdgeInsets.all(10),
                   child: Text("Leave password field blank if you are not updating it"),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top: 10),
                   child: Text("Old Password",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top:10),
                   child: TextFormField(
                     controller: oldPasswordController,
                     validator:(value){
                       if(value.length > 1){
                         if((!(value.contains(new RegExp(r"[0-9.!#$%&'*+-/=?^_`{|}~]"))) || value.isEmpty) || value.length < 5){
                           return 'Your password is very week';
                         }else if(md5.convert(utf8.encode(value)).toString() != _userData['password']) {
                           return 'Incorrect password provided';
                         }
                       }
                       return null;
                     },
                     obscureText: true,
                     style: TextStyle(fontFamily: "Mont",fontSize: 13),
                     decoration: InputDecoration(
                       contentPadding: EdgeInsets.fromLTRB(20,10,10,20),
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius:BorderRadius.circular(100)),
                     ),
                   ),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top: 10),
                   child: Text("New Password",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                 ),
                 Padding(
                   padding: EdgeInsets.only(top:10),
                   child: TextFormField(
                     controller: passwordController,
                     validator:(value){
                       if(oldPasswordController.text.length > 1){
                         if((!(value.contains(new RegExp(r"[0-9.!#$%&'*+-/=?^_`{|}~]"))) || value.isEmpty) || value.length < 5){
                           return 'Your password is very week';
                         }
                       }
                       return null;
                     },
                     obscureText: true,
                     style: TextStyle(fontFamily: "Mont",fontSize: 13),
                     decoration: InputDecoration(
                       contentPadding: EdgeInsets.fromLTRB(20,10,10,20),
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(borderRadius:BorderRadius.circular(100)),
                     ),
                   ),
                 ),
                 Container(
                   width: double.infinity,
                   height: 50,
                   margin: EdgeInsets.only(top: 30),
                   child: FlatButton(
                     onPressed: (){
                       updateProfile();
                     },
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(100),
                     ),
                     child: Text("Save changes",style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                     color: appConfiguration.appSecondaryColor,
                   ),
                 )
               ],
             ),
           ),
         )
       ],
     );
  }
}
