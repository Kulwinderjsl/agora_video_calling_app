import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_calling_app/screens/users/user_list_item.dart';

import '../../bloc/users/user_bloc.dart';
import '../../data/services/local_storage_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await LocalStorageService.init();
    context.read<UserListBloc>().add(const FetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<UserListBloc>().add(RefreshUsers());
            },
          ),
        ],
      ),
      body: BlocBuilder<UserListBloc, UserListState>(
        builder: (context, state) {
          if (state is UserListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserListError) {
            return _buildErrorState(state, context);
          } else if (state is UserListLoaded) {
            return _buildUserList(state);
          }
          return const Center(child: Text('Pull to refresh'));
        },
      ),
    );
  }

  Widget _buildUserList(UserListLoaded state) {
    return Column(
      children: [
        if (state.isFromCache)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Colors.amber[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.amber[800]),
                const SizedBox(width: 8),
                Text(
                  'Offline Mode - Showing Cached Data',
                  style: TextStyle(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<UserListBloc>().add(RefreshUsers());
            },
            child: ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return UserListItem(user: user);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(UserListError state, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load users',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (state.cachedUsers?.isNotEmpty ?? false)
            ElevatedButton(
              onPressed: () {
                context.read<UserListBloc>().add(
                  FetchUsers(forceRefresh: false),
                );
              },
              child: const Text('Show Cached Data'),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              context.read<UserListBloc>().add(RefreshUsers());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
