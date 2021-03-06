import 'package:flutter/material.dart';
import 'dart:async';

import 'package:youroccasions/screens/user/diagonally_cut_colored_image.dart';
import 'package:youroccasions/models/user.dart';
import 'package:youroccasions/models/event.dart';
import 'package:youroccasions/controllers/user_controller.dart';
import 'package:youroccasions/controllers/event_controller.dart';
import 'package:youroccasions/screens/home/event_card.dart';
import 'package:youroccasions/models/data.dart';
import 'package:youroccasions/controllers/friend_list_controller.dart';
import 'package:youroccasions/models/friend_list.dart';
import 'package:youroccasions/screens/user/update_user.dart';

final UserController _userController = UserController();
final EventController _eventController = EventController();
final FriendListController friendController = FriendListController();

class UserProfileScreen extends StatefulWidget {
  final User user;

  UserProfileScreen(this.user);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
  
}

class _UserProfileScreenState extends State<UserProfileScreen>{

  User user;
  String id;
  List<Event> _eventList;
  User currentUser = Dataset.currentUser.value;
  bool followed;
  FriendList friend;
  // List<FriendList> following;
  int follower;
  int follow = 0;
  Timer _queryTimer;

  @override
  initState() {
    super.initState();
    user = widget.user;
    if (user.followers == null){
      follower = 0;
    }
    else follower = user.followers;
    friend = FriendList();
    friend.userId = currentUser.id;
    friend.friendId = user.id;
    if (currentUser.id == widget.user.id){
      getdata();
    }
    else{
    _refresh();
    }
  }


    // getUserId().then((value){
    //   setState(() {
    //     id = value;
    //   });
    // });

  void getdata() async {
    var temp1 = await _eventController.getEvents(hostId: widget.user.id);

    var temp2 = (await friendController.getFriendList(userId: widget.user.id)).length;

    setState(() {
          followed = false;
          _eventList = temp1;
          follow = temp2;
        });
  }

  void _refresh() async{
    var temp = await friendController.getFriend(currentUser.id, widget.user.id);

    var temp1 = await _eventController.getEvents(hostId: widget.user.id);

    var temp2 = (await friendController.getFriendList(userId: widget.user.id)).length;

    setState(() {
          followed = temp;
          _eventList = temp1;
          follow = temp2;
        });
  }

  void _handleTimer() {
    if(!followed) {
      setState(() {
        follower-=1;
      });
      // follower-=1;
      _delete();
    }
    else{
      setState(() {
        follower+=1;
      });
      // follower+=1;
      _add();
    }
    _queryTimer = null;
  }

  Future<void> getCurrentUser(String id) async {
    List<User> currentUser = await _userController.getUsers(id: id);
    print(currentUser);
    Dataset.currentUser.value.followers = currentUser[0].followers;
    setState(() {
      follower = currentUser[0].followers;
    });
  }

  void _add() async{
    var isFollowed = await friendController.getFriend(currentUser.id, user.id);
    if (!isFollowed){
      // print(friend.friendId);
      await friendController.insert(friend);      
      // await _userController.increaseFollowers(widget.user.id);
      // await friendController.insert(friend);
      // await _userController.increaseFollowers(user.id);
    }
  }

  void _delete() async{
    var isFollowed = await friendController.getFriend(currentUser.id, user.id);
    if (isFollowed){
      await friendController.deleteFriend(currentUser.id, widget.user.id);
      // await _userController.decreaseFollowers(widget.user.id);
      // await friendController.deleteFriend(currentUser.id, widget.user.id);
      
    }
  }
  
  Widget _buildAvatar() {
    return new Hero(
      tag: "User Profile",
      child: new CircleAvatar(
        backgroundImage: user.picture != null? NetworkImage(user.picture) 
        : AssetImage("assets/images/no-avatar2.jpg"),
        radius: 50.0,
      ),
    );
  }

  Widget _buildDiagonalImageBackground(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return new DiagonallyCutColoredImage(
      new Image.network(
        "https://i.imgur.com/dBy4rtg.png",
        width: screenWidth,
        height: 280.0,
        fit: BoxFit.cover,
      ),
      color: const Color(0xBB8338f4),
    );
  }

  List<Widget> _buildUserEventsCardList() {
    List<Widget> cards = List<Widget>();

    // print(_eventList);

    if (_eventList == null || _eventList.length == 0){
      return cards;
    }

    Widget e = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        user == currentUser? "My events" : "${user.name}'s events",
        style: TextStyle(color: Colors.white, fontSize: 30.0, fontFamily: "Niramit")
      ),
    );

    cards.add(e);

    _eventList.sort((b,a) => a.startTime.compareTo(b.startTime));
    _eventList.forEach((Event currentEvent) {
      cards.insert(1, Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SmallEventCard(
          // color: Colors.blue[100],
          event: currentEvent,
          imageURL: currentEvent.picture,
          place: currentEvent.locationName ?? "Unname location",
          time: currentEvent.startTime ?? DateTime.now(),
          title: currentEvent.name ?? "Untitled event" ,
        ),
      ));
    });
    return cards;
  }

  Widget _buildLocationInfo(TextTheme textTheme) {
    return new Row(
      children: <Widget>[
        new Icon(
          Icons.place,
          color: Colors.white,
          size: 16.0,
        ),
        new Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: new Text(
            'Plattsburgh',
            style: textTheme.subhead.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowerInfo(TextTheme textTheme) {
    var followerStyle =
        textTheme.subhead.copyWith(color: Colors.yellow[100]);

    return new Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text('$follow Following', style: followerStyle),
          new Text(
            ' | ',
            style: followerStyle.copyWith(
                fontSize: 24.0, fontWeight: FontWeight.normal),
          ),
          new Text('$follower Followers', style: followerStyle),
        ],
      ),
    );
  }

  Widget _createFollowButton ({
    Color backgroundColor = Colors.transparent,
    Color textColor = Colors.white70,
  }) {
    return new MaterialButton(
        minWidth: 140.0,
        color: backgroundColor,
        textColor: textColor,
        onPressed: () async {
          if (this.mounted) { 
            // friendController.deleteFriend(currentUser.id, id);
            // _userController.decreaseFollowers(user.id);
            setState((){
              followed = !followed;

              if(_queryTimer == null) {
                _queryTimer = Timer(Duration(milliseconds: 500), _handleTimer);
              }
            });
          }
          // else {
          //   // friendController.insert(friend);
          //   // _userController.increaseFollowers(user.id);
          //   setState((){
          //     followed = !followed;
          //     follower+=1;

          //     if(_queryTimer == null) {
          //       _queryTimer = Timer(Duration(seconds: 1), _handleTimer);
          //     }
          //   });
        },
        child: new Text(followed == false ? 'Follow' : 'Following'),
      );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return new Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
      ),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _createFollowButton(
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget body (var textTheme){
    return new Padding(
      padding: const EdgeInsets.all(24.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text(
            user.name,
            style: textTheme.headline.copyWith(color: Colors.white),
          ),
          new Text(
            user.email,
            style: TextStyle(color: Colors.white, fontSize: 14.0)
          ),
          new Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: _buildLocationInfo(textTheme),
          ),
        ],
      )
    );
  }

  String _getDateFormatted(DateTime date) {
    if (date == null) {
      return "";
    }
    return "${date.month.toString().padLeft(2, "0")}/${date.day.toString().padLeft(2, "0")}/${date.year}";
  }

  Widget info(var textTheme){
    return new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text(
            user.name,
            style: textTheme.headline.copyWith(color: Colors.white),
          ),
          new Text(
            user.email,
            style: TextStyle(color: Colors.white, fontSize: 14.0)
          ),
          user.birthday != null?
          new Text(
            _getDateFormatted(user.birthday),
            style: TextStyle(color: Colors.white, fontSize: 14.0),
          )
          : new Text(
            "", 
            style: TextStyle(color: Colors.white, fontSize: 0.0),
          ),
          new Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: _buildLocationInfo(textTheme),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    var screenHeight = MediaQuery.of(context).size.height;
    var theme = Theme.of(context);
    var textTheme = theme.textTheme;
    var linearGradient = const BoxDecoration(
      gradient: LinearGradient(
        begin: FractionalOffset.centerRight,
        end: FractionalOffset.bottomLeft,
        colors: <Color>[
          Colors.deepPurpleAccent,
          Colors.indigoAccent,
          Colors.blueAccent,
          Colors.lightBlue
        ],
      ),
    );

    if (followed == null){
      print(1);
      return Container(
        color: Colors.white,
        child:Center(child: const CircularProgressIndicator())
      );
    }
    return new Scaffold(
      body: new Container(
        height: double.infinity,
        decoration: linearGradient,
        child: new SingleChildScrollView(
          child: user.id == currentUser.id
          ? new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Stack(
                children: <Widget>[
                  new Align(
                    alignment: FractionalOffset.bottomCenter,
                    heightFactor: 1.4,
                    child: new Column(
                      children: <Widget>[
                        _buildAvatar(),
                        _buildFollowerInfo(textTheme),
                        // SizedBox(height: screen.height * 0.4,),
                        // _buildActionButtons(theme),
                      ],
                    ),
                  ),
                  new Positioned(
                    top: 26.0,
                    left: 4.0,
                    child: new BackButton(color: Colors.white),
                  ),
                  new Positioned(
                    top: 26.0,
                    right: 4.0,
                    child: new IconButton(
                      icon: Icon(Icons.edit),
                      color: Colors.white,
                      onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateUserScreen(user)));}
                    ),
                  ),
                ],
              ),
              info(textTheme),
              new Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildUserEventsCardList(),
                )
              ),
            ],
          )
          : new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Stack(
                children: <Widget>[
                  new Align(
                    alignment: FractionalOffset.bottomCenter,
                    heightFactor: 1.4,
                    child: new Column(
                      children: <Widget>[
                        _buildAvatar(),
                        _buildFollowerInfo(textTheme),
                        _buildActionButtons(theme),
                      ],
                    ),
                  ),
                  new Positioned(
                    top: 26.0,
                    left: 4.0,
                    child: new BackButton(color: Colors.white),
                  ),
                ],
              ),
              info(textTheme),
              new Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildUserEventsCardList(),
                )
              ),
            ],
          )
        ),
      ),
    );
  }
}
