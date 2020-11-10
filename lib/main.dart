import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COVIDometer India',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  IndState india;
  List<Container> result = [];
  List<Container> subresult = [];
  List<IndState> states = [];
  bool isSearched,loading;
  int index = 0; TextEditingController ctrl = TextEditingController(); String line;

  @override
  void initState(){
    super.initState();
    getData();
    getStatesData();
    isSearched = false;
    loading = true;
    india = new IndState();
    india.name = "INDIA";
  }

  getData() async {
    final response = await http.Client().get(Uri.parse("https://www.mohfw.gov.in/"));
    if(response.statusCode == 200){
      var document = parse(response.body);
      setState(() {
        india.active = document.getElementsByTagName('#site-dashboard > div > div > div > div > ul > li.bg-blue > strong')[0].text;
        india.cured = document.getElementsByTagName('#site-dashboard > div > div > div > div > ul > li.bg-green > strong')[0].text;
        india.death = document.getElementsByTagName('#site-dashboard > div > div > div > div > ul > li.bg-red > strong')[0].text;
        india.total = (int.parse(india.active) + int.parse(india.cured) + int.parse(india.death)).toString();
        line = document.getElementsByTagName('#site-dashboard > div > div > div > div > div > h2 > span')[0].text;
        line = line.substring(0,1).toUpperCase() + line.substring(1);
        loading = false;
      });
    }
  }

  getStatesData() async {
    final response = await http.Client().get(Uri.parse("https://www.mohfw.gov.in/"));
    if(response.statusCode == 200){
      var document = parse(response.body);
      var doc = document.getElementsByTagName("#state-data > div > div > div > div > table > tbody > tr");      
      for(var i=0;i<35;i++){
        IndState state = IndState.fromDocument(doc[i].querySelectorAll('td'));
        Container w = getContainer(state);
        result.add(w);
        states.add(state);
      }
    }
  }
  
  route(IndState state,IndState india){
     return PageRouteBuilder(
      pageBuilder: (context,animation,secondaryAnimation)=>Display(state,india)
    );
  } 

  getContainer(IndState state){
    return Container(
            width: 380, height: 250,
            child: MaterialButton(
              onPressed: ()=>{Navigator.push(context,route(state,india))},
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(15),
                    child: Column(
                      children:[
                        Padding(padding: EdgeInsets.all(5),child: Text(state.name,style:TextStyle(fontSize: 25),textAlign: TextAlign.center,)),
                        Divider(thickness:2,color:Colors.black),
                        Padding(padding: EdgeInsets.all(5),child: Text("Active cases: "+ state.active ,style:TextStyle(fontSize: 18))),
                        Padding(padding: EdgeInsets.all(5),child: Text("Recovered cases: "+ state.cured ,style:TextStyle(fontSize: 18))),
                        Padding(padding: EdgeInsets.all(5),child: Text("Death: "+ state.death,style:TextStyle(fontSize: 18))),
                        Padding(padding: EdgeInsets.all(5),child: Text("Total cases: "+ state.total,style:TextStyle(fontSize: 18)))
                      ]
                    ),
                  )
                ),
            ),
            );
  }

  clearSearch(){
    setState(() {
      ctrl.clear();
      subresult = [];
      isSearched = false;
    });
  }

  search(String query){
    query = query.toLowerCase(); 
    setState(() {
      subresult = [];
      isSearched = true;
      for(var i=0;i<35;i++){
        if(states[i].name.toLowerCase() == query){
          var w = getContainer(states[i]);
          subresult.add(w);
        }
      }
    });
  }

  getStat(String key,String value,Color color){
    final style = TextStyle(fontWeight: FontWeight.bold,fontSize: 25);    
    return Container(
            height: 120,
            child: Card(
              color: color,
              elevation: 10,
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Row(
                  children: [
                    Text(key,style: style),
                    Text(value,style:TextStyle(fontSize: 20))
                  ],
                  ),
              )
              )
            );
  }

  about(){
    showAboutDialog(
      context: context,
      applicationVersion: '0.1.3',
      applicationIcon: Image.asset('assets/icon.png',scale:1.5),
      children: [
        Text("App to track spread of COVID-19 across the country.\nOne-day-development.\n\nSource:\nMinistry of Health and Family Welfare, Government of India"),
      ]
    );
  }

  getRate(String title,String numr,String dino, Color color){
    var percent = (int.parse(numr) * 100 / int.parse(dino)).toStringAsFixed(4) + "%";
    return Container(
      child: Card(
        elevation: 5,
        child: Row(
          children: [
            Container(
              decoration:BoxDecoration(
                color: color,
              ),
              width: 200,
              height: 70,
              child: Padding(
                padding: EdgeInsets.only(top:25,left:25),
                child: Text(title,style:TextStyle(fontSize:20,fontWeight: FontWeight.bold))
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(percent,style:TextStyle(fontSize: 20))
            )
          ],
        )
      )
    );
  }

  Widget build(BuildContext context) {

    Widget statewise,ind;
    List<Widget> list;
    if(!loading){
      statewise = Column(
      children: [
        Container(
            decoration: BoxDecoration(color:Colors.black),
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(line,style:TextStyle(color:Colors.white)),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top:40,bottom:30),
          child: Text("State-wise data",style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(10),
          child: TextField(
           controller: ctrl,
           enableSuggestions: true,
           onSubmitted: search,
           textInputAction: TextInputAction.go,
           decoration: InputDecoration(
            prefixIcon: Icon(Icons.search,size:20.0),
            hintText: "Enter name to search",  
            suffixIcon: IconButton(icon: Icon(Icons.close), onPressed: clearSearch)              
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top:30),
          child: Column(
            children: isSearched ? subresult : result
          ),
        )
      ],
    );
    ind = Container(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color:Colors.black),
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(line,style:TextStyle(color:Colors.white)),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Image.asset('assets/ind.png',scale:2)
              ),
              Padding(
                padding: EdgeInsets.only(left:60),
                child: Text(india.name,style:TextStyle(fontSize: 30,fontWeight: FontWeight.bold))
              ),
            ],
          ),
          getStat("Active Cases: ",india.active,Colors.yellow[300]),
          getStat("Recovered Cases: ",india.cured,Colors.green[300]),
          getStat("Deaths: ",india.death,Colors.red[300]),
          getStat("Total Cases: ",india.total,Colors.blue[300]),
          Divider(height: 60,),
          getRate("Recovery rate",india.cured,india.total,Colors.green[100]),
          getRate("Death rate",india.death,india.total,Colors.red[100]),
        ],
      )
    );
    list = [ind,statewise];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("COVIDometer India"),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/about.png',scale:4),
          onPressed: about,
        )
      ),
      body: loading ? Padding(
        padding: EdgeInsets.only(top:300),
        child: LinearProgressIndicator(),
      ) 
      : SingleChildScrollView(
          child: Center(
            child:list.elementAt(index),
          )
      ) ,
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: select,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Image.asset('assets/india.png',scale:15),title: Text("Nation")),
            BottomNavigationBarItem(icon: Icon(Icons.flag),title: Text("States")),
          ]
        ),
    );
  }

  void select(int value) {
    setState(() {
      index = value;
    });
  }
}

class IndState{
  String name,active,cured,death,total; 
  IndState({this.name,this.active,this.cured,this.death,this.total});
  factory IndState.fromDocument(doc){
    return IndState(
      name: doc[1].text,
      active: doc[2].text,
      cured: doc[3].text,
      death: doc[4].text,
      total: doc[5].text
    );
  }
}

class Display extends StatefulWidget{
  final IndState india,state;
  Display(this.state,this.india);
  @override
  State<StatefulWidget> createState() => ShowState();
}

class ShowState extends State<Display>{
  IndState india,state;
  Float share;
  @override
  void initState() {
    india = widget.india;
    state = widget.state;
    super.initState();
  }

  getStat(String dataS,String dataI, String title, Color color){
    final style = TextStyle(fontWeight: FontWeight.bold,fontSize: 25);
    var percent = ((int.parse(dataS) / int.parse(dataI))*100).toStringAsFixed(4) + "%";    
    return Container(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(0),
                child: Column(
                  children: [
                    Container(
                      width: double.maxFinite,
                      child: Padding(padding:EdgeInsets.all(10),child: Text(title,style: style,textAlign: TextAlign.center,)),
                      decoration: BoxDecoration(
                        color: color
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        children: [
                          Text("Number of "+ title.toLowerCase(),style:TextStyle(fontSize: 20)),
                          Text(dataS,style:TextStyle(fontSize: 20))
                        ],
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Text("% of nation-wide "+title.toLowerCase(),style:TextStyle(fontSize: 20)),
                          Text(percent,style:TextStyle(fontSize: 20))
                        ],
                      )
                    )
                  ],
                  ),
              )
              )
            );
  }

  getRate(String dataS,String dataI, String title, Color color){
    final style = TextStyle(fontWeight: FontWeight.bold,fontSize: 25);
    var percent = ((int.parse(dataS) / int.parse(dataI))*100).toStringAsFixed(4) + "%";    
    return Container(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(0),
                child: Column(
                  children: [
                    Container(
                      width: 190,
                      child: Padding(padding:EdgeInsets.all(10),child: Text(title,style: style,textAlign: TextAlign.center,)),
                      decoration: BoxDecoration(
                        color: color
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(percent,style:TextStyle(fontSize: 20))
                    )
                  ],
                  ),
              )
              )
            );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Container(
          child: SingleChildScrollView(
            child:Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(90),
                  child: Image.asset('assets/states/'+ state.name +'.png',scale:3.5),
                ),
                Padding(
                  padding: EdgeInsets.only(top:10,bottom:20),
                  child: Text(state.name,style:TextStyle(fontSize: 30))
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: getStat(state.active,india.active,"Active cases",Colors.yellow[300]),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: getStat(state.cured,india.cured,"Recovered cases",Colors.green[300]),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: getStat(state.death,india.death,"Deaths",Colors.red[300]),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: getStat(state.total,india.total,"Total cases",Colors.blue[300]),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Row(
                    children: [
                      getRate(state.cured,state.total,"Recovery rate",Colors.green[100]),
                      getRate(state.death,state.total,"Death rate",Colors.red[100])
                    ],
                  )
                )   
              ],
            )
          )
        )
      )
    );
  }
}