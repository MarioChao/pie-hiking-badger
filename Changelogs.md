# Changelogs

## [v1.1.0] Data optimization | 2026/08/30

Added new data store `CombinedUserInfo` for retrieving all ranks & usernames more efficiently.
- Migrated the Hiker Hall to use this data store, greatly improving the retrieval time.
- Also allows much more ranks to be retrieved in the future.
- The old data store `TestedRank` is still used for storing personal rank data.

Populated `CombinedUserInfo` with all data from `TestedRank` via the `DataMigration` script.

## [v1.0.3] Player name cache + Auto refresh | 2026/03/14

`GetNameFromUserIdAsync()` is now cached in memory store.
- The cache expires every hour.

Added auto refresh to Hiker's Hall.
- Clears & refreshes data every hour.
- Refresh time is also displayed.

## [v1.0.2] Hiker's hall | 2026/03/12 (2)

Added script for Hiker's Hall (Hall of Hikers).
- Reads data store through `DataStoreReader`.
- Displays all users categorized by ranks.

## [v1.0.1] Badge Util migration + Small changes | 2026/03/12 (1)

Replaced badge modules with [`BadgeUtil`](https://github.com/MarioChao/badge-util).

Slightly changed how throttle is used in the `GiveRankBadge` script.
