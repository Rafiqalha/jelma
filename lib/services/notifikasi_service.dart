import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Saluran notifikasi Android; pengguna dapat mengatur tiap saluran di pengaturan sistem.
enum SaluranNotifikasi {
  pengingat('pengingat_rencana', 'Pengingat rencana', 'Mengingatkan rencana kunjungan yang Anda buat.'),
  cuaca('peringatan_cuaca', 'Peringatan cuaca', 'Memberi tahu bila cuaca kurang mendukung rencana Anda.');

  const SaluranNotifikasi(this.id, this.nama, this.deskripsi);

  final String id;
  final String nama;
  final String deskripsi;
}

/// Notifikasi lokal. Dipisahkan dari plugin agar dapat diganti pada pengujian.
abstract class NotifikasiService {
  Future<void> inisialisasi();

  /// Apakah pengguna mengizinkan aplikasi menampilkan notifikasi.
  Future<bool> izinDiberikan();

  /// Memunculkan dialog izin notifikasi (Android 13 ke atas).
  Future<bool> mintaIzin();

  Future<void> tampilkan({
    required int id,
    required String judul,
    required String isi,
    required SaluranNotifikasi saluran,
  });

  /// Menjadwalkan notifikasi pada jam dinding WIB [waktu]; false bila waktunya sudah lewat.
  Future<bool> jadwalkan({
    required int id,
    required DateTime waktu,
    required String judul,
    required String isi,
    required SaluranNotifikasi saluran,
  });

  Future<void> batalkan(int id);
}

/// Implementasi dengan paket flutter_local_notifications.
class LocalNotifikasiService implements NotifikasiService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  late final tz.Location _wib;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> inisialisasi() async {
    tzdata.initializeTimeZones();
    _wib = tz.getLocation('Asia/Jakarta');
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_jelma')),
    );
    for (final saluran in SaluranNotifikasi.values) {
      await _android?.createNotificationChannel(
        AndroidNotificationChannel(
          saluran.id,
          saluran.nama,
          description: saluran.deskripsi,
          importance: Importance.high,
        ),
      );
    }
  }

  @override
  Future<bool> izinDiberikan() async => await _android?.areNotificationsEnabled() ?? true;

  @override
  Future<bool> mintaIzin() async =>
      await _android?.requestNotificationsPermission() ?? await izinDiberikan();

  NotificationDetails _detail(SaluranNotifikasi saluran, String isi) => NotificationDetails(
        android: AndroidNotificationDetails(
          saluran.id,
          saluran.nama,
          channelDescription: saluran.deskripsi,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_jelma',
          styleInformation: BigTextStyleInformation(isi),
        ),
      );

  @override
  Future<void> tampilkan({
    required int id,
    required String judul,
    required String isi,
    required SaluranNotifikasi saluran,
  }) =>
      _plugin.show(id: id, title: judul, body: isi, notificationDetails: _detail(saluran, isi));

  @override
  Future<bool> jadwalkan({
    required int id,
    required DateTime waktu,
    required String judul,
    required String isi,
    required SaluranNotifikasi saluran,
  }) async {
    final tujuan = tz.TZDateTime(_wib, waktu.year, waktu.month, waktu.day, waktu.hour, waktu.minute);
    if (!tujuan.isAfter(tz.TZDateTime.now(_wib))) return false;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tujuan,
      notificationDetails: _detail(saluran, isi),
      // Mode tidak tepat tidak memerlukan izin alarm khusus; keterlambatan beberapa menit dapat diterima untuk pengingat.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: judul,
      body: isi,
    );
    return true;
  }

  @override
  Future<void> batalkan(int id) => _plugin.cancel(id: id);
}
