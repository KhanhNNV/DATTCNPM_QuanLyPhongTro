import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/home_page/view_models/home_page_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../../data/providers/user_provider.dart';
import '../../../data/models/response/user_model.dart';
import '../auth/login_screen.dart';

class HomePageScreen extends StatefulWidget {
  final String? selectedAreaId;

  const HomePageScreen({
    super.key,
    this.selectedAreaId,
  });

  @override
  State<HomePageScreen> createState() =>
      _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final UserProvider _userProvider = UserProvider();
  final HomePageViewModel _viewModel = HomePageViewModel();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.selectedAreaId != null) {
      _viewModel.loadRooms(widget.selectedAreaId!);
    }
  }

  @override
  void didUpdateWidget(covariant HomePageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedAreaId !=
        oldWidget.selectedAreaId) {

      if (widget.selectedAreaId != null) {
        _viewModel.loadRooms(
          widget.selectedAreaId!,
        );
      }
    }
  }

  Future<void> _fetchRoomsData() async {
    if (widget.selectedAreaId == null || widget.selectedAreaId!.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Gọi API lấy danh sách phòng theo ID khu trọ tại đây
      // Ví dụ: final rooms = await _roomProvider.getRooms(widget.selectedAreaId!);

      await Future.delayed(const Duration(milliseconds: 300)); // Giả lập call API
    } catch (e) {
      // Xử lý lỗi
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {

        if (_viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_viewModel.errorMessage != null) {
          return Center(
            child: Text(_viewModel.errorMessage!),
          );
        }

        if (_viewModel.rooms.isEmpty) {
          return const Center(
            child: Text("Khu trọ chưa có phòng"),
          );
        }

        return ListView.builder(
          itemCount: _viewModel.rooms.length,
          itemBuilder: (context, index) {

            final room = _viewModel.rooms[index];

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  "Phòng ${room.roomNumber}",
                ),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tầng: ${room.floor}",
                    ),
                    Text(
                      "Diện tích: ${room.areaSize} m²",
                    ),
                    Text(
                      "Giá thuê: ${room.rentPrice}",
                    ),
                    Text(
                      "Cọc: ${room.depositAmount}",
                    ),
                    Text(
                      "Tối đa: ${room.maxOccupants} người",
                    ),
                    Text(
                      "Trạng thái: ${room.status}",
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}