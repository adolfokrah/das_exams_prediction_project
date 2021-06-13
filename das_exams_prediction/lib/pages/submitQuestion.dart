import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/questionSentPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:http/http.dart' as http;


void main(){
  runApp(SubmitQuestion());
}

class SubmitQuestion extends StatefulWidget {

  final data;

  SubmitQuestion({@required data}):this.data = data;


  @override
  _SubmitQuestionState createState() => _SubmitQuestionState();
}

class _SubmitQuestionState extends State<SubmitQuestion> {
  Config appConfiguration = Config();
  TextEditingController question = TextEditingController();
  var document;
  File _image;
  final picker = ImagePicker();
  var loading  = false;
  var questionData;

  @override
  void initState() {
    super.initState();
    if(widget.data != null){
      if(!mounted) return;
      question.text = widget.data['question_text'];

      setState(() {
        questionData = widget.data;
      });
    }
  }


  Future _chooseDocument()async{
    try{
      FlutterDocumentPickerParams params = FlutterDocumentPickerParams(
          allowedFileExtensions: ['pdf','docx','doc']
      );

      final path = await FlutterDocumentPicker.openDocument(params: params);
      if(!mounted) return;
      setState(() {
        document = path;
      });
    }catch(e){
      Toast.show("Please select a valid document file", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);

    }
  }

  Future getImage(source) async {
    try{
      final pickedFile = await picker.getImage(source: source == 'gallery' ? ImageSource.gallery : ImageSource.camera);

      setState(() {
        if (pickedFile != null) {
          setState(() {
            _image = File(pickedFile.path);
          });
        } else {
          print('No image selected.');
        }
      });
    }catch(e){
      print(e);
    }
  }

  Future sendQuestion()async{
    if(question.text == '' && _image == null && document == null){
      Toast.show("Please type question, attached  an image or document of the question ", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      return;
    }

    if(question.text.length > 1 && question.text.length < 20){
      Toast.show("Your question is too short", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      return;
    }

    try{
      if(!mounted) return;
      setState(() {
        loading = true;
      });

      SharedPreferences storage = await SharedPreferences.getInstance();
      var userData = jsonDecode(storage.getString("userData"));


      var data;
      var   url = '${appConfiguration.apiBaseUrl}submit_question';

      if(widget.data == null){
        data= {
          "user_id": userData['user_id'].toString(),
          "question_text": question.text,
          "status": 'pending',
          "file": "",
          "photo":"",
          "photoName":"",
          "question_pic":"",
          "edit" : "false"
        };
      }else{
        data= {
          "user_id": widget.data['user_id'].toString(),
          "question_text": question.text,
          "status": 'pending',
          "file": questionData['file'].toString(),
          "photo":"",
          "photoName":"",
          "question_pic":questionData['question_pic'].toString(),
          "edit" : "true",
          "sq_id": widget.data['sq_id'].toString()
        };

      }




      var request = new http.MultipartRequest("POST", Uri.parse(url));
      request.fields.addAll(data);

      if(document != null){
        http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
            'doc', document);
        request.files.add(multipartFile);
      }

      if(_image != null){

        http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
            'photo', _image.path);
        request.files.add(multipartFile);
        String fileName = _image.path.split("/").last;

        data['photoName'] = fileName;
      }

      http.StreamedResponse response = await request.send();


      if(!mounted) return;
      setState(() {
        loading = false;
      });

      print(response.stream);
      Toast.show("Question Submitted", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);

      if(widget.data != null){
        Navigator.pop(context,'done');
      }else{

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (BuildContext context) => SentPage()));
      }
    }catch(e){
      print(e);
      if(!mounted) return;
      setState(() {
        loading = false;
      });
      Toast.show("Connection failed. Please try again", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
    }

  }

  Future showModal()async{
    await showMaterialModalBottomSheet(
      context: context,
      expand: false,
      builder: (context) => Container(
        height: 150,
        child: ListView(
          children: [
            InkWell(
              child: ListTile(
                onTap: (){
                  getImage("gallery");
                  Navigator.pop(context);
                },
                leading: Icon(Icons.photo),
                title: Text("Gallery",style: TextStyle(fontFamily: "Mont"),),
              ),
            ),
            InkWell(
              child: ListTile(
                onTap: (){
                  getImage("camera");
                  Navigator.pop(context);
                },
                leading: Icon(Icons.photo_camera_outlined),
                title: Text("Take Photo",style: TextStyle(fontFamily: "Mont"),),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.data != null ? "Edit Question" : "Submit a question",
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
              title: Text(widget.data != null ? "Edit Question" : "Submit a question"),
              actions: [
                IconButton(icon: Icon(Icons.send, color: Colors.white,), onPressed: (){
                  sendQuestion();
                })
              ]
          ),
          body: content(),
        ),
      ),
    );
  }
  Widget content(){
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text("Question",style: TextStyle(fontFamily: "Mont")),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextFormField(
            controller: question,
            decoration: InputDecoration(
              hintText: "Type your question here",

            ),
            keyboardType: TextInputType.multiline,
            maxLines: 20,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Container(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),

              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                     Container(
                       child:_image  != null || questionData!=null && questionData['question_pic'] != '' ? Stack(
                         children: [
                           _image != null ? Image.file(_image) : CachedNetworkImage(
                             imageUrl: questionData['question_pic'],
                             placeholder: (context, url) => CircularProgressIndicator(),
                             errorWidget: (context, url, error) => Icon(Icons.error),
                           ),
                           IconButton(icon: Icon(Icons.close,color: Colors.white,), onPressed: (){
                             if(!mounted) return;
                             setState(() {
                               _image = null;
                             });
                             if(questionData['question_pic'] != ''){
                               var datam = questionData;
                               datam['question_pic'] = '';
                               setState(() {
                                 questionData = datam;
                               });
                               print(questionData);
                             }
                           })
                         ],
                       ) : CircleAvatar(
                         radius: 40,
                         backgroundColor: Color(0xffFBA040),
                         child: Icon(Icons.add_a_photo,color: Colors.white,size: 40,),
                       ),
                     ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Attach a Photo to this question"),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: (){
                        showModal();
                      },
                          child: Text(_image != null || questionData!=null && questionData['question_pic'] != '' ? "Change Image" : "Add photo"),
                          style: ElevatedButton.styleFrom(
                              primary: appConfiguration.appPrimaryColor,
                              onPrimary: Colors.white,
                          )
                      ),
                    ),

                  ],
                ),
              ),

            ),
          )
        ),
        Padding(
            padding: const EdgeInsets.only(left: 40.0,right:40,bottom: 10),
            child: Container(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),

                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xffFBA040),
                        child: Icon(Icons.file_copy,color: Colors.white,size: 40,),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: document != null || questionData!=null &&  questionData['file'] != '' ? Row(
                          children: [
                            Flexible(child: Text(document != null ? document.split('/')[document.split('/').length-1] :  questionData['file'])),
                            IconButton(icon: Icon(Icons.close), onPressed: (){
                              if(!mounted) return;
                              setState(() {
                                questionData['file'] = '';
                                document = null;
                              });
                            })
                          ],
                        ) : Text("Attach a Document to this question"),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(onPressed: (){
                          _chooseDocument();
                        },
                            child: Text(document != null || questionData!=null &&  questionData['file'] != ''  ? "Change document" : "Add Document"),
                            style: ElevatedButton.styleFrom(
                              primary: appConfiguration.appPrimaryColor,
                              onPrimary: Colors.white,
                            )
                        ),
                      ),

                    ],
                  ),
                ),

              ),
            )
        )
      ],
    );
  }
}
