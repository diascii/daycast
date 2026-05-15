import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

class WeatherMapScreen extends StatefulWidget {
  final AppState state;
  const WeatherMapScreen({super.key, required this.state});

  @override
  State<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

enum WeatherMapLayer {
  radar,
  clouds,
  nightLights,
  snow,
  fires,
  oceanTemp
}

class _WeatherMapScreenState extends State<WeatherMapScreen> {
  final WeatherService _weatherService = WeatherService();
  final MapController _mapController = MapController();
  String? _radarPath;
  String? _satellitePath;
  bool _loading = true;
  WeatherMapLayer _selectedLayer = WeatherMapLayer.radar;

  @override
  void initState() {
    super.initState();
    _loadMapPaths();
  }

  Future<void> _loadMapPaths() async {
    final paths = await _weatherService.fetchRadarAndSatellitePaths();
    if (mounted) {
      setState(() {
        _radarPath = paths.radar;
        _satellitePath = paths.satellite;
        _loading = false;
      });
    }
  }

  void _moveToCurrentLocation() {
    final loc = widget.state.activeLocation;
    if (loc != null) {
      _mapController.move(LatLng(loc.lat, loc.lon), 8.0);
    }
  }

  String _getNASAUrl(String layer, String matrixSet, {String format = 'png'}) {
    // Using 'default' for time is more reliable for real-time/latest imagery
    return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/$layer/default/default/$matrixSet/{z}/{y}/{x}.$format';
  }

  String? _getLayerUrl() {
    switch (_selectedLayer) {
      case WeatherMapLayer.radar:
        if (_radarPath == null) return null;
        return 'https://tilecache.rainviewer.com$_radarPath/256/{z}/{x}/{y}/2/1_1.png';
      case WeatherMapLayer.clouds:
        // Switch to Infrared (Brightness Temp) for a better "Weather" look
        return _getNASAUrl('MODIS_Terra_Brightness_Temp_Band31_Day', 'GoogleMapsCompatible_Level9');
      case WeatherMapLayer.nightLights:
        return _getNASAUrl('VIIRS_CityLights_2012', 'GoogleMapsCompatible_Level8', format: 'jpg');
      case WeatherMapLayer.snow:
        // Use NDSI Snow Cover (PNG with transparency)
        return _getNASAUrl('MODIS_Terra_NDSI_Snow_Cover', 'GoogleMapsCompatible_Level8');
      case WeatherMapLayer.fires:
        // Use a more reliable 1km Fire layer
        return _getNASAUrl('MODIS_Terra_Thermal_Anomalies_Day', 'GoogleMapsCompatible_Level9');
      case WeatherMapLayer.oceanTemp:
        return _getNASAUrl('GHRSST_L4_MUR_Sea_Surface_Temperature', 'GoogleMapsCompatible_Level7');
    }
  }

  String _getLayerTitle() {
    switch (_selectedLayer) {
      case WeatherMapLayer.radar: return 'Precipitation';
      case WeatherMapLayer.clouds: return 'Infrared Clouds';
      case WeatherMapLayer.nightLights: return 'City Lights';
      case WeatherMapLayer.snow: return 'Snow Cover';
      case WeatherMapLayer.fires: return 'Active Fires';
      case WeatherMapLayer.oceanTemp: return 'Ocean Temp';
    }
  }

  List<Color> _getLegendColors() {
    switch (_selectedLayer) {
      case WeatherMapLayer.radar:
        return [const Color(0xFF82eefd), const Color(0xFF0000ff), const Color(0xFFffff00), const Color(0xFFff0000)];
      case WeatherMapLayer.clouds:
        return [Colors.blue.shade900, Colors.blue.shade100, Colors.white];
      case WeatherMapLayer.nightLights:
        return [Colors.black, Colors.yellow.shade200, Colors.white];
      case WeatherMapLayer.snow:
        return [Colors.blue.shade50, Colors.blue.shade100, Colors.white];
      case WeatherMapLayer.fires:
        return [Colors.orange, Colors.red, Colors.red.shade900];
      case WeatherMapLayer.oceanTemp:
        return [Colors.blue.shade900, Colors.blue, Colors.green, Colors.yellow, Colors.red];
    }
  }

  String _getLegendLow() {
    switch (_selectedLayer) {
      case WeatherMapLayer.radar: return 'Light';
      case WeatherMapLayer.clouds: return 'Warm';
      case WeatherMapLayer.nightLights: return 'Dark';
      case WeatherMapLayer.snow: return 'None';
      case WeatherMapLayer.fires: return 'Low';
      case WeatherMapLayer.oceanTemp: return 'Cold';
    }
  }

  String _getLegendHigh() {
    switch (_selectedLayer) {
      case WeatherMapLayer.radar: return 'Heavy';
      case WeatherMapLayer.clouds: return 'Cold (Storms)';
      case WeatherMapLayer.nightLights: return 'Bright';
      case WeatherMapLayer.snow: return 'Deep';
      case WeatherMapLayer.fires: return 'High';
      case WeatherMapLayer.oceanTemp: return 'Hot';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final activeLoc = widget.state.activeLocation;
    final initialCenter = activeLoc != null 
        ? LatLng(activeLoc.lat, activeLoc.lon) 
        : const LatLng(0, 0);

    final layerUrl = _getLayerUrl();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: c.surfaceElevated.withValues(alpha: 0.8),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Weather Map',
          style: GoogleFonts.dmSans(
            color: c.textPrimary,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: c.scaffoldBg.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<WeatherMapLayer>(
              initialValue: _selectedLayer,
              onSelected: (layer) => setState(() => _selectedLayer = layer),
              icon: CircleAvatar(
                backgroundColor: c.surfaceElevated.withValues(alpha: 0.8),
                child: Icon(Icons.layers_rounded, color: c.textPrimary, size: 20),
              ),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) => [
                const PopupMenuItem(value: WeatherMapLayer.radar, child: Text('Radar (Rain)')),
                const PopupMenuItem(value: WeatherMapLayer.clouds, child: Text('Infrared Clouds')),
                const PopupMenuItem(value: WeatherMapLayer.nightLights, child: Text('City Lights')),
                const PopupMenuItem(value: WeatherMapLayer.snow, child: Text('Snow Tracker')),
                const PopupMenuItem(value: WeatherMapLayer.fires, child: Text('Active Fires')),
                const PopupMenuItem(value: WeatherMapLayer.oceanTemp, child: Text('Ocean Temp')),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 8.0,
              maxZoom: 11.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.weather_note_app',
                tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 300)),
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: c.isDark 
                        ? const ColorFilter.matrix([
                            -0.2126, -0.7152, -0.0722, 0, 255,
                            -0.2126, -0.7152, -0.0722, 0, 255,
                            -0.2126, -0.7152, -0.0722, 0, 255,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: tileWidget,
                  );
                },
              ),
              if (layerUrl != null)
                TileLayer(
                  key: ValueKey(_selectedLayer),
                  urlTemplate: layerUrl,
                  userAgentPackageName: 'com.example.weather_note_app',
                  maxNativeZoom: _selectedLayer == WeatherMapLayer.radar ? 7 : 9,
                  tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 500)),
                  tileBuilder: (context, tileWidget, tile) {
                    final opacity = _selectedLayer == WeatherMapLayer.radar ? 1.0 : 0.7;
                    
                    // Special coloring for Infrared Clouds to make them look "Standard"
                    if (_selectedLayer == WeatherMapLayer.clouds) {
                      return Opacity(
                        opacity: 0.6,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.5, 0.5, 0.5, 0, 0,
                            0.5, 0.5, 0.5, 0, 0,
                            0.5, 0.5, 0.5, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                          child: tileWidget,
                        ),
                      );
                    }
                    
                    return Opacity(
                      opacity: opacity,
                      child: tileWidget,
                    );
                  },
                ),
              MarkerLayer(
                markers: [
                  if (activeLoc != null)
                    Marker(
                      point: LatLng(activeLoc.lat, activeLoc.lon),
                      width: 40,
                      height: 40,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 100,
            right: 0,
            child: RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {},
                ),
                TextSourceAttribution(
                  _selectedLayer == WeatherMapLayer.radar ? 'RainViewer' : 'NASA GIBS',
                  onTap: () {},
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  backgroundColor: c.surfaceElevated,
                  child: Icon(Icons.add, color: c.textPrimary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  backgroundColor: c.surfaceElevated,
                  child: Icon(Icons.remove, color: c.textPrimary),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'my_location',
                  onPressed: _moveToCurrentLocation,
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.surfaceElevated.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getLayerTitle(), 
                    style: GoogleFonts.dmSans(color: c.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: _getLegendColors(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_getLegendLow(), style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 8)),
                        Text(_getLegendHigh(), style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
