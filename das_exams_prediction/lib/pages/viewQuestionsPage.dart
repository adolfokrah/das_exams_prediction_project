
import 'package:cached_network_image/cached_network_image.dart';
import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/playVideo.dart';
import 'package:flutter/material.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main(){
  runApp(ViewQuestionsPage());
}


class ViewQuestionsPage extends StatefulWidget {
  final title;
  final questions;
  final questionNumber;

  ViewQuestionsPage({@required title, @required questions, @required questionNumber}):this.title = title, this.questions = questions, this.questionNumber = questionNumber;

  @override
  _ViewQuestionsPageState createState() => _ViewQuestionsPageState();
}

class _ViewQuestionsPageState extends State<ViewQuestionsPage> {
  Config appConfiguration = Config();
  var currentQuestion = 1;
  FlutterTts flutterTts = FlutterTts();
  var playing = false;
  // TtsState ttsState = TtsState.stopped;

  @override
  void initState(){
    super.initState();
    if(!mounted)return;

    setState(() {
      currentQuestion = widget.questionNumber;
    });


    flutterTts.setCompletionHandler(() {
      if(!mounted) return;
      setState(() {
        playing = false;
      });
    });

    flutterTts.setStartHandler(() {
      if(!mounted) return;
      setState(() {
        playing = true;
      });
    });

    flutterTts.setCancelHandler(() {
      if(!mounted) return;
      setState(() {
        playing = false;
      });
    });

    flutterTts.setPauseHandler(() {
      if(!mounted) return;
      setState(() {
        playing = false;
      });
    });

  }



  Future _speak(text) async{
    if(playing){
      _pause();
      return;
    }
    var result = await flutterTts.speak(text);
  }

  Future _stop() async{
    var result = await flutterTts.stop();
  }

  Future _pause() async{
    var result = await flutterTts.pause();
  }




  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        title: widget.title,
        theme: ThemeData(
        primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            brightness: Brightness.dark,
            leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
              Navigator.pop(context);
              _stop();
            },),
            backgroundColor: appConfiguration.appPrimaryColor,
            title: Text(widget.title),
          ),
        body: viewQuestionsContent(),
      ),
    );
  }

  Widget viewQuestionsContent(){
    return Container(
      color: Color(0xffdee2e6),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 10,left: 10, right: 10),
            child: Text(widget.title),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.all(10),
              width: 200,
              child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Question "+currentQuestion.toString()+'/'+widget.questions['questions'].length.toString(),style: TextStyle(fontFamily: "Mont",fontWeight: FontWeight.bold,fontSize: 15)),
                  InkWell(
                    onTap: (){
                      _speak('Question '+currentQuestion.toString()+'. '+widget.questions['questions'][currentQuestion-1]['question']);
                    },
                    child: Icon(Icons.volume_up,color:playing ? Colors.deepOrange : Colors.black,),
                  )
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.only(top:10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  child: questions(),
                ),
                Container(
                  margin: EdgeInsets.only(top:10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: answers(),
                  ),
                )
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(10),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left,color: currentQuestion > 1 ? Colors.black45 : Colors.black12,size: 40,),
                  onPressed: (){
                    if(currentQuestion > 1){
                       if(!mounted) return;
                       setState(() {
                         currentQuestion = currentQuestion - 1;
                       });
                       _stop();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.navigate_next,color: currentQuestion < widget.questions['questions'].length ? Colors.black45 : Colors.black12,size: 40,),
                  onPressed: (){
                    if(currentQuestion < widget.questions['questions'].length){
                      if(!mounted) return;
                      setState(() {
                        currentQuestion = currentQuestion + 1;
                      });
                      _stop();

                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  questions(){
    List <Widget> list = List<Widget>();
    list.add(
        Text('Q. '+widget.questions['questions'][currentQuestion-1]['question'],style: TextStyle(fontFamily: "Mont",fontSize: 15))
    );

    if(widget.questions['questions'][currentQuestion-1]['q_photo'] != null && widget.questions['questions'][currentQuestion-1]['q_photo'] != ""){
      list.add(
          InkWell(
            onTap: (){
              ImageViewer.showImageSlider(
                images: [
                  widget.questions['questions'][currentQuestion-1]['q_photo']
                ],
                startingPosition: 1,
              );
            },
            child: Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.only(left:20,right:20,top: 10, bottom: 20),
              child:  CachedNetworkImage(
                imageUrl: widget.questions['questions'][currentQuestion-1]['q_photo'],
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          )
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
    );
  }

  List<Widget> answers(){
    List <Widget> list = List<Widget>();
    list.add(
       Container(
         padding: EdgeInsets.only(left:20,right:20,top: 20, bottom: 10),
         child:  Text("Answers",style: TextStyle(fontFamily: "Mont",fontSize: 15)),
       )
    );

    list.add(Divider());

    if(widget.questions['questions'][currentQuestion-1]['a_text'] != null && widget.questions['questions'][currentQuestion-1]['a_text'] != ''){
      list.add(
          Container(
            padding: EdgeInsets.only(left:20,right:20,top: 10, bottom: 20),
            child:  Text(widget.questions['questions'][currentQuestion-1]['a_text'],style: TextStyle(fontFamily: "Mont",fontSize: 15,fontWeight: FontWeight.bold)),
          )
      );
    }
    if(widget.questions['questions'][currentQuestion-1]['a_photo'] != null && widget.questions['questions'][currentQuestion-1]['a_photo'] != ""){
      list.add(
          InkWell(
            onTap: (){
              ImageViewer.showImageSlider(
                images: [
                  widget.questions['questions'][currentQuestion-1]['a_photo']
                ],
                startingPosition: 1,
              );
            },
            child: Container(
              padding: EdgeInsets.only(left:20,right:20,top: 10, bottom: 20),
              child:  CachedNetworkImage(
                imageUrl: widget.questions['questions'][currentQuestion-1]['a_photo'],
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          )
      );
    }

    if(widget.questions['questions'][currentQuestion-1]['a_video'] != null && widget.questions['questions'][currentQuestion-1]['a_video'] != ""){

      var id = YoutubePlayer.convertUrlToId(widget.questions['questions'][currentQuestion-1]['a_video']);


      list.add(
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: EdgeInsets.all(5),
              width: double.infinity,
              decoration: BoxDecoration(
                color: appConfiguration.appPrimaryColor
              ),
              child: InkWell(
                onTap: (){
                  Navigator.push(
                      context, MaterialPageRoute(builder: (BuildContext context) => PlayVideoContent(videoId: id)));
                },
                child: Row(
                 children: [
                   Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Icon(Icons.play_arrow,color: Colors.white,),
                   ),
                   Text("Play Attached Video",style: TextStyle(color: Colors.white),)
                 ],
                ),
              ),
            ),
          )
      );
    }

    return list;
  }
}
