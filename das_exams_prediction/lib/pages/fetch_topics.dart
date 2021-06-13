import 'package:das_exams_prediction/pages/viewQuestionsPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:das_exams_prediction/includes/config.dart';
import 'dart:convert';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:das_exams_prediction/pages/subscription.dart';
import 'package:toast/toast.dart';

void main(){
  runApp(PredictedTopics());
}

class PredictedTopics extends StatefulWidget {
  final topics;
  final examType;
  final year;
  final examTypeName;

  PredictedTopics({@required topics, @required examType,@required year,@required examTypeName}):this.topics = topics, this.examType = examType, this.year = year,this.examTypeName = examTypeName;
  @override
  _PredictedTopicsState createState() => _PredictedTopicsState();
}

class _PredictedTopicsState extends State<PredictedTopics> {
  Config appConfiguration = Config();
  var _loading = false;
  var _fetching = false;
  var _topics = [];
  var _title = 'hello world';
  var _userData;
  var selectedTopic = 0;


  @override
  void initState(){
    super.initState();
    setState(() {
      _topics = jsonDecode(widget.topics)['topics'];
      _title = jsonDecode(widget.topics)['title'];
    });
    checkUserSession();

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

  Future<void> fetchQuestions(section,topicId,topic) async{

    try{

      if(!mounted) return;
      setState(() {
        _fetching = true;
      });
      String url = Uri.encodeFull('${appConfiguration.apiBaseUrl}fetch_questions/${section.toString()}/${topicId.toString()}/${widget.year}/${widget.examType}');
      // print(url);
      var req = await http.get(url);
      var response = req.body;
      setState(() {
        _fetching = false;
      });


      var title = widget.examTypeName+' ('+widget.year+') '+topic+' - '+section;

      var questions = jsonDecode(response);
      Navigator.push(
          context, MaterialPageRoute(builder: (BuildContext context) => ViewQuestionsPage(title: title,questions: questions,questionNumber: 1)));

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
      title: "Select Topic",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: LoadingOverlay(
        isLoading: _fetching,
        child: SafeArea(
          child: Scaffold(
              appBar: AppBar(
                leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
                  Navigator.pop(context);
                },),
                backgroundColor: appConfiguration.appPrimaryColor,
                title: Text(widget.examTypeName+" - Select Topic"),
              ),
              body: _loading ? Align(alignment: Alignment.center,child: CircularProgressIndicator(),) : Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Container(
                      color: Color(0xffcdedff),
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(_title, style: TextStyle(fontFamily: "Mont",fontSize: 15),),
                      ),
                    ),
                    Expanded(
                      child: PredictedTopicsCotent(),
                    )
                  ],
                ),
              )
          ),
        ),
      ),
    );
  }

  Widget PredictedTopicsCotent(){
    return ListView.builder(
      itemCount: _topics.length,
      itemBuilder: (context,index){
        return Card(
          child: InkWell(
              onTap: (){
                // if(index > 4){
                //   if(_userData['expired'] == 'true'){
                //     Navigator.push(
                //         context, MaterialPageRoute(builder: (BuildContext context) => Subscription()));
                //     return;
                //   }
                // }
                setState(() {
                  selectedTopic = index + 1;
                });
              },
              child: Column(
                children: [
                  ListTile(
                    title: Text(_topics[index]['topic'].toString(), style:  TextStyle(fontFamily: "Mont",fontSize: 16)),
                    trailing: Icon(selectedTopic == index + 1 ? Icons.keyboard_arrow_down_rounded : Icons.arrow_forward_ios_rounded,size:selectedTopic == index + 1 ? 25 : 15 ,),
                  ),
                  Container(
                    child: selectedTopic == index + 1 ? Container(
                      margin: EdgeInsets.only(top:0),
                      decoration: BoxDecoration(
                          color: Color(0xfff8f8f8),
                          // borderRadius: BorderRadius.circular(2),
                          border: Border(
                            top: BorderSide(width: 0.8, color: Color(0xffd3d3d3)),
                          ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           for(var sections in _topics[index]['sections']) ListTile(
                             title: Text(sections['type'],style:  TextStyle(fontFamily: "Mont",fontSize: 16)),
                             onTap: (){
                               fetchQuestions(sections['type'], _topics[index]['t_id'],_topics[index]['topic']);
                             },
                           )
                        ],
                      ),
                    ) : null,
                  )
                ],
              ),

          ) ,
        );
      },
    );
  }
}
