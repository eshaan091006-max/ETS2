import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/admin/cards/contingent_card.dart';
import 'package:malhar_ets/app/admin/contingent/events_participated_page.dart';
import 'package:malhar_ets/app/admin/modals/contingent_modal.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/helpers/page_transitions.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/helpers/animated_card_wrapper.dart';
import 'package:malhar_ets/helpers/empty_state_widget.dart';
import 'package:malhar_ets/helpers/glowing_search_field.dart';
import 'package:malhar_ets/helpers/shimmer_skeleton.dart';

class ContingentManagementPage extends StatefulWidget {
  const ContingentManagementPage({super.key});

  @override
  State<ContingentManagementPage> createState() =>
      _ContingentManagementPageState();
}

class _ContingentManagementPageState extends State<ContingentManagementPage> {
  final ContingentController _contingentController = ContingentController();
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return ValueListenableBuilder(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, value, child) {
        final query = _searchController.text.trim().toLowerCase();
        final List<Contingent> filteredContingents = _contingentController.contingents
            .where((c) => c.contingentCode.toLowerCase().contains(query))
            .toList();

        return Column(
          children: [
            /// Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GlowingSearchField(
                controller: _searchController,
                hintText: 'Search Contingents...',
                onChanged: (text) {
                  setState(() {});
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),

            if (PageRefreshController.initialLoadCompleted)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Showing ${filteredContingents.length} of ${_contingentController.contingents.length} contingents',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            /// Contingents List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.secondary,
                onRefresh: () async {
                  if (PageRefreshController.onRefresh != null) {
                    PageRefreshController.onRefresh!();
                  }
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: !PageRefreshController.initialLoadCompleted
                    ? const ShimmerSkeletonList(itemCount: 3, cardHeight: 120.0)
                    : filteredContingents.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              alignment: Alignment.center,
                          child: EmptyStateWidget(
                            title: 'No Contingents Found',
                            subtitle: 'We couldn\'t find any contingents matching your search.',
                            icon: Icons.group_off,
                            action: TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: const Text(
                                "Clear Search",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredContingents.length,
                        itemBuilder: (context, index) {
                          Contingent contingent = filteredContingents[index];

                          final navigateToEvents = () => Navigator.of(context).push(
                            LiquidPageRoute(
                              page: EventsParticipatedPage(contingent: contingent),
                            ),
                          );

                          return AnimatedCardWrapper(
                            key: ValueKey(contingent.contingentId),
                            child: GestureDetector(
                              onDoubleTap: navigateToEvents,
                              child: ContingentCard(
                                contingent: contingent,
                                onEdit:
                                    () => showContingentModal(
                                      context,
                                      contingent: contingent,
                                      onSubmit: (contingent) async {
                                        await ContingentController().updateContingent(
                                          context,
                                          contingent,
                                        );
                                      },
                                    ),
                                onDelete: () async {
                                  await ContingentController().deleteContingent(
                                    context,
                                    contingent.contingentId,
                                  );
                                },
                                onViewEvents: navigateToEvents,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
