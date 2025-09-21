import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'ad_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    MobileAds.instance.initialize();
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const DiceRollerApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

const Color primarySeedColor = Colors.greenAccent;

final TextTheme appTextTheme = TextTheme(
  displayLarge: GoogleFonts.montserrat(
      fontSize: 150,
      fontWeight: FontWeight.bold,
      shadows: [
        const Shadow(blurRadius: 10.0, color: Colors.black26, offset: Offset(5.0, 5.0))
      ]),
  titleLarge: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold),
  bodyMedium: GoogleFonts.poppins(fontSize: 16),
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeedColor,
    brightness: Brightness.light,
  ),
  textTheme: appTextTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: primarySeedColor,
    foregroundColor: Colors.black,
    titleTextStyle: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: primarySeedColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      textStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySeedColor,
    brightness: Brightness.dark,
  ),
  textTheme: appTextTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
    foregroundColor: Colors.white,
    titleTextStyle: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: primarySeedColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      textStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
    ),
  ),
);

class DiceRollerApp extends StatelessWidget {
  const DiceRollerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Dice',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const DiceScreen(),
        );
      },
    );
  }
}

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => DiceScreenState();
}

class DiceScreenState extends State<DiceScreen>
    with SingleTickerProviderStateMixin {
  int _diceValue = 1;
  int _rollCount = 0;
  late AnimationController _animationController;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadRollCount();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (!kIsWeb) {
      _bannerAd = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              _isBannerAdReady = true;
            });
          },
          onAdFailedToLoad: (ad, err) {
            developer.log('Failed to load a banner ad: ${err.message}');
            _isBannerAdReady = false;
            ad.dispose();
          },
        ),
      );

      _bannerAd?.load();
      _loadInterstitialAd();
    }
  }

  Future<void> _loadRollCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rollCount = prefs.getInt('rollCount') ?? 0;
    });
  }

  Future<void> _incrementRollCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rollCount++;
      prefs.setInt('rollCount', _rollCount);
    });
  }

  void _loadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          developer.log('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void _rollDice() {
    _animationController.forward(from: 0.0);
    setState(() {
      _diceValue = Random().nextInt(6) + 1;
    });
    if (!kIsWeb) {
      Vibration.vibrate(duration: 100);
    }
    _incrementRollCount();
    if (_rollCount % 5 == 0) {
      if (_interstitialAd != null) {
        _interstitialAd!.show();
        _loadInterstitialAd();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.green[700]!, Colors.green[900]!]
                : [Colors.greenAccent.shade100, Colors.greenAccent.shade400],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RotationTransition(
                turns: _animationController,
                child: GestureDetector(
                  onTap: _rollDice,
                  child: Text(
                    '$_diceValue',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _rollDice,
                child: const Text('Roll Dice'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isBannerAdReady && _bannerAd != null
          ? SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox(),
    );
  }
}
