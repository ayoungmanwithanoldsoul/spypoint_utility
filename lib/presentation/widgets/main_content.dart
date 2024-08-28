import 'package:flutter/material.dart';

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      color: Colors.blue[600],
      child: Column(
        children: [
          Container(
            height: 60,
            color: Colors.orange,
            padding: EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Sample Title",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(color: Colors.black)),
                Text("Sample Location0"),
                Text("Sample Location1"),
              ],
            ),
          ),
          Column(
            children: [
              Text('Sample Text',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(color: Colors.white)),
              Container(
                color: Colors.green,
                child: Text("sample text"),
              )
            ],
          ),
        ],
      ),
    );
  }
}
