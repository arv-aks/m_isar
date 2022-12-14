import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/matchers.dart';

part 'where_string_test.g.dart';

@collection
class StringModel {
  StringModel();

  StringModel.init(this.field) : hashField = field;
  Id? id;

  @Index(type: IndexType.value)
  String? field = '';

  @Index(type: IndexType.hash)
  String? hashField = '';

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (other is StringModel) {
      return field == other.field && hashField == other.hashField;
    }
    return false;
  }
}

void main() {
  group('Where String', () {
    late Isar isar;
    late IsarCollection<StringModel> col;

    late StringModel objEmpty;
    late StringModel obj1;
    late StringModel obj2;
    late StringModel obj3;
    late StringModel obj4;
    late StringModel objNull;

    setUp(() async {
      isar = await openTempIsar([StringModelSchema]);
      col = isar.stringModels;

      await isar.writeTxn(() async {
        for (var i = 0; i < 5; i++) {
          final obj = StringModel.init('string $i');
          await col.put(obj);
        }
        await col.put(StringModel.init(null));
        await col.put(StringModel.init(''));
        await col.put(StringModel.init('string 4'));
      });
    });

    isarTest('.equalTo()', () async {
      await qEqual(
        col.where().hashFieldEqualTo('string 2'),
        [StringModel.init('string 2')],
      );
      await qEqual(
        col.where().fieldEqualTo('string 2'),
        [StringModel.init('string 2')],
      );

      await qEqual(
        col.where().hashFieldEqualTo(null),
        [StringModel.init(null)],
      );
      await qEqual(
        col.where().fieldEqualTo(null),
        [StringModel.init(null)],
      );

      await qEqual(col.where().hashFieldEqualTo('string 5'), []);
      await qEqual(col.where().fieldEqualTo('string 5'), []);

      await qEqual(
        col.where().hashFieldEqualTo(''),
        [StringModel.init('')],
      );
      await qEqual(
        col.where().fieldEqualTo(''),
        [StringModel.init('')],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(
        col.where().hashFieldIsNull(),
        [StringModel.init(null)],
      );
      await qEqual(
        col.where().fieldIsNull(),
        [StringModel.init(null)],
      );
    });

    isarTest('.isNotNull()', () async {
      await qEqualSet(
        col.where().hashFieldIsNotNull(),
        {
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqual(
        col.where().fieldIsNotNull(),
        [
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        ],
      );
    });

    isarTest('.notEqualTo()', () async {
      await qEqualSet(
        col.where().hashFieldNotEqualTo('string 4'),
        {
          StringModel.init(null),
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
        },
      );
      await qEqualSet(
        col.where().fieldNotEqualTo('string 4'),
        [
          StringModel.init(null),
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
        ],
      );
    });

    isarTest('.startsWith()', () async {
      await qEqual(
        col.where().fieldStartsWith('string'),
        [
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        ],
      );

      await qEqual(
        col.where().fieldStartsWith(''),
        [
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        ],
      );

      await qEqual(col.where().fieldStartsWith('S'), []);
    });
  });
}
