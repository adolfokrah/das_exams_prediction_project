import 'dart:convert';

import 'homePage.dart';
import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/forgotPassword.dart';
import 'package:das_exams_prediction/pages/registerPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';


void main(){
  runApp(LoginPage());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Config appConfiguration = Config();
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _loading = false;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  final facebookLogin = FacebookLogin();
  var userDetails;

  Future<void> login()async{

    if(!_formKey.currentState.validate() && passwordController.text != 'social') return;
      try{
          if(!mounted) return;
          setState(() {
            _loading = true;
          });
          var data = {
            "email": emailController.text,
            "password": passwordController.text
          };

          var url = appConfiguration.apiBaseUrl+'auth/users/login';

          var request = await http.post(url,body: data);


          if(!mounted) return;

          setState(() {
            _loading = false;
          });

          if(request.statusCode == 201){
            if(passwordController.text == 'social'){

              passwordController.text = '';
              emailController.text = '';

              Navigator.push(
                  context, MaterialPageRoute(builder: (BuildContext context) => RegisterPage(email: data['email'],userName: userDetails['userName'])));
              return;
            }
            Toast.show(request.body, context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
            return;
          }



          var userData = request.body;
          SharedPreferences storage = await SharedPreferences.getInstance();
          storage.setString("userData", userData);
          storage.commit();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (BuildContext context) => HomePage()));
      }catch(e){
        if(!mounted) return;
        setState(() {
          _loading = false;
        });
        Toast.show('Connection failed, please try again later', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
        print(e);
      }

  }

  Future<void> googleSignIn() async {
    try {
      setState(() {
        _loading = true;
      });
      await _googleSignIn.signIn();
      setState(() {
        _loading = false;
      });
      var name = _googleSignIn.currentUser.displayName.split(' ');
      var data = {
        "userName": name[0]+''+name[1],
        "email": _googleSignIn.currentUser.email
      };
      emailController.text = _googleSignIn.currentUser.email;
      passwordController.text = 'social';
      setState(() {
        userDetails = data;
      });

     login();

    } catch (error) {
      Toast.show(error, context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      setState(() {
        _loading = false;
      });
      print(error);
    }
  }

  Future<void> facebookSignin() async{
    try{
      setState(() {
        _loading = true;
      });
      final result = await facebookLogin.logIn(['email']);
      setState(() {
        _loading = false;
      });
      switch (result.status) {
        case FacebookLoginStatus.loggedIn:
          final token = result.accessToken.token;
          final graphResponse = await http.get(
              'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email&access_token='+token);
          final profile = jsonDecode(graphResponse.body);

          var data = {
            "userName": profile['first_name']+""+profile['last_name'],
            "email": profile['email']
          };
          setState(() {
            userDetails = data;
          });
          emailController.text = profile['email'];
          passwordController.text = 'social';

          login();
          break;
        case FacebookLoginStatus.cancelledByUser:

          break;
        case FacebookLoginStatus.error:

          break;
      }
    }catch(e){
      setState(() {
        _loading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      progressIndicator: Container(
        width: 100,
        child: LinearProgressIndicator(valueColor:AlwaysStoppedAnimation<Color> (appConfiguration.appPrimaryColor),),
      ),
      child: Scaffold(
        body: Container(
          color: appConfiguration.appAcentColor,
          child: Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child:Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     Align(alignment: Alignment.center,child: Text("LOGIN",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),),
                     Padding(
                       padding: EdgeInsets.only(top:20),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                           InkWell(
                             onTap: (){
                               facebookSignin();
                             },
                             child: Chip(
                               padding: EdgeInsets.only(left:30,right:30,top:13,bottom: 13),
                               backgroundColor: Colors.white,
                               shape: StadiumBorder(side: BorderSide(color: Colors.blueGrey)),
                               avatar: Image.asset("assets/images/facebook.png"),
                               label: Text("Facebook",style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                             ),
                           ),
                           InkWell(
                             onTap: (){
                               googleSignIn();
                             },
                             child: Chip(
                               padding: EdgeInsets.only(left:30,right:30,top:13,bottom: 13),
                               backgroundColor: Colors.white,
                               shape: StadiumBorder(side: BorderSide(color: Colors.blueGrey)),
                               avatar: Image.asset("assets/images/google.png"),
                               label: Text("Google",style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                             ),
                           )
                         ],
                       ),
                     ),

                   Padding(
                     padding: EdgeInsets.only(top:20),
                     child: Form(
                       key: _formKey,
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text("Email",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
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
                           Text("Password",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                           Padding(
                             padding: EdgeInsets.only(top:10),
                             child: TextFormField(
                               controller: passwordController,
                               validator:(value){
                                 if(value.length < 1){
                                   return 'Your password is needed';
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
                           InkWell(
                             onTap: (){
                               Navigator.push(
                                   context, MaterialPageRoute(builder: (BuildContext context) => ForgotPassword()));
                             },
                             child: Padding(
                               padding: EdgeInsets.only(top:20,bottom: 30),
                               child: Align(alignment: Alignment.topRight,child: Text("Forgot your password?",textAlign: TextAlign.right,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),),
                             ),
                           ),
                           Container(
                             width: double.infinity,
                             height: 50,
                             child: FlatButton(
                                 onPressed: (){
                                   login();
                                 },
                                 shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(100),
                                 ),
                                 child: Text("Login",style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                                 color: appConfiguration.appSecondaryColor,
                             ),
                           ),
                           InkWell(
                             onTap: (){
                               Navigator.push(
                                   context, MaterialPageRoute(builder: (BuildContext context) => RegisterPage()));
                             },
                             child: Padding(
                               padding: EdgeInsets.only(top:20,bottom: 30),
                               child: Align(alignment: Alignment.center,
                                   child: RichText(
                                     text: TextSpan(
                                       children: <TextSpan>[
                                         TextSpan(text: "Don't have an account?",style: TextStyle(fontFamily: "Mont",color: Colors.black87)),
                                         TextSpan(text: " Sign up",style: TextStyle(fontFamily: "Mont",color: Colors.blue)),
                                       ]
                                     ),
                                   ),),
                             ),
                           )
                         ],
                       ),
                     ),
                   )
                 ],
                ),
              )
            ),
          ),
        ),
      ),
    );
  }
}
