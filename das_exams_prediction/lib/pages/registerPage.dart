import 'dart:convert';

import 'package:das_exams_prediction/includes/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

void main(){
  runApp(RegisterPage());
}

class RegisterPage extends StatefulWidget {
  final userName;
  final email;

  RegisterPage({@required userName, @required email}): this.userName = userName, this.email = email;
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Config appConfiguration = Config();
  String region = "Ashanti";
  String examsType = "BECE";
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  GoogleSignIn _googleSignIn = GoogleSignIn();
  final facebookLogin = FacebookLogin();

  //set form textfield controllers
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController sponsorController = TextEditingController();



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
      userNameController.text = data['userName'];


    } catch (error) {
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
          emailController.text = profile['email'];
          userNameController.text = data['userName'];

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
  initState(){
    super.initState();
    if(widget.email != ''){
      emailController.text = widget.email;
      userNameController.text = widget.userName;
    }
  }

  Future<void> registerUser()async{
    if(_formKey.currentState.validate()){

      try{
        if(!mounted) return;
        setState(() {
          _loading = true;
        });
        var data = {
          "username": userNameController.text,
          "email": emailController.text,
          "typeOfExams": examsType,
          "region": region,
          "phonenumber": phoneNumberController.text,
          "password": passwordController.text,
          "photo": 'avatar.jpg',
          'expired': 'true',
          'sponsor': sponsorController.text
        };

        var url = appConfiguration.apiBaseUrl+'auth/users/register';
        var request = await http.post(url,body: data);
        if(!mounted) return;
        setState(() {
          _loading = false;
        });
        if(request.statusCode == 201){
          Toast.show(request.body, context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
          return;
        }


        var userData = request.body;
        SharedPreferences storage = await SharedPreferences.getInstance();
        storage.setString("userData", userData);
        storage.commit();
        Phoenix.rebirth(context);

      }catch(e){
        if(!mounted) return;
        setState(() {
          _loading = false;
        });
        Toast.show('Connection failed, please try again later', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sign up",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: LoadingOverlay(
        isLoading: _loading,
        progressIndicator: Container(
          width: 100,
          child: LinearProgressIndicator(valueColor:AlwaysStoppedAnimation<Color> (appConfiguration.appPrimaryColor),),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: appConfiguration.appAcentColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,color: Colors.black87,),
              onPressed: (){
                Navigator.pop(context);
              },
            ),
          ),
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
                        Align(alignment: Alignment.center,child: Text("SIGN UP",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),),
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
                          child: Align(alignment: Alignment.center,child: Text("or",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top:20),
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
                                Text("Password",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                                Padding(
                                  padding: EdgeInsets.only(top:10,bottom: 20),
                                  child: TextFormField(
                                    controller: passwordController,
                                    validator:(value){
                                      if((!(value.contains(new RegExp(r"[0-9.!#$%&'*+-/=?^_`{|}~]"))) || value.isEmpty) || value.length < 5){
                                        return 'Your password is very week';
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
                                Text("Sponsor (optional)",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                                Padding(
                                  padding: EdgeInsets.only(top:10,bottom: 20),
                                  child: TextFormField(
                                    controller: sponsorController,
                                    obscureText: false,
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
                                       registerUser();
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text("Sign up",style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                                    color: appConfiguration.appSecondaryColor,
                                  ),
                                ),
                                InkWell(
                                  onTap: (){
                                   Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(top:20,bottom: 30),
                                    child: Align(alignment: Alignment.center,
                                      child: RichText(
                                        text: TextSpan(
                                            children: <TextSpan>[
                                              TextSpan(text: "All ready a member?",style: TextStyle(fontFamily: "Mont",color: Colors.black87)),
                                              TextSpan(text: " Login",style: TextStyle(fontFamily: "Mont",color: Colors.blue)),
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
      ),
    );
  }
}
