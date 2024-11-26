import 'package:flutter/material.dart';

class RunningTextWidget extends StatefulWidget {
  final String text;
  
  RunningTextWidget({required this.text});
  
  @override
  _RunningTextWidgetState createState() => _RunningTextWidgetState();
}

class _RunningTextWidgetState extends State<RunningTextWidget> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() async {
    while (true) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        await _scrollController.animateTo(
          maxScroll,
          duration: Duration(seconds: 20),
          curve: Curves.linear,
        );
        await _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.green,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
} 