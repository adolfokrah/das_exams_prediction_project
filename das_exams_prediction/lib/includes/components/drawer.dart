import 'dart:convert';

import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/affiliate.dart';
import 'package:das_exams_prediction/pages/profile.dart';
import 'package:das_exams_prediction/pages/submittedQuestions.dart';
import 'package:das_exams_prediction/pages/subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:das_exams_prediction/pages/examSelction.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main(){
  runApp(MyDrawer());
}

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  Config appConfiguration = Config();
  var _userData;
  bool _loading = true;
  var years;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  final facebookLogin = FacebookLogin();

  var drawerMenus = [
    {
      "menuType": "heading",
      "title": "Product",
      "link": null,
      "icon": null
    },
    {
      "menuType": "menu",
      "title": "My Subscription",
      "link": "/sub",
      "icon": Icon(Icons.vpn_key)
    },
    {
      "menuType": "menu",
      "title": "Licences Terms & Conditions",
      "link": "https://dasexams.com/licenses-terms-conditions/",
      "icon": Icon(Icons.copyright)
    },
    {
      "menuType": "divider",
      "title": null,
      "link": null,
      "icon": null
    },
    {
      "menuType": "heading",
      "title": "Exams",
      "link": null,
      "icon": null
    },
    {
      "menuType": "menu",
      "title": "WASSCE Private",
      "link": "menu",
      "icon": Icon(Icons.book)
    },
    {
      "menuType": "menu",
      "title": "WASSCE School",
      "link": "menu",
      "icon": Icon(Icons.school)
    },
    {
      "menuType": "menu",
      "title": "BECE Private",
      "link": "menu",
      "icon": Icon(Icons.school_outlined)
    },
    {
      "menuType": "menu",
      "title": "BECE School",
      "link": "menu",
      "icon": Icon(Icons.book_outlined)
    },
    {
      "menuType": "menu",
      "title": "BECE/WASSCE Assitant",
      "link": "menu",
      "icon": Icon(Icons.help)
    },
    {
      "menuType": "divider",
      "title": null,
      "link": null,
      "icon": null
    },
    {
      "menuType": "heading",
      "title": "Contact",
      "link": "https://dasexams.com/contact-das-exams-predictions/",
      "icon": null
    },
    {
      "menuType": "menu",
      "title": "Rate App",
      "link": null,
      "icon": Icon(Icons.star)
    },
    {
      "menuType": "menu",
      "title": "Invite Friends",
      "link": "menu",
      "icon": Icon(Icons.send)
    },
    {
      "menuType": "menu",
      "title": "Website",
      "link": "https://dasexams.com/",
      "icon": Icon(Icons.flaky_outlined)
    },
    {
      "menuType": "menu",
      "title": "About Das Exams",
      "link": "https://dasexams.com/",
      "icon": Icon(Icons.info_outline)
    },
    {
      "menuType": "menu",
      "title": "Logout",
      "link": '/logout',
      "icon": Icon(Icons.power_settings_new_outlined)
    }
  ];

  @override
  void initState() {
    super.initState();
    checkUserSession();
    getUserDetails();
  }

  //check if user is already logged in
  Future<void> checkUserSession() async {
    SharedPreferences storage = await SharedPreferences.getInstance();
    var userData = storage.getString("userData");
    if (userData != null) {
      //open home page
      setState(() {
        _userData = jsonDecode(userData);
        _loading = false;
      });
    }
  }

  Future<void> getUserDetails()async{
    try{
      var data = {
        "user_id": _userData['user_id'].toString(),
        "username": _userData['username'],
        "photoName":"",
        "photo":"",
        "password":"",
        "email":_userData['email']

      };

      String url = '${appConfiguration.apiBaseUrl}auth/users/updateprofile';

      var req = await http.post(url,body: data);
      var response = req.body;

      SharedPreferences storage = await SharedPreferences.getInstance();
      storage.setString("userData", response);
      storage.commit();
    }catch(e){
      print(e);
    }
  }


  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: ()async{
                SharedPreferences storage = await SharedPreferences.getInstance();
                storage.clear();

                await _googleSignIn.signOut();
                await facebookLogin.logOut();
                Phoenix.rebirth(context);
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _loading ? Container() : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/drawerBanner.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                      appConfiguration.usersImageFolder  +
                          _userData['photo']),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 10, left: 10),
                          child: Text(_userData['username'], style: TextStyle(
                              fontFamily: "Mont", fontSize: 16),),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 0, left: 10),
                          child: Text(
                            _userData['phonenumber'], style: TextStyle(
                              fontFamily: "Mont", fontSize: 16),),
                        )
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.white,),
                      onPressed: () async {
                         var data = await Navigator.push(
                            context, MaterialPageRoute(builder: (BuildContext context) => Profile()));
                         checkUserSession();
                      },
                    )
                  ],
                )
              ],
            ) /* add child content here */,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: drawerMenus.length,
              itemBuilder: (context, index) {
                if (drawerMenus[index]['menuType'] == 'heading') {
                  return ListTile(
                    title: Text(drawerMenus[index]['title'],
                      style: TextStyle(color: Colors.black38, fontSize: 15),),
                  );
                }
                if (drawerMenus[index]['menuType'] == 'divider') {
                  return Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: Divider(),
                  );
                }
                return InkWell(
                  onTap: ()async{
                    // print(drawerMenus[index]['link']);

                    if(drawerMenus[index]['link'] == '/logout'){
                      _showMyDialog();
                    }

                     if(drawerMenus[index]['link'] == '/sub'){
                       var data = await Navigator.push(
                           context, MaterialPageRoute(builder: (BuildContext context) => Subscription()));
                          getUserDetails();
                     }
                     if(drawerMenus[index]['link'] == 'menu'){
                       var menuTitle = drawerMenus[index]['title'].toString().toLowerCase();
                       if(menuTitle == 'bece/wassce assitant'){
                           if(_userData['expired'] == 'true'){

                             Navigator.push(
                                 context, MaterialPageRoute(builder: (BuildContext context) => Subscription()));
                             getUserDetails();
                             return;
                           }else{
                             Navigator.push(
                                 context, MaterialPageRoute(builder: (BuildContext context) => SubmittedQuestions(userId: _userData['user_id'],)));
                           }


                         return;
                       }else if(menuTitle == 'invite friends'){
                         Navigator.push(
                             context, MaterialPageRoute(builder: (BuildContext context) => AffiliatePage()));return;
                       }

                       Navigator.push(
                           context, MaterialPageRoute(builder: (BuildContext context) => ExamSelection(examsType: menuTitle)));
                       getUserDetails();
                       return;

                     }else if(drawerMenus[index]['link'] != null && drawerMenus[index]['link'] != '/sub' && drawerMenus[index]['link'] != '/logout'){
                      // print(drawerMenus[index]['link']);
                       await launch(drawerMenus[index]['link'] );
                     }

                  },
                  child: ListTile(
                    leading: drawerMenus[index]['icon'],
                    title: Text(drawerMenus[index]['title'],style: TextStyle(fontSize: 15),),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}