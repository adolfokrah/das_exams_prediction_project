
import 'dart:convert';

import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/submitQuestion.dart';
import 'package:das_exams_prediction/pages/viewSubmittedQuestion.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
void main(){
  runApp(SubmittedQuestions());
}


class SubmittedQuestions extends StatefulWidget {
  final userId;

  SubmittedQuestions({@required userId, @required questions}):this.userId = userId;

  @override
  _SubmittedQuestionsState createState() => _SubmittedQuestionsState();
}

class _SubmittedQuestionsState extends State<SubmittedQuestions> {
  Config appConfiguration = Config();
  var currentQuestion = 1;
  var loading = true;
  var answeredQuestions =[];
  var pendingQuestions =[];
  var pendingQuestionsStart = 0;
  var answeredQuestionsStart = 0;
  ScrollController _pendingScrollController = ScrollController();
  ScrollController _answeredScrollController = ScrollController();
  var failed = false;

  // TtsState ttsState = TtsState.stopped;


  @override
  void initState(){
    super.initState();
    fetchQuestions(0,'all');
    _pendingScrollController.addListener(() {
      if(_pendingScrollController.position.pixels == _pendingScrollController.position.maxScrollExtent){
        fetchQuestions(pendingQuestionsStart, 'pending');
      }
    });

    _answeredScrollController.addListener(() {
      if(_answeredScrollController.position.pixels == _answeredScrollController.position.maxScrollExtent){
        fetchQuestions(answeredQuestionsStart, 'answered');
      }
    });
  }


  Future fetchQuestions(start,type)async{
     try{
       if(!mounted) return;
       setState(() {
         loading = true;
         failed = false;
       });
       String url = '${appConfiguration.apiBaseUrl}getSubmittedQuestions/${widget.userId.toString()}/${start.toString()}/${type.toString()}';
       var req = await http.get(url);
       var response = jsonDecode(req.body);


       var pendingQuestionsData = [];
       var answeredQuestionsData =[];

       if(type == 'pending' && response['pendingQuestions'].length != pendingQuestions){
         pendingQuestionsData = new List.from(pendingQuestions)..addAll(response['pendingQuestions']);
         if(!mounted) return;
         setState(() {
           pendingQuestionsStart = pendingQuestionsStart + 5;
         });
       }

       if(type == 'answered' && response['answeredQuestions'].length != answeredQuestions){
         answeredQuestionsData = new List.from(answeredQuestions)..addAll(response['answeredQuestions']);
         if(!mounted) return;
         setState(() {
           answeredQuestionsStart = answeredQuestionsStart + 5;
         });
       }

       if(type == 'all'){
         pendingQuestionsData  = response['pendingQuestions'];
         answeredQuestionsData = response['answeredQuestions'];

         if(!mounted) return;
         if(answeredQuestionsData.length > 0){
           setState(() {
             answeredQuestionsStart = answeredQuestionsStart + 5;
           });
         }

         if(pendingQuestionsData.length > 0){
           setState(() {
             pendingQuestionsStart = pendingQuestionsStart + 5;
           });
         }

       }

       if(!mounted) return;
       setState(() {
         loading = false;
         pendingQuestions = pendingQuestionsData.length > 0 || type == 'all' ?  pendingQuestionsData : pendingQuestions;
         answeredQuestions = answeredQuestionsData.length > 0 || type == 'all' ? answeredQuestionsData : answeredQuestions;
       });
       return true;
     }catch(e){
       if(!mounted) return;
       setState(() {
         failed = true;
       });
     }
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Submitted Questions',
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            brightness: Brightness.dark,
            leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
              Navigator.pop(context);
            },),
            backgroundColor: appConfiguration.appPrimaryColor,
            title: Text('Submitted Questions'),
            actions: [
              IconButton(icon: Icon(Icons.add, color: Colors.white,), onPressed: ()async{
                var data = await Navigator.push(
                    context, MaterialPageRoute(builder: (BuildContext context) => SubmitQuestion(data: null)));

      setState(() {
        pendingQuestionsStart = 0;
        answeredQuestionsStart = 0;
      });
      fetchQuestions(0, 'all');
              })
            ],
            bottom: TabBar(
              labelStyle: TextStyle(fontFamily: "Mont"),
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Pending Questions' ),
                Tab(text: 'Answered Questions'),
              ],
            )
          ),
          body: content(),
        ),
      ),
    );
  }

  Widget content(){
    return TabBarView(
      children: [
        Tab(
          child: pendingQuestionsStart == 0 && loading ? CircularProgressIndicator() :
              pendingQuestions.length < 1 && pendingQuestionsStart == 0 ? noItems():
              ListView.separated(
            separatorBuilder: (context, index)=>Divider(),
            controller: _pendingScrollController,
            itemBuilder: (BuildContext context, int index) {
              if(index == pendingQuestions.length){
                 if(loading){
                   return Padding(
                       padding: EdgeInsets.all(10),
                       child: CupertinoActivityIndicator()
                   );
                 }else{
                   return Container();
                 }
              }
              return InkWell(
                onTap: ()async{
                  var data = await Navigator.push(
                      context, MaterialPageRoute(builder: (BuildContext context) => ViewSubmittedQuestions(questionsData: pendingQuestions[index])));
                  if(data != ''){
                    if(!mounted) return;
                    setState(() {
                      pendingQuestionsStart = 0;
                      answeredQuestionsStart = 0;
                    });
                    fetchQuestions(0, 'all');
                  }
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.book_outlined,color: Colors.black45,),
                  ),
                  trailing: Icon(Icons.chevron_right),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEEE, d MMM, yyyy hh:mm a').format(DateTime.parse(pendingQuestions[index]['date'])).toString(), style: TextStyle(color:Colors.black,fontFamily: "Mont")),
                      Text("Submiited on",style: TextStyle(fontStyle: FontStyle.italic,color: Colors.black45),)
                    ],

                  ),
                ),
              );
            },
            itemCount: pendingQuestions.length + 1,
          ),
        ),
        Tab(
          child: answeredQuestionsStart == 0 && loading ? CircularProgressIndicator():
              answeredQuestions.length < 1 && answeredQuestionsStart == 0 ? noItems() :
          ListView.separated(
            separatorBuilder: (context, index)=>Divider(),
            controller: _answeredScrollController,
            itemBuilder: (BuildContext context, int index) {
              if(index == answeredQuestions.length){
                if(loading){
                  return Padding( 
                      padding: EdgeInsets.all(10),
                      child: CupertinoActivityIndicator()
                  );
                }else{
                  return Container();
                }
              }
              return InkWell(
                onTap: ()async{
                  var data = await Navigator.push(
                      context, MaterialPageRoute(builder: (BuildContext context) => ViewSubmittedQuestions(questionsData: answeredQuestions[index])));
                  if(data != ''){

                    if(!mounted) return;
                    setState(() {
                      pendingQuestionsStart = 0;
                      answeredQuestionsStart = 0;
                    });
                    fetchQuestions(0, 'all');
                  }
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.book_outlined,color: Colors.black45,),
                  ),
                  trailing: Icon(Icons.chevron_right),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEEE, d MMM, yyyy hh:mm a').format(DateTime.parse(answeredQuestions[index]['date'])).toString(), style: TextStyle(color:Colors.black,fontFamily: "Mont")),
                      Text("Submiited on",style: TextStyle(fontStyle: FontStyle.italic,color: Colors.black45),)
                    ],

                  ),
                ),
              );
            },
            itemCount: answeredQuestions.length + 1,
          ),
        )
  ]
    );
  }

  Widget noItems(){
    if(failed && pendingQuestions.length < 1 && answeredQuestions.length < 1){
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Connection failed",style: TextStyle(fontFamily: "Mont"),),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: appConfiguration.appPrimaryColor,
                    onPrimary: Colors.white
                ),
                child: Text("Reload"),
                onPressed: (){
                  fetchQuestions(0,'all');
                })
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text("You have no questions here",style: TextStyle(fontFamily: "Mont"),),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: appConfiguration.appPrimaryColor,
                  onPrimary: Colors.white
              ),
              child: Text("Submit a question"),
              onPressed: ()async{
                var data = await Navigator.push(
                    context, MaterialPageRoute(builder: (BuildContext context) => SubmitQuestion(data: null)));
                if(data != null){
                  setState(() {
                    pendingQuestionsStart = 0;
                    answeredQuestionsStart = 0;
                  });
                  fetchQuestions(0, 'all');
                }
              })
        ],
      ),
    );
  }

}
