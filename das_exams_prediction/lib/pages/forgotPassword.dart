import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/registerPage.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(ForgotPassword());
}

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  Config appConfiguration = Config();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Forgot passsword",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      home: Scaffold(
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
                      Align(alignment: Alignment.center,child: Text("Forgot Password",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),),

                      Padding(
                        padding: EdgeInsets.only(top:20),
                        child: Form(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                              Padding(
                                padding: EdgeInsets.only(top:10,bottom: 20),
                                child: TextFormField(
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
                                child: FlatButton(
                                  onPressed: (){
                                    Navigator.push(
                                        context, MaterialPageRoute(builder: (BuildContext context) => RegisterPage()));
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text("Send",style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.w700)),
                                  color: appConfiguration.appSecondaryColor,
                                ),
                              ),

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
