class AddressResult {
  final String main;
  final String detail;
  final String full;

  AddressResult({required this.main, required this.detail, required this.full});

  factory AddressResult.fromNominatim(Map<String, dynamic> json) {
    final addr = json['address'] as Map<String, dynamic>? ?? {};
    final main = addr['road'] ??
        addr['neighbourhood'] ??
        addr['suburb'] ??
        addr['village'] ??
        json['display_name'].toString().split(',').first;
    final parts = <String>[];
    if (addr['suburb'] != null) { parts.add(addr['suburb']); }
    if (addr['city'] != null) {
      parts.add(addr['city']);
    } else if (addr['town'] != null) {
      parts.add(addr['town']);
    } else if (addr['regency'] != null) {
      parts.add(addr['regency']);
    }
    if (addr['state'] != null) { parts.add(addr['state']); }
    return AddressResult(
      main: main.toString(),
      detail: parts.join(', '),
      full: json['display_name'].toString(),
    );
  }
}
