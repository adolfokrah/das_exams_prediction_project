import 'package:das_exams_prediction/includes/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main(){
  runApp(PlayVideoContent());
}

class PlayVideoContent extends StatefulWidget {

  final videoId;
  PlayVideoContent({@required videoId}):this.videoId = videoId;

  @override
  _PlayVideoContentState createState() => _PlayVideoContentState();
}

class _PlayVideoContentState extends State<PlayVideoContent> {
  Config appConfiguration = Config();
  YoutubePlayerController _controller;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    _controller.toggleFullScreenMode();

  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        return true;
      },
      child: OrientationBuilder(builder:
          (BuildContext context, Orientation orientation) {
        if (orientation == Orientation.landscape) {
          return Scaffold(
            body: youtubeHierarchy(),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              brightness: Brightness.dark,
              title: Text("Video"),
            ),
            body: youtubeHierarchy(),
          );
        }
      }),
    );
  }

  youtubeHierarchy() {
    return Container(
      child: Align(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.fill,
          child: YoutubePlayer(
            controller: _controller,
          ),
        ),
      ),
    );
  }
}
