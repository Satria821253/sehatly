# Sehatly

Aplikasi Flutter untuk mencari dan memilih alamat layanan kesehatan terdekat:
pencarian alamat (Google Places + fallback OpenStreetMap), pemetaan dengan
Google Maps (pin tengah `assets/svg/pin.svg`), mode offline berbasis animasi
Lottie, serta kartu error seragam untuk kegagalan simpan/muat alamat.

## Fitur utama

- **Splash → gate koneksi**: bila internet mati, tampil layar **"Cek
  Jaringanmu"** (Lottie + tombol *Coba Lagi*); bila tetap gagal, aplikasi
  tetap masuk sesuai onboarding/`hasReachedHome` — tidak pernah mengunci user.
- **Mode offline di Beranda**: isi disembunyikan, Lottie ±3 detik (grace),
  lalu panel "Cek Jaringanmu" inline; koneksi dipolling otomatis tiap 5 detik
  sehingga data muncul sendiri begitu internet pulih.
- **Pemilih alamat**: pencarian berbasis debounce + shimmer, panel offline
  bila koneksi putus, dan pesan gagal khusus untuk simpan/muat alamat.
- **Onboarding**: intro "Penggunaan Data & Izin" tampil sekali pada kunjungan
  kedua (flag `has_reached_home` / `has_seen_intro` di SharedPreferences).

## Menyiapkan API key

Kedua key **tidak ikut ter-push** (sudah masuk `.gitignore`). Sebelum build,
salin contohnya lalu isi isinya:

```bat
copy lib\app\config\api_key.g.example.dart lib\app\config\api_key.g.dart
copy android\key.properties.example android\key.properties
```

- `api_key.g.dart` → `googleApiKey` untuk layanan Geocoding/Places (Dart side).
- `key.properties` → `GOOGLE_MAPS_API_KEY` untuk Google Maps SDK (Android side).

## Menjalankan

```bash
flutter pub get
flutter analyze lib test   # harus: No issues found
flutter test               # 31 tes (termasuk golden test kartu error)
flutter run
```

Build rilis:

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

## Struktur singkat

| Lokasi | Isi |
| --- | --- |
| `lib/pages/` | halaman (splash, home, address_picker, map_picker, connection_check, intro, permission) |
| `lib/widgets/` | komponen berulang (`error_message`, `offline_panel`, `lottie_loading`, `primary_button`, `map_pin`, `shimmer_*`) |
| `lib/app/controllers/` | kontroler GetX + binding/route |
| `lib/app/services/` | `network_status.dart`, `google_places_service.dart`, `nominatim_service.dart`, `google_geocoding_service.dart` |
| `assets/` | `fonts/` (Poppins dibundel, aman offline), `lottie/`, `images/`, `svg/` |
| `test/` | tes unit/widget/golden (`flutter test`) |
