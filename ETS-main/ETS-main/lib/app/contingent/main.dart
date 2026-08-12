import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:malhar_ets/app/contingent/form_links/departments_page.dart';
import 'package:malhar_ets/app/contingent/login/login_page.dart';
import 'package:malhar_ets/constants/app_theme.dart';
import 'package:malhar_ets/constants/supabase/credentials.dart';
import 'package:malhar_ets/shared/pages/home.dart';
import 'package:malhar_ets/app/contingent/profile/profile_page.dart';
import 'package:malhar_ets/app/contingent/scores/scores_page.dart';
import 'package:malhar_ets/constants/app_bar.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/helpers/ambient_glow_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseCredentials.url,
    publishableKey: SupabaseCredentials.anonKey,
    authOptions: const FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
    ),
  );
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeData,
      // darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.system,
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Main extends StatefulWidget {
  final Contingent contingent;
  const Main({required this.contingent, super.key});

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;

  @override
  void initState() {
    PageRefreshController.onRefresh = loadData;
    initializeVars();
    loadData();
    subscribeToChannels();
    super.initState();
  }

  @override
  void dispose() {
    PageRefreshController.onRefresh = null;
    super.dispose();
  }

  void initializeVars() {
    _pages.addAll([
      Home(contingent: widget.contingent),
      DepartmentsPage(contingent: widget.contingent),
      ScoresPage(c: widget.contingent),
      ProfilePage(contingent: widget.contingent),
    ]);
  }

  void loadData() async {
    PageRefreshController.initialLoadCompleted = false;
    PageRefreshController.triggerRefresh();
    try {
      await Future.wait([
        DepartmentController().loadDepartments(),
        EventController().loadEvents(),
        ContingentController().loadContingents(),
        ParticipationController().loadParticipations(),
        FormLinkController().loadFormLinks(),
      ]);
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      PageRefreshController.initialLoadCompleted = true;
      PageRefreshController.triggerRefresh();
    }
  }

  void subscribeToChannels() {
    ContingentController().subscribeToContingents(navigatorKey);
    EventController().subscribeToEvents(navigatorKey);
    ParticipationController().subscribeToParticipations(navigatorKey);
    FormLinkController().subscribeToFormLinks(navigatorKey);
  }

  final List<Widget> _pages = [];
  final iconList = <IconData>[
    Icons.home,
    Icons.link_sharp,
    Icons.leaderboard_sharp,
    Icons.person,
  ];

  final labelList = <String>['Home', 'Form Links', 'Score', 'Profile'];

  @override
  Widget build(BuildContext context) {
    List<VoidCallback> actionList = [
      () {
        //Null Function
      },
      // () => AppFeedback.showInfo(context, 'Adding Contingent..'),
      () {
        //Null Function
      },
      () {
        //Null Function
      },
      () {
        //Null Function
      },
    ];
    return AmbientGlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        key: navigatorKey,
        appBar: getAppBar(context, true),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _pages[_currentIndex],
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: actionList[_currentIndex],
        backgroundColor: AppColors.primary,
        child: Icon(iconList[_currentIndex], color: AppColors.textWhite),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 250),
        tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final scale = 1.0 + 0.12 * value;
          final Color color = Color.lerp(Colors.white38, AppColors.primary, value)!;
          return SizedBox(
            width: 65,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Icon(iconList[index], size: 24, color: color),
                ),
                const SizedBox(height: 4),
                Transform.scale(
                  scale: 1.0 + 0.05 * value,
                  child: Text(
                    labelList[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color, 
                      fontSize: 10,
                      fontWeight: value > 0.5 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Growing glowing active line indicator
                Container(
                  height: 2,
                  width: 14 * value,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha((value * 180).toInt()),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16.0,
      ),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withAlpha(30),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withAlpha(150),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0),
                  _buildNavItem(1),
                  const SizedBox(width: 48), // FAB spacing gap
                  _buildNavItem(2),
                  _buildNavItem(3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

