import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class CourierClusterItem extends ClusterItem {
  final String id;
  final String name;
  final LatLng location;

  CourierClusterItem({
    required this.id,
    required this.name,
    required this.location,
  }) : super(location);

  @override
  String toString() => 'Courier $id at $location';
}
