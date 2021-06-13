import 'package:das_exams_prediction/includes/config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(SentPage());
}

class SentPage extends StatefulWidget {
  @override
  _SentPageState createState() => _SentPageState();
}

class _SentPageState extends State<SentPage> {
  Config appConfiguration = Config();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Question Sent",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.close,color: Colors.black), onPressed: (){
            Navigator.pop(context);
          },),
          backgroundColor: Colors.white,
        ),
        body: Container(
          color: Colors.white,
          child: Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(children:[
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Color(0xffFBA040),
                  child: Icon(CupertinoIcons.paperplane_fill,color: Colors.white,size: 70,),
                ),
               Padding(padding: EdgeInsets.all(20),
               child:  Text("Thanks, your question has been received, our team of experienced teachers will help provide a solution as soon as possible.",textAlign: TextAlign.center,style: TextStyle(fontFamily: "Mont"),),),
                ElevatedButton(onPressed: (){
                 Navigator.pop(context);
                },
                    child: Text("Okay thanks"),
                    style: ElevatedButton.styleFrom(
                      primary: appConfiguration.appPrimaryColor,
                      onPrimary: Colors.white,
                    )
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
