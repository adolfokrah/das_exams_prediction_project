import 'dart:convert';

import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/viewQuestionsPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';

void main(){
  runApp(SearchQuestionPage());
}

class SearchQuestionPage extends StatefulWidget {
  @override
  _SearchQuestionPageState createState() => _SearchQuestionPageState();
}

class _SearchQuestionPageState extends State<SearchQuestionPage> {
  Config appConfiguration = Config();
  TextEditingController search = TextEditingController();
  var examsType = 'BECE School';
  var topics;
  var loading = false;
  var fetching = false;
  var topic = 'Everywhere';
  var questions =[];
  var searched = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchTopics();
  }


  Future fetchTopics()async{
      try{
        if(!mounted) return;
        setState(() {
          loading = true;
        });
        var url = '${appConfiguration.apiBaseUrl}allTopics';
        var request = await http.get(url);


        var topicsData = ['Everywhere'];

        for(var i=0; i<jsonDecode(request.body).length; i++){
          topicsData.add(jsonDecode(request.body)[i]['topic']);
        }

        if(!mounted)return;
        setState(() {
          topics = topicsData;
          loading = false;
          searched = true;
        });


      }catch(e){
        Navigator.pop(context);
        setState(() {
          loading = false;
        });
      }

  }

  Future searchTopic(text)async{
      try{
        if(!mounted) return;
        setState(() {
          fetching = true;
        });
        var url = '${appConfiguration.apiBaseUrl}searchQuestion/${examsType.toString()}/${topic.toString()}/${text.toString()}';
        var request = await http.get(url);
        if(!mounted) return;
        setState(() {
          fetching = false;
          questions = jsonDecode(request.body);
        });
      }catch(e){
        if(!mounted) return;
        setState(() {
          fetching = false;
        });
      }
  }

  Future<void> fetchQuestions(section,topicId,topic,year,questionId,examType) async{

    try{
      if(!mounted) return;
      setState(() {
        loading = true;
      });
      String url = Uri.encodeFull('${appConfiguration.apiBaseUrl}fetch_questions/${section.toString()}/${topicId.toString()}/${year.toString()}/${examType.toString()}');
      // print(url);
      var req = await http.get(url);
      var response = req.body;
      setState(() {
        loading = false;
      });

      var title = '('+year+') '+topic+' - '+section;

      var questions = jsonDecode(response);
      var index = 1;

      var questionsData = questions['questions'];
      for(var i =0; i<questionsData.length; i++){
        if(questionsData[i]['q_id'].toString() == questionId.toString()){
          index = i+1;
          break;
        }
      }
      Navigator.push(
          context, MaterialPageRoute(builder: (BuildContext context) => ViewQuestionsPage(title: title,questions: questions,questionNumber: index,)));

    }catch(e){
      print(e);
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Search Question",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
            Navigator.pop(context);
          },),
          backgroundColor: appConfiguration.appPrimaryColor,
          title: Text("Search Question"),
          elevation: 0,
        ),
        body: LoadingOverlay(
          isLoading: loading,
          child: content(),
        ),
      ),
    );
  }

  Widget content(){
    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          color: appConfiguration.appPrimaryColor,
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0,right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Container(
                   padding: EdgeInsets.all(10),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(5)
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Padding(
                         padding: const EdgeInsets.only(left:2, right:15,top: 2,bottom: 2),
                         child: Icon(Icons.menu,color:Color(0xffFBA040)),
                       ),
                       Expanded(
                         child: DropdownButtonFormField<String>(
                           decoration: InputDecoration.collapsed(
                             filled: true,
                             fillColor: Colors.white
                           ),
                           // isExpanded: true,
                           value: examsType,
                           iconSize: 24,
                           elevation: 16,
                           onChanged: (String newValue) {
                             setState(() {
                               examsType = newValue;
                             });
                           },
                           items: <String>['BECE School', 'WASSCE School','BECE Private','WASSCE Private']
                               .map<DropdownMenuItem<String>>((String value) {
                             return DropdownMenuItem<String>(
                               value: value,
                               child: Text(value,style: TextStyle(fontFamily: "Mont",fontSize: 13)),
                             );
                           }).toList(),
                         ),
                       )
                     ],
                   ),
                 ),
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5)
                  ),
                  child:loading ? Container() :  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left:2, right:15,top: 2,bottom: 2),
                        child: Icon(Icons.book,color:Color(0xffFBA040)),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration.collapsed(
                              filled: true,
                              fillColor: Colors.white
                          ),
                          // isExpanded: true,
                          value: topic,
                          iconSize: 24,
                          elevation: 16,
                          onChanged: (String newValue) {
                            setState(() {
                              topic = newValue;
                            });
                          },
                          items: topics.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,style: TextStyle(fontFamily: "Mont",fontSize: 13)),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: TextFormField(
                    onFieldSubmitted: (e){
                      searchTopic(e);
                    },
                    controller: search,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10),
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search,color: Color(0xffFBA040),),
                      hintText: "Search",
                      filled: true,
                      focusedBorder:OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white, width: 5.0),
                        borderRadius: BorderRadius.circular(5)
                      ),
                        enabledBorder:OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white, width: 2.0),
                          borderRadius: BorderRadius.circular(5)
                      )
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: fetching ? CupertinoActivityIndicator() : questions.length < 1 && searched ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No results found for your search"),
          ) : ListView.separated(
            itemCount: questions.length,
            separatorBuilder: (context,index)=>Divider(),
            itemBuilder: (context,index){
                return InkWell(
                  onTap: (){
                    fetchQuestions(questions[index]['type'],questions[index]['t_id'],questions[index]['topic'],questions[index]['year'],questions[index]['q_id'],questions[index]['exam_type']);
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: appConfiguration.appPrimaryColor,
                      child: Text((index+1).toString(),style: TextStyle(color: Colors.white),),
                    ),
                    title: Text(questions[index]['question'],overflow: TextOverflow.ellipsis,),
                    subtitle: Text(questions[index]['topic'].toString()+'/'+questions[index]['year']+'/'+questions[index]['type']),
                    trailing: Icon(Icons.navigate_next),
                  ),
                );
            },
          ),
        )
      ],
    );
  }
}
