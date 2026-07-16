import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:broker_flutter_pp/ui/common/viewmodels/TaskViewModel.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';
import 'ManageLegsAndMilestones.dart';
import 'CircularRating.dart';

class MyMissions extends StatefulWidget {
  const MyMissions({Key? key}) : super(key: key);

  @override
  _MyMissionsState createState() => _MyMissionsState();
}

class _MyMissionsState extends State<MyMissions> {
  int _selectedIndex = 0;

  final List<String> _tabs = ["In Progress", "Completed", "Todo"];

  final List<Color> statusColors = [
    Palette.warning,
    Palette.success,
    Palette.primaryColor,
  ];

  final List<IconData> statusIcons = [
    Icons.timelapse_rounded,
    Icons.check_circle_rounded,
    Icons.pending_actions_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);

    taskViewModel.addTask(Task(
      brokerId: '1',
      flightNumber: 'AB123',
      departureFrom: 'City A',
      arriveAt: 'City B',
      status: 'In Progress',
      rating: 3,
      startDateTime: "21-9-2024",
      endDateTime: "30-9-2024",
      bid: "3000",
    ));
    taskViewModel.addTask(Task(
      brokerId: '2',
      flightNumber: 'CD456',
      departureFrom: 'City C',
      arriveAt: 'City D',
      status: 'Completed',
      rating: 2,
      startDateTime: "21-9-2024",
      endDateTime: "30-9-2024",
      bid: "3000",
    ));
    taskViewModel.addTask(Task(
      brokerId: '3',
      flightNumber: 'EF789',
      departureFrom: 'City E',
      arriveAt: 'City F',
      status: 'Todo',
      rating: 3,
      startDateTime: "21-9-2024",
      endDateTime: "30-9-2024",
      bid: "3000",
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dataMap = <String, double>{
      "In Progress": 40,
      "Completed": 30,
      "Todo": 30,
    };

    return Scaffold(
      backgroundColor: Palette.backgroundLight,
      body: Column(
        children: [
          // ── Chart + stats header ──────────────────────────────────
          Container(
            color: Palette.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                CircularRating(
                  dataMap: dataMap,
                  colorList: statusColors,
                ),
                const SizedBox(height: 16),

                // Stat tiles row
                Consumer<TaskViewModel>(
                  builder: (context, vm, _) {
                    return Row(
                      children: List.generate(_tabs.length, (i) {
                        final count = vm.getTasksByStatus(_tabs[i]).length;
                        return Expanded(
                          child: _StatTile(
                            label: _tabs[i],
                            count: count,
                            color: statusColors[i],
                            icon: statusIcons[i],
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Filter tabs ───────────────────────────────────────────
          Container(
            color: Palette.surface,
            child: Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Palette.borderLight),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final selected = _selectedIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected ? statusColors[i] : statusColors[i].withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcons[i], size: 15,
                                  color: selected ? Colors.white : statusColors[i]),
                              const SizedBox(width: 6),
                              Text(
                                _tabs[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : statusColors[i],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── Task list ─────────────────────────────────────────────
          Expanded(
            child: Consumer<TaskViewModel>(
              builder: (context, taskViewModel, _) {
                final tasks = taskViewModel.getTasksByStatus(_tabs[_selectedIndex]);
                final statusColor = statusColors[_selectedIndex];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcons[_selectedIndex], color: statusColor, size: 34),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No ${_tabs[_selectedIndex]} missions',
                          style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: Palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _MissionCard(
                      task: task,
                      statusColor: statusColor,
                      statusIcon: statusIcons[_selectedIndex],
                      statusLabel: _tabs[_selectedIndex],
                      onViewDetails: () => _navigateToLegsAndMilestones(task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLegsAndMilestones(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManageLegsAndMilestones(data: task)),
    );
  }
}

// ── Stat tile widget ─────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Mission card widget ──────────────────────────────────────────────────────
class _MissionCard extends StatelessWidget {
  final Task task;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final VoidCallback onViewDetails;

  const _MissionCard({
    required this.task,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Palette.primaryColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(width: 5, color: statusColor),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: flight number + status badge
                    Row(
                      children: [
                        if (task.flightNumber != null && task.flightNumber!.isNotEmpty) ...[
                          const Icon(Icons.flight_rounded, size: 14, color: Palette.primaryColor),
                          const SizedBox(width: 5),
                          Text(
                            task.flightNumber ?? '',
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Palette.primaryColor,
                            ),
                          ),
                          const Spacer(),
                        ] else
                          const Spacer(),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Route row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FROM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Palette.textDisabled, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(
                                task.departureFrom ?? 'N/A',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, color: statusColor, size: 18),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Palette.textDisabled, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(
                                task.arriveAt ?? 'N/A',
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 1, color: Palette.borderLight),
                    const SizedBox(height: 10),

                    // Bottom row: dates + bid + button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.bid != null && task.bid!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on_outlined, size: 13, color: Palette.secondaryColor),
                                    const SizedBox(width: 4),
                                    Text(task.bid!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Palette.secondaryColor)),
                                  ],
                                ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Palette.textDisabled),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${task.startDateTime ?? ''} – ${task.endDateTime ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: Palette.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
