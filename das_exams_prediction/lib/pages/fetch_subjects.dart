import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:das_exams_prediction/includes/config.dart';
import 'dart:convert';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:das_exams_prediction/pages/fetch_topics.dart';
import 'package:toast/toast.dart';


void main(){
  runApp(ExamSubjects());
}

class ExamSubjects extends StatefulWidget {
  final subjects;
  final examType;
  final examTypeName;
  ExamSubjects({@required subjects, @required examType, @required examTypeName}):this.subjects = subjects,this.examType = examType,this.examTypeName = examTypeName;
  @override
  _ExamSubjectsState createState() => _ExamSubjectsState();
}

class _ExamSubjectsState extends State<ExamSubjects> {
  Config appConfiguration = Config();
  var _loading = false;
  var _fetching = false;
  var _subjects;


  @override
  void initState(){
    super.initState();
    setState(() {
      _subjects = jsonDecode(widget.subjects);
    });
  }

  Future<void> fetchTopics(subject,year) async{
    try{
      if(!mounted) return;
      setState(() {
        _fetching = true;
      });
      String url = '${appConfiguration.apiBaseUrl}getTopics/${subject.toString()}/${widget.examType.toString()}/${year.toString()}';
      var req = await http.get(url);
      var response = req.body;
      setState(() {
        _fetching = false;
      });
      // print(response);

      Navigator.push(
          context, MaterialPageRoute(builder: (BuildContext context) => PredictedTopics(topics: response,examType: widget.examType,year: year.toString(),examTypeName: widget.examTypeName)));
    }catch(e){
      setState(() {
        _fetching = false;
      });
      Toast.show('Connection failed, please try again', context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Select Subject",
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
                title: Text(widget.examTypeName+" - Select Subject"),
              ),
              body: _loading ? Align(alignment: Alignment.center,child: CircularProgressIndicator(),) : Padding(
                padding: EdgeInsets.all(10),
                child: ExamSubjectsCotent(),
              )
          ),
        ),
      ),
    );
  }

  Widget ExamSubjectsCotent(){
    return ListView.builder(
      itemCount: _subjects.length,
      itemBuilder: (context,index){
        return Card(
          child: InkWell(
              onTap: (){
                fetchTopics(_subjects[index]['subject'],_subjects[index]['year']);
              },
              child: ListTile(
                title: Text(_subjects[index]['subject'].toString(), style:  TextStyle(fontFamily: "Mont",fontSize: 16)),
            trailing: Icon(Icons.arrow_forward_ios_rounded,size: 15,),
              )
          ) ,
        );
      },
    );
  }
}
