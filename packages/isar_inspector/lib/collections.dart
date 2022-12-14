import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/desktop/download.dart'
    if (dart.library.html) 'package:isar_inspector/web/download.dart';
import 'package:isar_inspector/query_builder.dart';
import 'package:isar_inspector/state/collections_state.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/isar_connect_state_notifier.dart';
import 'package:isar_inspector/state/query_state.dart';

class CollectionsList extends ConsumerWidget {
  const CollectionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collections = ref.watch(collectionsPod).valueOrNull ?? [];
    final collectionInfo = ref.watch(collectionInfoPod);
    final selectedCollection = ref.watch(selectedCollectionPod).valueOrNull;
    final isarConnect = ref.watch(isarConnectPod.notifier);
    final selectedInstance = ref.watch(selectedInstancePod).value!;

    return ListView.builder(
      primary: false,
      itemBuilder: (BuildContext context, int index) {
        final collection = collections.elementAt(index);
        final info = collectionInfo[collection.name];

        return SizedBox(
          height: 55,
          child: IsarCard(
            color: collection == selectedCollection ? theme.primaryColor : null,
            radius: BorderRadius.circular(60),
            onTap: () {
              if (ref.read(selectedCollectionNamePod.state).state !=
                  collection.name) {
                ref.read(selectedCollectionNamePod.state).state =
                    collection.name;

                ref.read(queryFilterPod.state).state =
                    collection.uiFilter == null
                        ? null
                        : QueryBuilderUI.parseQuery(collection.uiFilter!);

                ref.read(querySortPod.state).state = collection.uiSort;
                ref.read(queryPagePod.state).state = 1;
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: collection.name,
                      child: Text(
                        collection.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (info != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          info.count.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatSize(info.size),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 5),
                  ],
                  GestureDetector(
                    onTap: () async {
                      final query = ConnectQuery(
                        instance: selectedInstance,
                        collection: collection.name,
                      );

                      final data = await isarConnect.exportJson(query);

                      await download(
                        data,
                        '${selectedInstance}_${collection.name}.json',
                      );
                    },
                    child: Tooltip(
                      message: 'Download collection',
                      child: Icon(
                        Icons.download,
                        size: 30,
                        color: info != null && info.count == 0
                            ? Colors.grey
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      itemCount: collections.length,
    );
  }
}

String _formatSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  final i = (log(bytes) / log(1000)).floor();
  return '${(bytes / pow(1000, i)).toStringAsFixed(2)} ${suffixes[i]}';
}
