import 'package:get/get.dart';

/// Surah metadata for the Madinah Mushaf (Hafs, 604 pages).
///
/// [page] is the Mushaf page on which the surah begins. Several short surahs
/// share a page, which is expected — the last ten all sit on pages 601-604.
class SurahInfo {
  const SurahInfo(this.number, this.page, this.nameAr, this.nameEn, this.ayahs, this.isMeccan);

  final int number;
  final int page;
  final String nameAr;
  final String nameEn;
  final int ayahs;
  final bool isMeccan;
}

/// All 114 surahs in order.
const List<SurahInfo> kQuranSurahs = [
  SurahInfo(1, 1, 'الفاتحة', 'Al-Fatihah', 7, true),
  SurahInfo(2, 2, 'البقرة', 'Al-Baqarah', 286, false),
  SurahInfo(3, 50, 'آل عمران', 'Ali \'Imran', 200, false),
  SurahInfo(4, 77, 'النساء', 'An-Nisa', 176, false),
  SurahInfo(5, 106, 'المائدة', 'Al-Ma\'idah', 120, false),
  SurahInfo(6, 128, 'الأنعام', 'Al-An\'am', 165, true),
  SurahInfo(7, 151, 'الأعراف', 'Al-A\'raf', 206, true),
  SurahInfo(8, 177, 'الأنفال', 'Al-Anfal', 75, false),
  SurahInfo(9, 187, 'التوبة', 'At-Tawbah', 129, false),
  SurahInfo(10, 208, 'يونس', 'Yunus', 109, true),
  SurahInfo(11, 221, 'هود', 'Hud', 123, true),
  SurahInfo(12, 235, 'يوسف', 'Yusuf', 111, true),
  SurahInfo(13, 249, 'الرعد', 'Ar-Ra\'d', 43, false),
  SurahInfo(14, 255, 'إبراهيم', 'Ibrahim', 52, true),
  SurahInfo(15, 262, 'الحجر', 'Al-Hijr', 99, true),
  SurahInfo(16, 267, 'النحل', 'An-Nahl', 128, true),
  SurahInfo(17, 282, 'الإسراء', 'Al-Isra', 111, true),
  SurahInfo(18, 293, 'الكهف', 'Al-Kahf', 110, true),
  SurahInfo(19, 305, 'مريم', 'Maryam', 98, true),
  SurahInfo(20, 312, 'طه', 'Ta-Ha', 135, true),
  SurahInfo(21, 322, 'الأنبياء', 'Al-Anbiya', 112, true),
  SurahInfo(22, 332, 'الحج', 'Al-Hajj', 78, false),
  SurahInfo(23, 342, 'المؤمنون', 'Al-Mu\'minun', 118, true),
  SurahInfo(24, 350, 'النور', 'An-Nur', 64, false),
  SurahInfo(25, 359, 'الفرقان', 'Al-Furqan', 77, true),
  SurahInfo(26, 367, 'الشعراء', 'Ash-Shu\'ara', 227, true),
  SurahInfo(27, 377, 'النمل', 'An-Naml', 93, true),
  SurahInfo(28, 385, 'القصص', 'Al-Qasas', 88, true),
  SurahInfo(29, 396, 'العنكبوت', 'Al-\'Ankabut', 69, true),
  SurahInfo(30, 404, 'الروم', 'Ar-Rum', 60, true),
  SurahInfo(31, 411, 'لقمان', 'Luqman', 34, true),
  SurahInfo(32, 415, 'السجدة', 'As-Sajdah', 30, true),
  SurahInfo(33, 418, 'الأحزاب', 'Al-Ahzab', 73, false),
  SurahInfo(34, 428, 'سبأ', 'Saba', 54, true),
  SurahInfo(35, 434, 'فاطر', 'Fatir', 45, true),
  SurahInfo(36, 440, 'يس', 'Ya-Sin', 83, true),
  SurahInfo(37, 446, 'الصافات', 'As-Saffat', 182, true),
  SurahInfo(38, 453, 'ص', 'Sad', 88, true),
  SurahInfo(39, 458, 'الزمر', 'Az-Zumar', 75, true),
  SurahInfo(40, 467, 'غافر', 'Ghafir', 85, true),
  SurahInfo(41, 477, 'فصلت', 'Fussilat', 54, true),
  SurahInfo(42, 483, 'الشورى', 'Ash-Shura', 53, true),
  SurahInfo(43, 489, 'الزخرف', 'Az-Zukhruf', 89, true),
  SurahInfo(44, 496, 'الدخان', 'Ad-Dukhan', 59, true),
  SurahInfo(45, 499, 'الجاثية', 'Al-Jathiyah', 37, true),
  SurahInfo(46, 502, 'الأحقاف', 'Al-Ahqaf', 35, true),
  SurahInfo(47, 507, 'محمد', 'Muhammad', 38, false),
  SurahInfo(48, 511, 'الفتح', 'Al-Fath', 29, false),
  SurahInfo(49, 515, 'الحجرات', 'Al-Hujurat', 18, false),
  SurahInfo(50, 518, 'ق', 'Qaf', 45, true),
  SurahInfo(51, 520, 'الذاريات', 'Adh-Dhariyat', 60, true),
  SurahInfo(52, 523, 'الطور', 'At-Tur', 49, true),
  SurahInfo(53, 526, 'النجم', 'An-Najm', 62, true),
  SurahInfo(54, 528, 'القمر', 'Al-Qamar', 55, true),
  SurahInfo(55, 531, 'الرحمن', 'Ar-Rahman', 78, false),
  SurahInfo(56, 534, 'الواقعة', 'Al-Waqi\'ah', 96, true),
  SurahInfo(57, 537, 'الحديد', 'Al-Hadid', 29, false),
  SurahInfo(58, 542, 'المجادلة', 'Al-Mujadila', 22, false),
  SurahInfo(59, 545, 'الحشر', 'Al-Hashr', 24, false),
  SurahInfo(60, 549, 'الممتحنة', 'Al-Mumtahanah', 13, false),
  SurahInfo(61, 551, 'الصف', 'As-Saff', 14, false),
  SurahInfo(62, 553, 'الجمعة', 'Al-Jumu\'ah', 11, false),
  SurahInfo(63, 554, 'المنافقون', 'Al-Munafiqun', 11, false),
  SurahInfo(64, 556, 'التغابن', 'At-Taghabun', 18, false),
  SurahInfo(65, 558, 'الطلاق', 'At-Talaq', 12, false),
  SurahInfo(66, 560, 'التحريم', 'At-Tahrim', 12, false),
  SurahInfo(67, 562, 'الملك', 'Al-Mulk', 30, true),
  SurahInfo(68, 564, 'القلم', 'Al-Qalam', 52, true),
  SurahInfo(69, 566, 'الحاقة', 'Al-Haqqah', 52, true),
  SurahInfo(70, 568, 'المعارج', 'Al-Ma\'arij', 44, true),
  SurahInfo(71, 570, 'نوح', 'Nuh', 28, true),
  SurahInfo(72, 572, 'الجن', 'Al-Jinn', 28, true),
  SurahInfo(73, 574, 'المزمل', 'Al-Muzzammil', 20, true),
  SurahInfo(74, 575, 'المدثر', 'Al-Muddaththir', 56, true),
  SurahInfo(75, 577, 'القيامة', 'Al-Qiyamah', 40, true),
  SurahInfo(76, 578, 'الإنسان', 'Al-Insan', 31, false),
  SurahInfo(77, 580, 'المرسلات', 'Al-Mursalat', 50, true),
  SurahInfo(78, 582, 'النبأ', 'An-Naba', 40, true),
  SurahInfo(79, 583, 'النازعات', 'An-Nazi\'at', 46, true),
  SurahInfo(80, 585, 'عبس', '\'Abasa', 42, true),
  SurahInfo(81, 586, 'التكوير', 'At-Takwir', 29, true),
  SurahInfo(82, 587, 'الانفطار', 'Al-Infitar', 19, true),
  SurahInfo(83, 587, 'المطففين', 'Al-Mutaffifin', 36, true),
  SurahInfo(84, 589, 'الانشقاق', 'Al-Inshiqaq', 25, true),
  SurahInfo(85, 590, 'البروج', 'Al-Buruj', 22, true),
  SurahInfo(86, 591, 'الطارق', 'At-Tariq', 17, true),
  SurahInfo(87, 591, 'الأعلى', 'Al-A\'la', 19, true),
  SurahInfo(88, 592, 'الغاشية', 'Al-Ghashiyah', 26, true),
  SurahInfo(89, 593, 'الفجر', 'Al-Fajr', 30, true),
  SurahInfo(90, 594, 'البلد', 'Al-Balad', 20, true),
  SurahInfo(91, 595, 'الشمس', 'Ash-Shams', 15, true),
  SurahInfo(92, 595, 'الليل', 'Al-Layl', 21, true),
  SurahInfo(93, 596, 'الضحى', 'Ad-Duha', 11, true),
  SurahInfo(94, 596, 'الشرح', 'Ash-Sharh', 8, true),
  SurahInfo(95, 597, 'التين', 'At-Tin', 8, true),
  SurahInfo(96, 597, 'العلق', 'Al-\'Alaq', 19, true),
  SurahInfo(97, 598, 'القدر', 'Al-Qadr', 5, true),
  SurahInfo(98, 598, 'البينة', 'Al-Bayyinah', 8, false),
  SurahInfo(99, 599, 'الزلزلة', 'Az-Zalzalah', 8, false),
  SurahInfo(100, 599, 'العاديات', 'Al-\'Adiyat', 11, true),
  SurahInfo(101, 600, 'القارعة', 'Al-Qari\'ah', 11, true),
  SurahInfo(102, 600, 'التكاثر', 'At-Takathur', 8, true),
  SurahInfo(103, 601, 'العصر', 'Al-\'Asr', 3, true),
  SurahInfo(104, 601, 'الهمزة', 'Al-Humazah', 9, true),
  SurahInfo(105, 601, 'الفيل', 'Al-Fil', 5, true),
  SurahInfo(106, 602, 'قريش', 'Quraysh', 4, true),
  SurahInfo(107, 602, 'الماعون', 'Al-Ma\'un', 7, true),
  SurahInfo(108, 602, 'الكوثر', 'Al-Kawthar', 3, true),
  SurahInfo(109, 603, 'الكافرون', 'Al-Kafirun', 6, true),
  SurahInfo(110, 603, 'النصر', 'An-Nasr', 3, false),
  SurahInfo(111, 603, 'المسد', 'Al-Masad', 5, true),
  SurahInfo(112, 604, 'الإخلاص', 'Al-Ikhlas', 4, true),
  SurahInfo(113, 604, 'الفلق', 'Al-Falaq', 5, true),
  SurahInfo(114, 604, 'الناس', 'An-Nas', 6, true),
];

/// The surah occupying [page] — the last one to have started at or before it.
SurahInfo surahForPage(int page) {
  var found = kQuranSurahs.first;
  for (final s in kQuranSurahs) {
    if (s.page <= page) {
      found = s;
    } else {
      break;
    }
  }
  return found;
}

/// Juz start pages, index 0 = Juz 1.
const List<int> kJuzStartPages = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
  201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
  402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
];

/// The surah's name in the reader's language, and the other one.
///
/// Both names are carried for every surah, but the Mushaf screens were printing
/// `nameAr` unconditionally, so an English reader got Arabic titles under an
/// otherwise translated interface.
extension SurahNames on SurahInfo {
  String get localizedName => Get.locale?.languageCode == 'ar' ? nameAr : nameEn;

  /// The name the title isn't using — shown underneath in the index, where
  /// repeating the title would say nothing.
  String get otherName => Get.locale?.languageCode == 'ar' ? nameEn : nameAr;
}
