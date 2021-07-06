import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
String email;

class ChatScreen extends StatefulWidget {
  static const id = 'ChatScreen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextConroller = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messageText;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        email = user.email;
        print(email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  _auth.signOut();
                  Navigator.pop(context);
                }),
          ],
          title: Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessageStream(),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextConroller,
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    // ignore: deprecated_member_use
                    FlatButton(
                      onPressed: () {
                        messageTextConroller.clear();
                        _firestore
                            .collection('messages')
                            .add({'text': messageText, 'sender': email, 'timestamp': FieldValue.serverTimestamp()});
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isme});
  final String text;
  final String sender;
  final bool isme;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            '$sender',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          Material(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isme ? 30 : 0),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
                topRight: Radius.circular(isme ? 0 : 30)),
            elevation: 5,
            color: isme ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '$text ',
                style: TextStyle(fontSize: 20, color: isme ? Colors.white : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').orderBy('timestamp').snapshots(),
        // ignore: missing_return
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return (Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            ));
          }
          final messages = snapshot.data.docs.reversed;
          List<MessageBubble> messageWidgets = [];
          for (var message in messages) {
            final messageText = message['text'];
            final messageSender = message.get('sender');
            final messageWidget = MessageBubble(
              sender: messageSender,
              text: messageText,
              isme: messageSender == email,
            );
            messageWidgets.add(messageWidget);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              children: messageWidgets,
            ),
          );
        });
  }
}
