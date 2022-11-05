import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  dynamic markers;
  dynamic setMarkers;
  bool? isSetupReady;
  Uint8List? image;
  TextEditingController? searchLocationController;
  LatLng? latLng;
  Completer<GoogleMapController>? googleMapController;

  @override
  void initState() {
    doInitialSetup();
    super.initState();
  }

  doInitialSetup() async {
    isSetupReady = false;
    googleMapController = Completer();
    searchLocationController = TextEditingController();
    image = await getBytesFromAsset(AppConstants.imageString, 100);
    markers = [
      Marker(
          markerId: const MarkerId(AppConstants.titleName),
          icon: BitmapDescriptor.fromBytes(image!),
          position: const LatLng(28.535517, 77.391029),
          infoWindow: const InfoWindow(title: AppConstants.titleName))
    ];
    setMarkers = markers.toSet();
    setState(() {
      isSetupReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () async {
                if (searchLocationController!.text
                    .toString()
                    .trim()
                    .isNotEmpty) {
                  findLatAndLogFromAddress();
                }
              },
              child: const Icon(
                Icons.search,
                color: Colors.black54,
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.startDocked,
          body: getBody()),
    );
  }

  Widget getBody() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: isSetupReady!
              ? GoogleMap(
                  initialCameraPosition: const CameraPosition(
                      target: LatLng(28.535517, 77.391029), zoom: 17),
                  zoomControlsEnabled: true,
                  markers: setMarkers,
                  onMapCreated: (GoogleMapController controller) {
                    googleMapController!.complete(controller);
                  },
                )
              : const Center(child: Text(AppConstants.loadingMapString)),
        ),
        Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
                  hintText: AppConstants.locationString,
                  hintStyle: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  suffixIcon: InkWell(
                    onTap: () async {
                      if (searchLocationController!.text
                          .toString()
                          .trim()
                          .isNotEmpty) {
                        findLatAndLogFromAddress();
                      }
                    },
                    child: const Icon(
                      Icons.search,
                      size: 26,
                      color: Colors.black54,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(45.0),
                    borderSide: const BorderSide(
                      width: 2.0,
                      color: Colors.red,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(45.0),
                    borderSide: const BorderSide(
                      width: 2.0,
                      color: Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(45.0),
                    borderSide: const BorderSide(
                      width: 2.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
                controller: searchLocationController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  findLatAndLogFromAddress() async {
    List<Location> locations = await locationFromAddress(
        searchLocationController!.text.toString().trim());
    markers.clear();
    markers.add(Marker(
        markerId: MarkerId(searchLocationController!.text.toString().trim()),
        icon: BitmapDescriptor.fromBytes(image!),
        position: LatLng(locations[0].latitude, locations[0].longitude),
        infoWindow: InfoWindow(
            title: searchLocationController!.text.toString().trim())));

    setState(() {
      setMarkers = markers.toSet();
    });
    GoogleMapController controller = await googleMapController!.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(locations[0].latitude, locations[0].longitude),
      zoom: 14,
    )));
    setState(() {});
    searchLocationController!.clear();
  }
}
