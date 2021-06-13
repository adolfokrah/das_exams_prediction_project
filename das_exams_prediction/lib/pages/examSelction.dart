import 'package:das_exams_prediction/pages/subscription.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:das_exams_prediction/includes/config.dart';
import 'dart:convert';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:das_exams_prediction/pages/fetch_subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

void main(){
  runApp(ExamSelection());
}

class ExamSelection extends StatefulWidget {
  final examsType;

  ExamSelection({@required examsType}):this.examsType = examsType;
  @override
  _ExamSelectionState createState() => _ExamSelectionState();
}

class _ExamSelectionState extends State<ExamSelection> {
  Config appConfiguration = Config();
  var _loading = true;
  var _fetching = false;
  var years;
  var _userData;


  @override
  void initState(){
    super.initState();
    getYears(widget.examsType);
  }

  Future<void> getYears(examsType)async{
    try{
      String url = '${appConfiguration.apiBaseUrl}getYears/${examsType.toUpperCase()}';
      var req = await http.get(url);
      var response = req.body;


      SharedPreferences storage = await SharedPreferences.getInstance();
      var userData = storage.getString("userData");
      if (userData != null) {
        //open home page
        setState(() {
          _userData = jsonDecode(userData);
        });
      }
      setState(() {
        years = jsonDecode(response);
        _loading = false;
      });
    }catch(e){
      Toast.show('Connection failed, please try again', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      Navigator.pop(context);
    }
  }

  Future<void> fetchTopics(year) async{
      try{
        if(!mounted) return;
        setState(() {
          _fetching = true;
        });
        String url = '${appConfiguration.apiBaseUrl}getSubjects/${year.toString()}/${years[0]['e_id'].toString()}/${_userData['user_id']}';

        var req = await http.get(url);
        var response = req.body;

        setState(() {
          _fetching = false;
        });

        if(req.statusCode == 201){
          Navigator.push(
              context, MaterialPageRoute(builder: (BuildContext context) => Subscription()));
          return;
        }

        Navigator.push(
            context, MaterialPageRoute(builder: (BuildContext context) => ExamSubjects(subjects: response,examType: years[0]['e_id'],examTypeName: widget.examsType)));

      }catch(e){
        setState(() {
           _fetching = false;
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Select Exam",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: LoadingOverlay(
        isLoading: _fetching,
        child: SafeArea(
            child: Scaffold(
                appBar: AppBar(
                  brightness: Brightness.dark,
                  leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
                    Navigator.pop(context);
                  },),
                  backgroundColor: appConfiguration.appPrimaryColor,
                  title: Text(widget.examsType+" - Select Year"),
                ),
                body: _loading ? Align(alignment: Alignment.center,child: CircularProgressIndicator(),) : Padding(
                  padding: EdgeInsets.all(10),
                  child: examSelectionCotent(),
                )
            ),
          ),
      ),
    );
  }

  Widget examSelectionCotent(){
    return ListView.builder(
      itemCount: years.length,
      itemBuilder: (context,index){
        return Card(
          child: InkWell(
            onTap: (){
              fetchTopics(years[index]['year']);
            },
            child: ListTile(
              title: Text(years[index]['year'].toString(), style:  TextStyle(fontFamily: "Mont",fontSize: 16)),
              trailing: Icon(Icons.arrow_forward_ios_rounded,size: 15,),
            )
          ) ,
        );
      },
    );
  }
}
