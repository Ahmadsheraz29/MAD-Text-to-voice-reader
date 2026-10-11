import 'package:flutter/cupertino.dart';
class EsectionClass extends StatelessWidget{
  final String name;
  const EsectionClass({super.key , required this.name})

  // const EsectionClass({super.key});
  // const EsectionClass ({super.key , required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text("E Section Lab"),
          Text("FA24-BCS-261"),
          Text("Ahmad Bin Sheraz"),
        ],
      ),
    );


  }

}