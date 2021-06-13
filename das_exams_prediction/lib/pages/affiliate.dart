import 'dart:convert';

import 'package:das_exams_prediction/includes/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(){
  runApp(AffiliatePage());
}

class AffiliatePage extends StatefulWidget {
  @override
  _AffiliatePageState createState() => _AffiliatePageState();
}

class _AffiliatePageState extends State<AffiliatePage> {
  Config appConfiguration = Config();
  var _userData;

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  Future getUserDetails()async{
    SharedPreferences storage = await SharedPreferences.getInstance();
    var userData = storage.getString("userData");
    if(!mounted) return;
    setState(() {
      _userData = jsonDecode(userData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Invite Your Friends",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
            brightness: Brightness.light,
            elevation: 0,
            title: Text("Invite Your Friends",style: TextStyle(color: Colors.black),),
            leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.black), onPressed: (){
              Navigator.pop(context);
            },),
            backgroundColor: Colors.white
        ),
        body: content(),
      ),
    );
  }

  Widget content(){
    return  Container(
      color: Colors.white,
      child: (
         ListView(
           children: [
             Align(
               alignment: Alignment.center,
               child:  Image.asset("assets/images/affiliate.jpg"),
             ),
             Align(
               alignment: Alignment.center,
               child:  Text("Refer & Earn",style: TextStyle(fontSize: 20,fontFamily: "Mont",fontWeight: FontWeight.bold),),
             ),
             Padding(
               padding: EdgeInsets.only(top: 20,left: 40,right: 40,bottom: 40),
               child: Align(
                 alignment: Alignment.center,
                 child:  Text("Invite your friends and earn a free 14 days free subscription when they first upgrade their account",style: TextStyle(fontSize: 15,fontFamily: "Mont"),textAlign: TextAlign.center,),
               ),
             ),
             Align(
               child:  Container(
                 width: 200,
                 padding: EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: Colors.white10,
                   borderRadius: BorderRadius.circular(50.0),
                   border: Border.all(
                     color: appConfiguration.appPrimaryColor,
                     width: 3// red as border color
                   ),
                 ),
                 child: Text(_userData['scode'],textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
               ),
               alignment: Alignment.center,
             ),
             Align(
               child:  Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: IconButton(
                   onPressed: ()async{
                     await FlutterShare.share(
                       title: 'Invite Friends',
                       text: 'Hello, I use Das Prediction to access top predicted topics, questions and answers for the upcoming WASSCE and BECE exams. Download the app and use my referral code ${_userData['scode']} and get a discount off your first subscription. https://play.google.com/store/apps/details?id=com.das_exams_prediction',
                     );
                   },
                   icon: Icon(Icons.share,
                     color: Colors.black),
                 ),
               ),
               alignment: Alignment.center,
             )
           ],
         )
      ),
    );
  }
}
