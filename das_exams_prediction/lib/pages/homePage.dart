import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:das_exams_prediction/includes/components/drawer.dart';
import 'package:das_exams_prediction/includes/config.dart';
import 'package:das_exams_prediction/pages/examSelction.dart';
import 'package:das_exams_prediction/pages/searchQuestion.dart';
import 'package:das_exams_prediction/pages/submittedQuestions.dart';
import 'package:das_exams_prediction/pages/subscription.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:das_exams_prediction/includes/menuList.dart';

void main(){
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Config appConfiguration = Config();
  var _userData;
  bool _loading = true;
  var _items = [];


  @override
  void initState(){
    super.initState();
    checkUserSession();
  }


  //check if user is already logged in
  Future<void> checkUserSession()async{
    SharedPreferences storage = await SharedPreferences.getInstance();
    var userData = storage.getString("userData");
    if(userData != null){
      //open home page
      setState(() {
        _userData = jsonDecode(userData);
      });

      try{
        //fetch news from wordpress  webiste
        var request = await http.get("https://dasexams.com/wp-json/wp/v2/posts?per_page=3");
        if(request.statusCode == 200){
          var news = jsonDecode(request.body);
          if(!mounted) return;
          setState(() {
            _items = news;
            _loading = false;
          });
        }
      }catch(e){
        print(e);
        setState(() {
          _loading = false;
        });
      }

    }

  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: appConfiguration.appPrimaryColor,
          title: Text("Das Exams Prediction"),
          brightness: Brightness.dark,
        ),
        body: HomeContent(),
        drawer: MyDrawer()
      ),
    );
  }

  Widget HomeContent(){

    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate(
            [

              Padding(
                padding: EdgeInsets.only(top:_loading ? 30 : _items.length > 0 ? 20 : 0),
                child: _loading? Center(child: SizedBox(
                  child: CircularProgressIndicator(),
                  height: 30.0,
                  width: 30.0,
                ),) : null,
              ),
              CarouselSlider(
                  items: _items.map((i) {
                    return Builder(
                      builder: (BuildContext context) {
                        return InkWell(
                          onTap: ()async{
                            if (await canLaunch(i['link'])) {
                              await launch(i['link']);
                            } else {
                              throw 'Could not launch ${i['link']}';
                            }
                          },
                          child: Container(
                              width: MediaQuery.of(context).size.width,
                              margin: EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(5),
                                  image: new DecorationImage(
                                    image: new NetworkImage(i['jetpack_featured_media_url']),
                                    fit: BoxFit.cover,
                                  )
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black, Colors.transparent])
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(i['title']['rendered'], style: TextStyle(color: Colors.white, fontSize: 17,fontWeight: FontWeight.bold),),
                                      Text(DateFormat('EEEE, d MMM, yyyy').format(DateTime.parse(i['modified'])).toString(), style: TextStyle(color:Colors.white,fontSize: 16))
                                    ],
                                  ),
                                ),
                              )
                          ),
                        );
                      },
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: _items.length > 0 ? 200 : 5,
                    aspectRatio: 16/9,
                    viewportFraction: 0.8,
                    initialPage: 0,
                    enableInfiniteScroll: true,
                    reverse: false,
                    autoPlay: false,
                    autoPlayInterval: Duration(seconds: 3),
                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    // enlargeCenterPage: true,
                    onPageChanged: null,
                    scrollDirection: Axis.horizontal,
                  )
              ),
              Padding(
                padding: EdgeInsets.only(top:20),
              )
            ],
          ),
        ),
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          delegate: SliverChildListDelegate(
            [
              for(var item in items) InkWell(
                onTap: ()async{
                   if(item['title'] == 'search'){
                     if(_userData['expired'] == 'true'){

                       await Navigator.push(
                           context, MaterialPageRoute(builder: (BuildContext context) => Subscription()));
                       checkUserSession();
                       return;
                     }

                     Navigator.push(
                         context, MaterialPageRoute(builder: (BuildContext context) => SearchQuestionPage()));
                   }

                   if(item['link']==''){
                     if(item['title'] == 'BECE/WASSCE Assitant'){


                       if(_userData['expired'] == 'true'){

                         await Navigator.push(
                             context, MaterialPageRoute(builder: (BuildContext context) => Subscription()));
                         checkUserSession();
                         return;
                       }else{
                         Navigator.push(
                             context, MaterialPageRoute(builder: (BuildContext context) => SubmittedQuestions(userId: _userData['user_id'],)));
                       }
                       return;
                     }
                     Navigator.push(
                         context, MaterialPageRoute(builder: (BuildContext context) => ExamSelection(examsType: item['title'])));
                   }
                },
                child: Container(
                  margin: EdgeInsets.all(5),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      border: Border.all(color: appConfiguration.appPrimaryColor, width: 2.0),
                      borderRadius: BorderRadius.circular(5),
                      color: Color(0xffe9e9e9)
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                         item['icon'],
                         Padding(
                             padding: EdgeInsets.only(top:10,bottom:10),
                             child: Text(item['heading'],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17),textAlign: TextAlign.center,)),
                         Text(item['caption'], textAlign: TextAlign.center,style: TextStyle(fontSize: 16),)
                      ],
                    ),
                  ),
                ),
              )
            ]
          ),
        ),
      ],
    );
  }
}
