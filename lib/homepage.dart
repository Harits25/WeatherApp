import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int? temperature;
  String location = 'Indonesia';
  String weather = 'thunderstrom';

  // Added a unique Code for a specific city
  int woeid = 1118370;

  // Make A Variable For Icon And Error Messages
  String abbreviation = '';
  String errorMessage = '';

  // Make A Link For API
  String searchApiUrl = 'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  // Var make list temperature
  var minTemperatureForecast = List.filled(7, 0);
  var mixTemperatureForecast = List.filled(7, 0);
  var abbreviationForecast = List.filled(7, '');

  Future<void> fetchSearch(String input) async {

    try{
      var searchUrl = await http.get(Uri.parse(searchApiUrl+ input));
      var result = jsonDecode(searchUrl.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
        errorMessage = '';
      });
    }catch(error){
      setState(() {
        errorMessage = 'Maaf kota yang anda cari tidak ada. Harap bersabar ini ujian untuk anda';
      });
    }
  }

  Future<void> fetchLocation() async{
    var locationResult = await http.get(Uri.parse(locationApiUrl + woeid.toString()));
    var result = jsonDecode(locationResult.body);
    var consolidated_weather = result['consolidated_weather'];
    var data = consolidated_weather[0];

    setState(() {
      temperature = data['the_temp'].round();
      weather = data['weather_state_name'].toString().replaceAll(" ", "").toLowerCase();
      abbreviation = data['weather_state_abbr'];
    });
  }

  // Membuat funtion untuk menampilkan data selama 7 hari
  Future<void> fetchSevenDays() async {
    var today = DateTime.now();
    for (var i = 0; i <  7; i++) {
      var locationDayResult = await http.get(
          Uri.parse(
              locationApiUrl + woeid.toString() + '/' + DateFormat(
                'y/M/d').format(
                  today.add(
                      Duration(
                          days: i + 1
                      )
                  )
              ).toString()
          )
      );
      var result = jsonDecode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data['min_temp'].round();
        mixTemperatureForecast[i] = data['max_temp'].round();
        abbreviationForecast[i] = data['weather_state_abbr'];
      });
    }
  }

  // Buat fungsi untuk si kolom search agar mendapatkan inputan
  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchSevenDays();
  }
  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchSevenDays();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/$weather.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.dstATop),
        )
      ),
      child: temperature == null ?
      CircularProgressIndicator() : Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Column(
                children: [
                  Center(
                    child: Image.network(
                      'https://www.metaweather.com/static/img/weather/png/'+ abbreviation +'.png',
                      width: 100,
                    ),
                  ),
                  const SizedBox(
                    height: 3.0,
                  ),
                  Center(
                    child: Text(temperature.toString() + ' °C', style: TextStyle(
                      color: Colors.white, fontSize: 60
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 3.0,
                  ),
                  Center(
                    child: Text(location, style: TextStyle(
                      color: Colors.white, fontSize: 40
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 3.0,
                  ),

                  // Untuk tampilan 7 hari berikutnya
                  Padding(
                      padding: EdgeInsets.only(
                        top: 50
                      ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (
                          var i = 0; i < 7; i++
                          )
                            forecastElement(
                                i + 1,
                                abbreviationForecast[i],
                                mixTemperatureForecast[i],
                                minTemperatureForecast[i],
                            ),
                        ],
                      )
                    ),
                  ),

                  // Make column for search
                  Column(
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextField(
                          onSubmitted : (String input) {
                            onTextFieldSubmitted(input);
                          },
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search Location',
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        errorMessage, textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                        ),
                      )
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget forecastElement(daysFromNow, abbreviation, maxTem, minTemp) {
    var now = DateTime.now();
    var oneDayFromNow = now.add(Duration(days: daysFromNow));
    return Padding(padding: EdgeInsets.only(left: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(285, 212, 228, 8.2),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(DateFormat.E().format(oneDayFromNow),
            style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              DateFormat.MMMd().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          Padding(padding: EdgeInsets.symmetric(vertical: 16),
            child: Image.network(
              'https://www.metaweather.com/static/img/weather/png/'+ abbreviation +'.png',
              width: 100,
                ),
              ),
            Text('High ' + maxTem.toString() + '°C',
            style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            Text('Low ' + maxTem.toString() + '°C',
              style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}