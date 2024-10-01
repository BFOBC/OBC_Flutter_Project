/*
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/res/structure.dart';
import 'package:broker_flutter_pp/ui/common/widgets/app_bar_title.dart';
import 'package:broker_flutter_pp/ui/common/widgets/footer.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<bool> _isExpanded = [false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Palette.firebaseNavy,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Palette.firebaseNavy,
        ),
        title: const AppBarTitle(
          sectionName: 'Samples',
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                bottom: 80.0,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Palette.firebaseNavy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) => const SizedBox(
                      height: 12.0,
                    ),
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      final item = menu[index];
                      final iconPath = item['icons'] ?? ''; // Provide default empty string if null
                      final name = item['name'] ?? 'Unnamed'; // Provide default name if null
                      final screens = item['screens'] ?? []; // Provide empty list if null

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == menu.length - 1 ? 30.0 : 0.0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ExpansionPanelList(
                            expansionCallback: (panelIndex, isExpanded) {
                              setState(() {
                                _isExpanded[index] = !_isExpanded[index];
                              });
                            },
                            children: [
                              ExpansionPanel(
                                backgroundColor: Colors.black54,
                                canTapOnHeader: true,
                                headerBuilder:
                                    (BuildContext context, bool isExpanded) {
                                  return Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          24.0,
                                          16.0,
                                          16.0,
                                          16.0,
                                        ),
                                        child: Image.asset(
                                          iconPath,
                                          color: Palette.firebaseYellow,
                                          width: 40.0,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.error, color: Colors.red, size: 40.0);
                                          },
                                        ),
                                      ),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    ],
                                  );
                                },
                                body: ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                                  itemCount: screens.length,
                                  itemBuilder: (context, index2) {
                                    final screen = screens[index2];
                                    final screenName = screen['name'] ?? 'Unnamed';
                                    final screenWidget = screen['widget'];
                                    final screenIcon = screen['icon'] ?? Icon(Icons.error);

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(16.0),
                                      onTap: screenWidget != null
                                          ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => screenWidget,
                                          ),
                                        );
                                      }
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          24.0,
                                          16.0,
                                          16.0,
                                          16.0,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: screenWidget != null
                                                  ? Palette.firebaseAmber
                                                  : Palette.firebaseGrey.withOpacity(0.5),
                                              child: screenIcon,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              screenName,
                                              style: TextStyle(
                                                color: screenWidget != null
                                                    ? Palette.firebaseYellow
                                                    : Palette.firebaseGrey.withOpacity(0.5),
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                isExpanded: _isExpanded[index],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Footer(),
            ),
          ],
        ),
      ),
    );
  }
}
*/
