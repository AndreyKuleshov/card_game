## Cloud Sync Implementation (2026-06-23)
- Files added: lib/data/{progress_repository,local_progress_repository,api_client,cloud_sync}.dart
- Merge policy: UNION cards, MAX node/kingdom-levels, crystals from newer timestamp
- Tests: test/data/cloud_sync_test.dart (pure mergeProgress, no network)
- analyze: clean, tests: green
