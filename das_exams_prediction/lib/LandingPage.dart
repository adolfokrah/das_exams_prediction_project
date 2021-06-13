import 'dart:convert';

import 'pages/homePage.dart';
import 'package:das_exams_prediction/pages/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';

import 'includes/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(){
  runApp(LandingPage());
}

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Config appConfiguration = Config();
  bool login  = false;
  bool initial = true;

  @override
  void initState(){
    super.initState();

    checkUserSession();
  }
  //check if user is already logged in
  Future<void> checkUserSession()async{
    SharedPreferences storage = await SharedPreferences.getInstance();
    var userData = storage.getString("userData");
    if(userData != null){
      //open home page
      setState(() {
        login  = true;
        initial = false;
      });
    }else{
      setState(() {
        initial = false;
      });
    }

  }
  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(appConfiguration.appPrimaryColor);
    return MaterialApp(
      title: login ? "Home" : "Das Exams Prediction",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: loadPage(),
    );
  }

  Widget loadPage(){
    if(initial) return Scaffold();
    if(login) return HomePage();
    if(!login) return LoginPage();
  }
}
