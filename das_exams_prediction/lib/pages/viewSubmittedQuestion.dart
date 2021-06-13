
import 'package:cached_network_image/cached_network_image.dart';
import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/playVideo.dart';
import 'package:das_exams_prediction/pages/submitQuestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:image_viewer/image_viewer.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

void main(){
  runApp(ViewSubmittedQuestions());
}


class ViewSubmittedQuestions extends StatefulWidget {
  final questionsData;

  ViewSubmittedQuestions({@required questionsData}):this.questionsData = questionsData;

  @override
  _ViewSubmittedQuestionsState createState() => _ViewSubmittedQuestionsState();
}

class _ViewSubmittedQuestionsState extends State<ViewSubmittedQuestions> {
  Config appConfiguration = Config();
  var currentQuestion = 1;
  FlutterTts flutterTts = FlutterTts();
  var playing = false;
  var loading = false;
  // TtsState ttsState = TtsState.stopped;


  @override
  void initState(){
    super.initState();

    initDownload();

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

  Future initDownload()async{
    try{
      WidgetsFlutterBinding.ensureInitialized();
      await FlutterDownloader.initialize(
          debug: true // optional: set false to disable printing logs to console
      );
    }catch(e){

    }

  }

  Future downloadFile(file)async{

    final status =await Permission.storage.request();

    if(status.isGranted){
      final  externalDir = await getExternalStorageDirectory();

      final taskId = await FlutterDownloader.enqueue(
        url: appConfiguration.uploadPath+'docs/'+file,
        savedDir: externalDir.path,
        fileName: file,
        showNotification: true, // show download progress in status bar (for Android)
        openFileFromNotification: true, // click on notification to open downloaded file (for Android)
      );
    }else{
       print('Permission denied');
    }

  }

  void _onSelect(value)async{
     try{
       if(value == 2){
         if(!mounted) return;
         setState(() {
           loading = true;
         });
         String url = Uri.encodeFull('${appConfiguration.apiBaseUrl}delete_question/${widget.questionsData['sq_id']}');
         var req = await http.get(url);

         Navigator.pop(context,widget.questionsData['sq_id']);
         if(!mounted) return;
         setState(() {
           loading = false;
         });
       }else{
        var data = await Navigator.push(
             context, MaterialPageRoute(builder: (BuildContext context) => SubmitQuestion(data: widget.questionsData)));
        if(data != null){
          Navigator.pop(context);
        }
       }
     }catch(e){
       print(e);
     }
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: "Submitted Question",
      theme: ThemeData(
          primaryColor: appConfiguration.appPrimaryColor
      ),
      debugShowCheckedModeBanner: false,
      home: LoadingOverlay(
        isLoading: loading,
        child: Scaffold(
          appBar: AppBar(
            brightness: Brightness.dark,
            leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.white), onPressed: (){
              Navigator.pop(context);
            },),
            backgroundColor: appConfiguration.appPrimaryColor,
            title: Text("Submitted Qeustion"),
            actions: [
              PopupMenuButton(
                onSelected: _onSelect,
                itemBuilder: (BuildContext context) => widget.questionsData['status'] == 'pending' ? [
                  const PopupMenuItem(
                    value: 1,
                    child: Text('Edit Question'),
                  ),
                  const PopupMenuItem(
                    value: 2,
                    child: Text('Delete Question'),
                  ),
                ] : [
                  const PopupMenuItem(
                    value: 2,
                    child: Text('Delete Question'),
                  )
                ],
              )
            ],
          ),
          body: viewQuestionsContent(),
        ),
      ),
    );
  }

  Widget viewQuestionsContent(){
    return Container(
      color: Color(0xffdee2e6),
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.all(10),
              child: Text(DateFormat('EEEE, d MMM, yyyy hh:mm a').format(DateTime.parse(widget.questionsData['date'])).toString(), style: TextStyle(color:Colors.black,fontFamily: "Mont")),
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
          )
        ],
      ),
    );
  }

  questions(){
    List <Widget> list = List<Widget>();
    list.add(
        Text('Q. '+widget.questionsData['question_text'],style: TextStyle(fontFamily: "Mont",fontSize: 15))

    );

    if(widget.questionsData['question_pic'] != null && widget.questionsData['question_pic'] != ""){
      list.add(
          InkWell(
            onTap: (){
              ImageViewer.showImageSlider(
                images: [
                  widget.questionsData['question_pic']
                ],
                startingPosition: 1,
              );
            },
            child: Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.only(left:20,right:20,top: 10, bottom: 20),
              child:  CachedNetworkImage(
                imageUrl: widget.questionsData['question_pic'],
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          )
      );
    }

    if(widget.questionsData['file'] != null && widget.questionsData['file'] != ""){
      list.add(
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text("Attached file"),
        )
      );
      list.add(
          InkWell(
            onTap: (){
              downloadFile(widget.questionsData['file']);
            },
            child: Container(
              padding: EdgeInsets.only(left:20,right:20,top: 10, bottom: 20),
              child:  Row(
                children: [
                  Container(
                    width: 200,
                    child: Text(widget.questionsData['file'],
                      overflow: TextOverflow.ellipsis,
                      style: new TextStyle(
                        fontSize: 13.0,
                        fontFamily: 'Roboto',
                        color: new Color(0xFF212121),
                        fontWeight: FontWeight.bold,
                      )),
                  ),
                  Icon(Icons.download_rounded)
                ],
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
    if(widget.questionsData['status'] == 'pending'){
      return list;
    }
    list.add(
        Container(
          padding: EdgeInsets.only(left:20,right:20,top: 20, bottom: 10),
          child:  Text("Answers",style: TextStyle(fontFamily: "Mont",fontSize: 15)),
        )
    );

    list.add(Divider());

    if(widget.questionsData['a_text'] != null && widget.questionsData['a_text'] != ''){
      list.add(
          Container(
            padding: EdgeInsets.only(left:20,right:20,top: 10, bottom: 20),
            child:  Text(widget.questionsData['a_text'],style: TextStyle(fontFamily: "Mont",fontSize: 15,fontWeight: FontWeight.bold)),
          )
      );
    }

    if(widget.questionsData['qa_file'] != null && widget.questionsData['qa_file'] != ""){
      list.add(
          Padding(
            padding: EdgeInsets.only(top: 10,left: 20),
            child: Text("Attached file"),
          )
      );
      list.add(
          InkWell(
            onTap: (){
              downloadFile(widget.questionsData['qa_file']);
            },
            child: Container(
              padding: EdgeInsets.only(left:30,right:20,top: 10, bottom: 20),
              child:  Row(
                children: [
                  Container(
                    width: 200,
                    child: Text(widget.questionsData['qa_file'],
                        overflow: TextOverflow.ellipsis,
                        style: new TextStyle(
                          fontSize: 13.0,
                          fontFamily: 'Roboto',
                          color: new Color(0xFF212121),
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  Icon(Icons.download_rounded)
                ],
              ),
            ),
          )
      );
    }
    if(widget.questionsData['a_photo'] != null && widget.questionsData['a_photo'] != ""){
      list.add(
          InkWell(
            onTap: (){
              ImageViewer.showImageSlider(
                images: [
                  widget.questionsData['a_photo']
                ],
                startingPosition: 1,
              );
            },
            child: Container(
              padding: EdgeInsets.only(left:20,right:20,top: 10, bottom: 20),
              child:  CachedNetworkImage(
                imageUrl: widget.questionsData['a_photo'],
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          )
      );
    }

    if(widget.questionsData['a_video'] != null && widget.questionsData['a_video'] != ""){
      var id = YoutubePlayer.convertUrlToId(widget.questionsData['a_video']);


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
