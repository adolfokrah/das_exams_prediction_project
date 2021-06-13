import 'dart:convert';

import 'package:das_exams_prediction/includes/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';


void main(){
  runApp(Subscription());
}

class Subscription extends StatefulWidget {
  @override
  _SubscriptionState createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  Config appConfiguration = Config();
  var _loading = true;
  var updating = false;
  var screen = 'new_sub';
  var _userData;
  var upgradeAmount = 0.0;
  var discountAmount = 0.0;
  var upgradeAmounts;
  var monthly = true;
  var list = ['Access unlimited topics and predictions','View current year predictions and solutions','Submit your preferred question for solutions','Quickly search for topics'];

  @override
  void initState() {
    super.initState();
    checkUserSession();
  }

  Future<void> checkUserSession() async {
    try{
      SharedPreferences storage = await SharedPreferences.getInstance();
      var userData = storage.getString("userData");
      if (userData != null) {
        //open home page
        if(!mounted) return;
        var uuserData = jsonDecode(userData);

        //get upgrade amount
        var url = appConfiguration.apiBaseUrl+'get_upgrade_amount/'+uuserData['user_id'].toString();
        var request = await http.get(url);
        if(!mounted) return;
        setState(() {
          _loading = false;
          upgradeAmounts = jsonDecode(request.body);
          upgradeAmount = jsonDecode(request.body)['monthly'].toDouble();
          discountAmount =  jsonDecode(request.body)['monthlyD'].toDouble();
          _userData = jsonDecode(request.body)['userData'];
        });
        storage.setString("userData", jsonEncode(jsonDecode(request.body)['userData']));
      }
    }catch(e){
      Navigator.pop(context);
      Toast.show('Connection failed',context);
      print(e);
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Subscription",
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
                title: Text("Subscription"),
              ),
              body: _loading ? Align(alignment: Alignment.center,child: CircularProgressIndicator(),) : subscriptionContent()
          ),
        ),
      ),
    );
  }

  upgrade() async {
      var duration = monthly ? "monthly" : "yearly";
      var userId = _userData['user_id'];

      String credentials = '$duration:$userId';
      Codec<String, String> stringToBase64 = utf8.fuse(base64);
      String encoded = stringToBase64.encode(credentials);

      var url = '${appConfiguration.apiBaseUrl}upgrade/$encoded/';
      if (await canLaunch(url)) {
      await launch(url);
      } else {
      throw 'Could not launch $url';
      }
  }
  Widget subscriptionContent(){
      return ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Container(
                width: 250,
                child: _userData['expired'] == 'false' ? null : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("Yearly",style: TextStyle(fontFamily: "Mont",fontSize: 15,fontWeight: FontWeight.bold,color: monthly ? Colors.black38: Colors.black),),
                    FlutterSwitch(
                      width: 100.0,
                      height: 40.0,
                      inactiveColor: appConfiguration.appPrimaryColor,
                      valueFontSize: 25.0,
                      toggleSize: 30.0,
                      value: monthly,
                      borderRadius: 30.0,
                      padding: 5.0,
                      showOnOff: false,
                      onToggle: (val) {
                        setState(() {
                          monthly = val;
                        });
                        if(val){
                          setState(() {
                            discountAmount = upgradeAmounts['monthlyD'].toDouble();
                            upgradeAmount = upgradeAmounts['monthly'].toDouble();
                          });
                        }else{
                          setState(() {
                            upgradeAmount = upgradeAmounts['yearly'].toDouble();
                            discountAmount = upgradeAmounts['yearlyD'].toDouble();
                          });
                        }
                      },
                    ),
                    Text("Monthly",style: TextStyle(fontFamily: "Mont",fontSize: 15,fontWeight: FontWeight.bold, color: monthly ? Colors.black: Colors.black38),),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
                width: 100,
                margin: EdgeInsets.only(top:40),
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _userData['expired'] == 'false' ? [Color(0xff5EB6E0), Color(0xff4cd517)]: [Color(0xff5EB6E0), Color(0xff706BD1)])
              ),
              child: Text(_userData['expired'] == 'false' ? 'ACTIVE' : 'PRO',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 20),textAlign: TextAlign.center,),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
                padding: EdgeInsets.only(top:10),
                child: _userData['expired'] == 'true'  ? RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: "¢ ${upgradeAmount.toStringAsFixed(2)}",style: TextStyle(fontSize: discountAmount > 0 ? 20  : 30,fontWeight: FontWeight.bold,fontFamily: "Mont",color: discountAmount > 0 ? Colors.black45 : Color(0xff527684),
                      decoration: discountAmount > 0 ? TextDecoration.lineThrough  : TextDecoration.none),),
                      TextSpan(text: discountAmount < 1 ? null :  " ¢ ${discountAmount.toStringAsFixed(2)}",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,fontFamily: "Mont",color: Color(0xff527684),),),
                    ]
                  )
                ) : null),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
                padding: EdgeInsets.only(top:10,left:100,right:100),
                child: Text("Enjoy all the amazing features of the das predictions app",style: TextStyle(fontSize: 10,fontFamily: "Mont",color: Color(0xff527684)),textAlign: TextAlign.center,)),
          ),
          Padding(
            padding: EdgeInsets.only(top:20,left:20,right:20,bottom:0),
            child: Divider(),
          ),
          for(var item in list)  Padding(
            padding: EdgeInsets.only(left:10,right:10),
              child: ListTile(
              leading: Icon(Icons.check_circle_outline_outlined, color: Colors.green,),
              title: Text(item,style: TextStyle(fontFamily: "Mont",fontSize: 13),),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: _userData['expired'] == 'false' ? mySubscription() : Padding(
              padding: EdgeInsets.all(20),
              child: InkWell(
                onTap: (){
                  upgrade();
                },
                child: Container(
                     width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Color(0xff6C6DC9),

                    ),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    margin: EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xff5EB6E0), Color(0xff706BD1)])
                    ),
                    child: Text("UPGRADE NOW",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 20,fontFamily: "Mont"),textAlign: TextAlign.center,),
                  ),
                ),
              ),
            ),
          )
        ],
      );
  }

  Widget mySubscription(){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top:10,left:100,right:100),
          child: Text("Expires on",style: TextStyle(fontSize: 10,fontFamily: "Mont",color: Color(0xff527684)),textAlign: TextAlign.center,),
        ),
        Padding(
          padding: EdgeInsets.only(top:10,left:100,right:100),
          child: Text((DateFormat("yyyy-MM-dd").format(DateFormat('yyyy-MM-dd').parse(_userData['expiration']))).toString(),style: TextStyle(fontSize: 10,fontFamily: "Mont",color: Color(0xff527684)),textAlign: TextAlign.center,),
        )
      ],
    );
  }
}
