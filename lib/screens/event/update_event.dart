import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:youroccasions/models/event.dart';
import 'package:youroccasions/controllers/event_controller.dart';
import 'package:youroccasions/utilities/config.dart';
import 'package:youroccasions/utilities/secret.dart';
import 'package:youroccasions/screens/event/event_detail.dart';

import 'package:youroccasions/utilities/cloudinary.dart';

final EventController _eventController = EventController();
bool _isSigningUp = false;

class UpdateEventScreen extends StatefulWidget {
  final Event event;

  UpdateEventScreen(Event event) :  this.event = event;
  
  @override
  _UpdateEventScreen createState() => _UpdateEventScreen();
}

class _UpdateEventScreen extends State<UpdateEventScreen> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey;
  TextEditingController nameController;
  TextEditingController descriptionController;
  TextEditingController categoryController;
  FocusNode _eventTitleNode = FocusNode();
  FocusNode _descriptionNode = FocusNode();
  FocusNode _c = FocusNode();
  DateTime startDate;
  TimeOfDay startTime;
  DateTime endDate;
  TimeOfDay endTime;
  String start;
  String end;
  Event event;
  File _image;
  String _imageURL;

  bool _invalidStart = false;
  bool _invalidEnd = false;
  bool _invalidCategory = false;
  List<String> _selectCategoryName = [];
  List<PopupMenuItem> _selectCategoryOptions = [];

  bool _imageChanged;
  bool _noImageError = false;
  double _contentWidth = 0.8;
  List<PopupMenuItem<ImageSource>> _selectImageOptions = [
    PopupMenuItem<ImageSource>(
      value: ImageSource.gallery,
      child: Text("Choose from gallery"),
    ),
    PopupMenuItem<ImageSource>(
      value: ImageSource.camera,
      child: Text("From camera"),
    ),
  ];

  @override
  initState() {
    super.initState();
    startDate = DateTime.now();
    startTime = TimeOfDay.now();
    event = widget.event;
    _imageChanged = false;
    formKey = GlobalKey<FormState>();
    nameController = TextEditingController(text: widget.event.name ?? "");
    descriptionController = TextEditingController(text: widget.event.description ?? "");
    categoryController = TextEditingController(text: widget.event.category ?? "");
    
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
  }

  void retrieveImageURL() {
    var url = fetch("event_header/${widget.event.id}");
  }
  
  void getImage(ImageSource source) {
    print(_imageChanged);
    ImagePicker.pickImage(source: source).then((image) {
      setState(() {
        _imageChanged = true;
        _image = image;
      });
    });
  }

  bool _autoValidateDateTime() {
    _invalidStart = false;
    _invalidEnd = false;

    if (startDate != null && endDate != null && startDate.compareTo(endDate) > 0) {
      _invalidStart = true;
      print("false here");
      return false;
    }
    if (startDate != null && endDate != null &&  startDate.compareTo(endDate) == 0) {
      if (endTime != null && startTime != null && endTime.hour - startTime.hour < 0) {
        _invalidEnd = true;
        print("false here 2");
        return false;
      }
    }

    return true;
  }

  String _getDateFormatted(DateTime date) {
    if (date == null) {
      return "MM/DD/YYYY";
    }
    return "${date.month.toString().padLeft(2, "0")}/${date.day.toString().padLeft(2, "0")}/${date.year}";
  }

  String _getTimeFormatted(TimeOfDay time) {
    if (time == null) {
      return "HH:MM AM/PM";
    }
    String hour = (time.hour > 12)
      ? (time.hour - 12).toString().padLeft(2, "0")
      : time.hour.toString().padLeft(2, "0");
    String period = (time.hour > 12) ? 'PM' : 'AM';
    return "$hour:${time.minute.toString().padLeft(2, "0")} $period";
  }

  Future<void> popUpSelectStartDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: startDate == null ? DateTime.now() : startDate,
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 2));

    setState(() {
      startDate = picked;
      _autoValidateDateTime();
    });
  }

  Future<void> selectStartTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: startTime == null ? TimeOfDay.now() : startTime
    );

    setState(() {
      startTime = picked;
      _autoValidateDateTime();
    });
  }

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: endDate == null ? DateTime.now() : endDate,
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 2)
    );

    setState(() {
      endDate = picked;
      _autoValidateDateTime();
    });
  }

  Future<void> selectEndTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context, 
      initialTime: endTime == null ? TimeOfDay.now() : endTime
    );

    setState(() {
      endTime = picked;
      _autoValidateDateTime();
    });
  }

  String _getCategoryInput() {
    String result = "";
    _selectCategoryName.forEach((category) {
      result += category;
      if (_selectCategoryName.indexOf(category) != _selectCategoryName.length - 1) {
        result += ", ";
      }
    });
    return result;
  }


  void _submit() async {
    final form = formKey.currentState;

    if (form.validate()) {
      form.save();
      bool result = await update();
      print(result);
      // if(result) {
      //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EventDetailScreen()));
      // }
    }
  }

  Widget selectImageButton() {
    var screen = MediaQuery.of(context).size;

    if (_image == null) {
      return ButtonBar(
        children: <Widget>[
          MaterialButton(
            onPressed: () => getImage(ImageSource.camera),
            child: Text("Get image from camera"),
          ),
          MaterialButton(
            onPressed: () => getImage(ImageSource.gallery),
            child: Text("Get image from gallery"),
          ),
        ] 
      );
    }
    else {
      return SizedBox(
        height: screen.height / 3,
        width: screen.width,
        child: Image.file(_image, fit: BoxFit.fitWidth,)
      );
    }
  }
  
  Widget updateButton() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Material(
          borderRadius: BorderRadius.circular(30.0),
          shadowColor: Colors.lightBlueAccent.shade100,
          elevation: 5.0,
          child: MaterialButton(
            minWidth: 200.0,
            height: 42.0,
            onPressed: () async {
              _submit();
            },
            // color: Colors.lightBlueAccent,
            child: Text('Update', style: TextStyle(color: Colors.black)),
          ),
        ));
  }

  Widget nameForm() {
    return Container(
      margin: const EdgeInsets.all(10.0),
      width: 260.0,
      child: TextFormField(
        controller: nameController,
        keyboardType: TextInputType.emailAddress,
        // validator: (name) => !isPassword(name) ? "Invalid name" : null,
        autofocus: false,
        // initialValue: widget.event.name,
        decoration: InputDecoration(
          hintText: 'Event Name',
          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
        ),
      ));
  }

  Widget descriptionForm() {
    return Container(
        margin: const EdgeInsets.all(10.0),
        width: 260.0,
        child: TextFormField(
          controller: descriptionController,
          keyboardType: TextInputType.emailAddress,
          // validator: (name) => !isPassword(name) ? "Invalid description" : null,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Event Description',
            contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
          ),
        ));
  }

  Widget categoryForm() {
    return Container(
        margin: const EdgeInsets.all(10.0),
        width: 260.0,
        // color: const Color(0xFF00FF00),
        child: TextFormField(
          controller: categoryController,
          keyboardType: TextInputType.emailAddress,
          // validator: (password) => !isName(password) ? "Invalid!" : null,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Category',
            contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
          ),
        ));
  }

  Future<bool> update() async {
    if (!_isSigningUp) {
      _isSigningUp = true;

      String url;
      if(_imageChanged) {
        Cloudinary cl = Cloudinary(CLOUDINARY_API_KEY, API_SECRET);
        url = await cl.upload(file: toDataURL(file: _image), preset: Presets.eventCover, path: "${widget.event.id}/cover");
        print(url);
      }

      final start = new DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
      if (endDate != null){
        endDate = new DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);
      }
      String name = nameController.text;
      String description = descriptionController.text;
      String category = categoryController.text;
      String hostId = await getUserId();
      // String location = "Plattsburgh";
      Event newEvent = Event(hostId: hostId, name: name, description: description, category: category, startTime: start, endTime: endDate);
      print("DEBUG new event is : $newEvent");
      
      if(url != null) {
        _eventController.update(event.id, hostId: hostId, name: name, description: description, category: category, startTime: start, endTime: endDate, picture: url);
      }
      else {
        _eventController.update(event.id, hostId: hostId, name: name, description: description, category: category, startTime: start, endTime: endDate);
      }
      _isSigningUp = false;

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EventDetailScreen(newEvent)));
      return true;
    }
    return false;
  }

  Widget _buildCoverImage() {
    if (_imageURL == null) {
      return selectImageButton();
    }
    else {
      return Image.network(_imageURL);
    }
  }

  void _getImage(ImageSource source) {
    ImagePicker.pickImage(source: source).then((image) {
      if (image != null) {
        if (this.mounted) {
          setState(() {
            _image = image;
          });
        }
      }
    });
  }

  Widget _buildSelectImageSection() {
    var screen = MediaQuery.of(context).size;
    Widget result;

    if (_image == null) {
      result = Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            MaterialButton(
              onPressed: () => _getImage(ImageSource.camera),
              child: Text("Take picture from camera"),
            ),
            MaterialButton(
              onPressed: () => _getImage(ImageSource.gallery),
              child: Text("Get picture from gallery"),
            ),
          ]
        ),
      );
    } else {
      result = Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: <Widget>[
          SizedBox(
            width: screen.width,
            child: Image.file(
              _image,
              fit: BoxFit.fitWidth,
            )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.all(0),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: SizedBox(
                width: 30,
                height: 30,
                child: PopupMenuButton<ImageSource>(
                  onSelected: (item) {
                    print("item selected");
                    print(item.toString());
                    _getImage(item);
                  },
                  child: Icon(
                    Icons.edit,
                    semanticLabel: "Change image",
                    color: Colors.black,
                  ),
                  itemBuilder: (context) => _selectImageOptions,
                )),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildEventTitleInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width * _contentWidth,
      child: TextFormField(
        focusNode: _eventTitleNode,
        controller: nameController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        validator: (name) {
          print("name is $name");
          return (nameController.text.length < 6 || nameController.text.isEmpty) ? "Event title has at least 6 characters" : null;
        },
        autofocus: false,
        onFieldSubmitted: (term) {
          _eventTitleNode.unfocus();
          FocusScope.of(context).requestFocus(_descriptionNode);
        },
        decoration: InputDecoration(
          labelText: "Event Title",
          labelStyle: TextStyle(fontWeight: FontWeight.bold)),
      ));
  }

  Widget _buildDescriptionInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width * _contentWidth,
      child: TextFormField(
        focusNode: _descriptionNode,
        controller: descriptionController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        validator: (name) => (name.length < 6) ? "Please provide a description with at least 6 characters" : null,
        autofocus: false,
        maxLines: null, /// Extend as type
        onFieldSubmitted: (term) {
          _descriptionNode.unfocus();
        },
        maxLengthEnforced: false,
        decoration: InputDecoration(
          labelText: "Description",
          labelStyle: TextStyle(fontWeight: FontWeight.bold)),
      ));
  }

  Widget _buildStartDateInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width * _contentWidth,
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _invalidStart ? Colors.red : Colors.black54,
                  width: 1
                )
              )
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          "Start Date",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          popUpSelectStartDate(context);
                        },
                        child: Text(
                          _getDateFormatted(startDate),
                          style: TextStyle(
                            letterSpacing: 2,
                            fontSize: 14,
                            color: _invalidStart ? Colors.red : startDate == null ? Colors.grey[500] : Colors.black,
                            fontFamily: "Monaco"
                          ),
                        ),
                      ),
                    ],
                  )),
                ),
                Expanded(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            "Time",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            selectStartTime(context);
                          },
                          child: Text(
                            _getTimeFormatted(startTime),
                            style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 14,
                              color: _invalidStart ? Colors.red : startTime == null ? Colors.grey[500] : Colors.black,
                              fontFamily: "Monaco"),
                          ),
                        ),
                      ],
                    )
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _invalidEnd ? Colors.red : Colors.black54,
                  width: 1
                )
              )
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          "End Date",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          selectEndDate(context);
                        },
                        child: Text(
                          _getDateFormatted(endDate),
                          style: TextStyle(
                            letterSpacing: 2,
                            fontSize: 14,
                            color: _invalidEnd ? Colors.red : endDate == null ? Colors.grey[500] : Colors.black,
                            fontFamily: "Monaco"),
                        ),
                      ),
                    ],
                  )),
                ),
                Expanded(
                  child: SizedBox(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          "Time",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          selectEndTime(context);
                        },
                        child: Text(
                          _getTimeFormatted(endTime),
                          style: TextStyle(
                            letterSpacing: 2,
                            fontSize: 14,
                            color: _invalidEnd ? Colors.red : endTime == null ? Colors.grey[500] : Colors.black,
                            fontFamily: "Monaco"),
                        ),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width * _contentWidth,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black54,
              width: 1,
            )
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text("Category",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.bold
                )
              ),
            ),
            PopupMenuButton(
              onSelected: (item) {},
              child: Text(
                _selectCategoryName.isEmpty 
                  ? "Select the category for this event" 
                  : _getCategoryInput(),
                style: TextStyle(
                  fontSize: 15,
                  color: _selectCategoryName.isEmpty ? Colors.black45 : Colors.black
                ),  
              ),
              itemBuilder: (context) => _selectCategoryOptions,
            ),
          ],
        ),
      ),
    );
  }


  List<Widget> _buildListViewContent() {
    List<Widget> result = List<Widget>();

    result.add(
      _buildSelectImageSection(),
    );

    if (_noImageError) {
      result.add(
        Container(
          child: Text(
            "Please add an image for the event!",
            style: TextStyle(
              color: Colors.red
            ),
          ),
        )
      );
    }

    result.addAll([
      _buildEventTitleInput(),
      _buildDescriptionInput(),
      _buildStartDateInput(),
      _buildCategoryInput(),
      // _buildLocationNameInput(),
      // _buildAddressInput(),
      SizedBox(
        height: 30,
      )
    ]);

    // if (_showMap) {
    //   result.addAll([
    //     Padding(
    //       padding: EdgeInsets.symmetric(vertical: 10),
    //       child: _buildGoogleMap()
    //     )
    //   ]);
    // }

    // if (_invalidCategory) {
    //   result.add(
    //     Container(
    //       child: Text(
    //         "Please add at least 1 category for the event!",
    //         style: TextStyle(
    //           color: Colors.red
    //         ),
    //       ),
    //     )
    //   );
    // }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "UPDATE EVENT",
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: _submit,
            child: Text("SAVE",
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 18
              ),
            ),
          )
        ],
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  children: _buildListViewContent(),
                ),
              ),
            )
          ],
        ),
      ));
  }

  // @override
  // Widget build(BuildContext context) {
  //   return new Scaffold(
  //     appBar: AppBar(
  //       title: Text("Update Event"),
  //     ),
  //     body: Center(
  //       child: Form(
  //         key: formKey,
  //         child: ListView(
            
  //           // mainAxisAlignment: MainAxisAlignment.center,
  //           children: <Widget>[
  //             _buildCoverImage(),
  //             nameForm(),
  //             descriptionForm(),
  //             categoryForm(),
  //             new Text('Start Date Selected: $start'),
  //             new RaisedButton(
  //               child: new Text('Select Date'),
  //               onPressed: (){selectStartDate(context);}
  //             ),
  //             new Text('Start Time Selected: ${startTime.toString().substring(10,15)}'),
  //             new RaisedButton(
  //               child: new Text('Select Time'),
  //               onPressed: (){selectStartTime(context);}
  //             ),
  //             new Text('End Date Selected: $end'),
  //             new RaisedButton(
  //               child: new Text('Select Date'),
  //               onPressed: (){selectEndDate(context);}
  //             ),
  //             new Text('End Time Selected: ${endTime.toString()}'),
  //             new RaisedButton(
  //               child: new Text('Select Time'),
  //               onPressed: (){selectEndTime(context);}
  //             ),
  //             updateButton(),
  //           ]
  //         ),
  //       )
  //     )
  //   );
  // }
}