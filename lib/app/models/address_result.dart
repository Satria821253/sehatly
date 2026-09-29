class AddressResult {
  final String label;
  final String main;
  final String detail;
  final String full;

  /// Dari Places Autocomplete — dipakai untuk ambil alamat lengkap presisi.
  final String? placeId;

  /// Koordinat (tersedia setelah reverse geocode / place details).
  final double? lat;
  final double? lng;

  AddressResult({
    required this.label,
    required this.main,
    required this.detail,
    required this.full,
    this.placeId,
    this.lat,
    this.lng,
  });

  AddressResult copyWith({
    String? label,
    String? main,
    String? detail,
    String? full,
    String? placeId,
    double? lat,
    double? lng,
  }) {
    return AddressResult(
      label: label ?? this.label,
      main: main ?? this.main,
      detail: detail ?? this.detail,
      full: full ?? this.full,
      placeId: placeId ?? this.placeId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  factory AddressResult.fromNominatim(Map<String, dynamic> json) {
    final displayName = json['display_name']?.toString() ?? '';
    final addr = json['address'] as Map<String, dynamic>? ?? {};

    final segments = displayName
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Nominatim biasanya memunculkan nama jalan/POI di urutan pertama.
    final main = segments.isNotEmpty
        ? segments.first
        : (addr['road'] ??
            addr['neighbourhood'] ??
            addr['suburb'] ??
            addr['village'] ??
            'Lokasi');

    final detail = segments.length > 1 ? segments.skip(1).join(', ') : '';

    return AddressResult(
      label: main,
      main: main,
      detail: detail.isNotEmpty ? detail : _fallbackDetail(addr),
      full: displayName.isNotEmpty ? displayName : main,
      lat: double.tryParse(json['lat']?.toString() ?? ''),
      lng: double.tryParse(json['lon']?.toString() ?? ''),
      // Penanda hasil dari OpenStreetMap, bukan Google.
      placeId: json['osm_type'] != null && json['osm_id'] != null
          ? 'osm:${json['osm_type']}/${json['osm_id']}'
          : null,
    );
  }

  static String _fallbackDetail(Map<String, dynamic> addr) {
    final parts = [
      addr['suburb'],
      addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'],
      addr['state'],
      addr['postcode'],
    ].whereType<String>().where((e) => e.isNotEmpty).toList();
    return parts.join(', ');
  }
}
