// import 'package:flutter/material.dart';
// import 'package:spotkin_flutter/app_core.dart';
// import 'package:spotkin_flutter/services/backup_service.dart';

// class JobManagementScreen extends StatefulWidget {
//   const JobManagementScreen({super.key});

//   @override
//   _JobManagementScreenState createState() => _JobManagementScreenState();
// }

// class _JobManagementScreenState extends State<JobManagementScreen> {
//   final StorageService _storageService = StorageService();
//   late BackupService _backupService;
//   List<Job> _jobs = [];

//   @override
//   void initState() {
//     super.initState();
//     _backupService = BackupService(_storageService);
//     _loadJobs();
//   }

//   void _loadJobs() {
//     setState(() {
//       _jobs = _storageService.getJobs();
//     });
//   }

//   void _createBackup() {
//     _backupService.createBackup();
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//           content: Text('Backup file created. Check your downloads.')),
//     );
//   }

//   Future<void> _importBackup() async {
//     await _backupService.importBackup();
//     _loadJobs(); // Reload jobs after import
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Backup imported and jobs updated.')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Job Management')),
//       body: Column(
//         children: [
//           ElevatedButton(
//             onPressed: _createBackup,
//             child: const Text('Create Backup File'),
//           ),
//           ElevatedButton(
//             onPressed: _importBackup,
//             child: const Text('Import Backup File'),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _jobs.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(_jobs[index].targetPlaylist.name ?? 'Untitled'),
//                   subtitle: Text('Recipe count: ${_jobs[index].recipe.length}'),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
