import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/schema.dart';

class QueryBuilderUI extends StatefulWidget {
  const QueryBuilderUI({
    super.key,
    required this.collection,
    this.filter,
    this.sort,
  });

  final ICollection collection;
  final QueryBuilderUIGroupHelper? filter;
  final SortProperty? sort;

  @override
  State<QueryBuilderUI> createState() => _QueryBuilderUIState();

  static FilterOperation parseQuery(QueryBuilderUIGroupHelper group) {
    final filters = <FilterOperation>[];
    for (final item in group.children) {
      if (item is QueryBuilderUIGroupHelper) {
        filters.add(parseQuery(item));
      } else if (item is _ConditionHelper) {
        filters.add(_parseCondition(item));
      } else if (item is _LinkHelper) {
        filters.add(_parseLink(item));
      }
    }

    final filter = FilterGroup(
      filters: filters,
      type: group.operation,
    );

    return group.not ? FilterGroup.not(filter) : filter;
  }

  static FilterOperation _parseCondition(_ConditionHelper condition) {
    FilterOperation ret;
    switch (condition.type) {
      case _ConditionType.equalTo:
        ret = FilterCondition.equalTo(
          property: condition.property.name,
          value: condition.parsedValue,
          caseSensitive: !(condition.generic == GenericType.string) ||
              condition.caseSensitive,
        );
        break;

      case _ConditionType.greaterThan:
      case _ConditionType.greaterOrEqualThan:
        ret = FilterCondition.greaterThan(
          property: condition.property.name,
          value: condition.parsedValue,
          include: condition.type == _ConditionType.greaterOrEqualThan,
        );
        break;

      case _ConditionType.lessThan:
      case _ConditionType.lessOrEqualThan:
        ret = FilterCondition.lessThan(
          property: condition.property.name,
          value: condition.parsedValue,
          include: condition.type == _ConditionType.lessOrEqualThan,
        );
        break;

      case _ConditionType.startsWith:
        ret = FilterCondition.startsWith(
          property: condition.property.name,
          value: condition.parsedValue as String,
          caseSensitive: condition.caseSensitive,
        );
        break;

      case _ConditionType.endsWith:
        ret = FilterCondition.endsWith(
          property: condition.property.name,
          value: condition.parsedValue as String,
          caseSensitive: condition.caseSensitive,
        );
        break;

      case _ConditionType.contains:
        ret = FilterCondition.contains(
          property: condition.property.name,
          value: condition.parsedValue as String,
          caseSensitive: condition.caseSensitive,
        );
        break;

      case _ConditionType.matches:
        ret = FilterCondition.matches(
          property: condition.property.name,
          wildcard: condition.parsedValue as String,
          caseSensitive: condition.caseSensitive,
        );
        break;

      case _ConditionType.isNull:
        ret = FilterCondition.isNull(property: condition.property.name);
        break;
    }

    return condition.not ? FilterGroup.not(ret) : ret;
  }

  static FilterOperation _parseLink(_LinkHelper link) {
    final filters = <FilterOperation>[];

    for (final item in link.children) {
      if (item is QueryBuilderUIGroupHelper) {
        filters.add(parseQuery(item));
      } else if (item is _ConditionHelper) {
        filters.add(_parseCondition(item));
      }
    }

    return LinkFilter(
      filter: FilterGroup(filters: filters, type: link.operation),
      linkName: link.link.name,
      targetCollection: link.link.target.name,
    );
  }
}

class _QueryBuilderUIState extends State<QueryBuilderUI> {
  late final QueryBuilderUIGroupHelper _filter;
  late SortProperty? _sort = widget.sort;
  late final List<IProperty> _sortProps;

  @override
  void initState() {
    super.initState();

    if (widget.filter != null) {
      _filter = widget.filter!.clone();
    } else {
      _filter = QueryBuilderUIGroupHelper();
    }

    _sortProps =
        widget.collection.allProperties.where((p) => !p.type.isList).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width - 200,
      height: size.height - 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: size.height - 270),
                child: _GroupUI(
                  helper: _filter,
                  collection: widget.collection,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {'filter': _filter, 'sort': _sort});
                },
                child: const Text('Build'),
              ),
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    {'filter': QueryBuilderUIGroupHelper(), 'sort': null},
                  );
                },
                child: const Text('Clear'),
              ),
              const Spacer(),
              CheckBoxLabel(
                value: _sort != null,
                text: 'Sort By',
                onChanged: (value) {
                  setState(() {
                    _sort = !value
                        ? null
                        : SortProperty(
                            property: _sortProps.first.name,
                            sort: Sort.asc,
                          );
                  });
                },
              ),
              const SizedBox(width: 15),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sort?.property ?? _sortProps.first.name,
                  items: _sortProps
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.name,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: _sort == null
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _sort = SortProperty(
                                property: value,
                                sort: _sort!.sort,
                              );
                            });
                          }
                        },
                ),
              ),
              const SizedBox(width: 15),
              DropdownButtonHideUnderline(
                child: DropdownButton<Sort>(
                  value: _sort?.sort ?? Sort.asc,
                  items: const [
                    DropdownMenuItem(
                      value: Sort.asc,
                      child: Text('ASC'),
                    ),
                    DropdownMenuItem(
                      value: Sort.desc,
                      child: Text('DESC'),
                    )
                  ],
                  onChanged: _sort == null
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _sort = SortProperty(
                                property: _sort!.property,
                                sort: value,
                              );
                            });
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupUI extends StatefulWidget {
  const _GroupUI({
    required this.helper,
    required this.collection,
    this.index,
    this.removeItem,
    this.link,
  });

  final QueryBuilderUIGroupHelper helper;
  final ICollection collection;
  final int? index;
  final ILink? link;
  final void Function(int index)? removeItem;

  @override
  State<_GroupUI> createState() => _GroupUIState();
}

class _GroupUIState extends State<_GroupUI> {
  @override
  Widget build(BuildContext context) {
    return IsarCard(
      side: const BorderSide(color: Colors.blue),
      radius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                _GroupButton(
                  onTap: () {
                    setState(() {
                      widget.helper.operation = FilterGroupType.and;
                    });
                  },
                  color: widget.helper.operation == FilterGroupType.and
                      ? Colors.blue
                      : null,
                  child: const Text('And'),
                ),
                const SizedBox(width: 5),
                _GroupButton(
                  onTap: () {
                    setState(() {
                      widget.helper.operation = FilterGroupType.or;
                    });
                  },
                  color: widget.helper.operation == FilterGroupType.or
                      ? Colors.blue
                      : null,
                  child: const Text('Or'),
                ),
                const SizedBox(width: 5),
                _GroupButton(
                  onTap: () {
                    setState(() {
                      widget.helper.operation = FilterGroupType.xor;
                    });
                  },
                  color: widget.helper.operation == FilterGroupType.xor
                      ? Colors.blue
                      : null,
                  child: const Text('Xor'),
                ),
                const SizedBox(width: 15),
                CheckBoxLabel(
                  value: widget.helper.not,
                  text: 'NOT',
                  onChanged: (value) {
                    setState(() {
                      widget.helper.not = value;
                    });
                  },
                ),
                const Spacer(),
                if (widget.link == null && widget.collection.links.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        widget.helper.children.add(
                          _LinkHelper(widget.collection.links.first),
                        );
                      });
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Link'),
                  ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.helper.children.add(
                        _ConditionHelper(widget.collection.allProperties.first),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Condition'),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.helper.children.add(QueryBuilderUIGroupHelper());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('(Group)'),
                ),
                if (widget.index != null)
                  IconButton(
                    color: Colors.blue,
                    onPressed: () {
                      widget.removeItem!(widget.index!);
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 20),
              child: Column(
                children: _generateChildren(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateChildren() {
    final children = <Widget>[];

    for (var index = 0; index < widget.helper.children.length; index++) {
      if (widget.helper.children[index] is QueryBuilderUIGroupHelper) {
        children.add(
          _GroupUI(
            helper: widget.helper.children[index] as QueryBuilderUIGroupHelper,
            collection: widget.collection,
            link: widget.link,
            removeItem: _removeItem,
            index: index,
          ),
        );
      } else if (widget.helper.children[index] is _ConditionHelper) {
        children.add(
          _ConditionUI(
            helper: widget.helper.children[index] as _ConditionHelper,
            collection: widget.collection,
            link: widget.link,
            removeItem: _removeItem,
            index: index,
          ),
        );
      } else if (widget.helper.children[index] is _LinkHelper) {
        children.add(
          _LinkUI(
            helper: widget.helper.children[index] as _LinkHelper,
            collection: widget.collection,
            removeItem: _removeItem,
            index: index,
          ),
        );
      }

      children.add(const SizedBox(height: 15));
    }
    return children;
  }

  void _removeItem(int index) {
    setState(() {
      widget.helper.children.removeAt(index);
    });
  }
}

class _LinkUI extends StatefulWidget {
  const _LinkUI({
    required this.helper,
    required this.index,
    required this.removeItem,
    required this.collection,
  });

  final _LinkHelper helper;
  final ICollection collection;
  final int index;
  final void Function(int index) removeItem;

  @override
  State<_LinkUI> createState() => _LinkUIState();
}

class _LinkUIState extends State<_LinkUI> {
  @override
  Widget build(BuildContext context) {
    return IsarCard(
      side: const BorderSide(color: Colors.green),
      radius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<ILink>(
                    value: widget.helper.link,
                    items: widget.collection.links.map((e) {
                      return DropdownMenuItem(value: e, child: Text(e.name));
                    }).toList(),
                    onChanged: widget.helper.children.isNotEmpty
                        ? null
                        : (link) {
                            if (link != null) {
                              setState(() {
                                widget.helper.link = link;
                              });
                            }
                          },
                  ),
                ),
                const SizedBox(width: 5),
                _GroupButton(
                  onTap: () {
                    setState(() {
                      widget.helper.operation = FilterGroupType.and;
                    });
                  },
                  color: widget.helper.operation == FilterGroupType.and
                      ? Colors.blue
                      : null,
                  child: const Text('And'),
                ),
                const SizedBox(width: 5),
                _GroupButton(
                  onTap: () {
                    setState(() {
                      widget.helper.operation = FilterGroupType.or;
                    });
                  },
                  color: widget.helper.operation == FilterGroupType.or
                      ? Colors.blue
                      : null,
                  child: const Text('Or'),
                ),
                const SizedBox(width: 5),
                _GroupButton(
                  onTap: () {
                    setState(() {
                      widget.helper.operation = FilterGroupType.xor;
                    });
                  },
                  color: widget.helper.operation == FilterGroupType.xor
                      ? Colors.blue
                      : null,
                  child: const Text('Xor'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.helper.children.add(
                        _ConditionHelper(
                          widget.helper.link.target.allProperties.first,
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Condition'),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.helper.children.add(
                        QueryBuilderUIGroupHelper(),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('(Group)'),
                ),
                IconButton(
                  color: Colors.blue,
                  onPressed: () {
                    widget.removeItem(widget.index);
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 20),
              child: Column(
                children: _generateChildren(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateChildren() {
    final children = <Widget>[];

    for (var index = 0; index < widget.helper.children.length; index++) {
      if (widget.helper.children[index] is QueryBuilderUIGroupHelper) {
        children.add(
          _GroupUI(
            helper: widget.helper.children[index] as QueryBuilderUIGroupHelper,
            collection: widget.collection,
            link: widget.helper.link,
            removeItem: _removeItem,
            index: index,
          ),
        );
      } else {
        children.add(
          _ConditionUI(
            helper: widget.helper.children[index] as _ConditionHelper,
            collection: widget.collection,
            link: widget.helper.link,
            removeItem: _removeItem,
            index: index,
          ),
        );
      }

      children.add(const SizedBox(height: 15));
    }
    return children;
  }

  void _removeItem(int index) {
    setState(() {
      widget.helper.children.removeAt(index);
    });
  }
}

class _ConditionUI extends StatefulWidget {
  const _ConditionUI({
    required this.helper,
    required this.index,
    required this.removeItem,
    required this.collection,
    this.link,
  });

  final _ConditionHelper helper;
  final int index;
  final void Function(int index) removeItem;
  final ICollection collection;
  final ILink? link;

  @override
  State<_ConditionUI> createState() => _ConditionUIState();
}

class _ConditionUIState extends State<_ConditionUI> {
  late final properties =
      widget.link?.target.allProperties ?? widget.collection.allProperties;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<IProperty>(
            value: widget.helper.property,
            items: properties
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (property) {
              if (property != null) {
                setState(() {
                  widget.helper.property = property;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 20),
        CheckBoxLabel(
          value: widget.helper.not,
          text: 'NOT',
          onChanged: (not) {
            setState(() {
              widget.helper.not = not;
            });
          },
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 190,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_ConditionType>(
              value: widget.helper.type,
              items: widget.helper.types
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() {
                    widget.helper.type = type;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 20),
        if (widget.helper.generic == GenericType.string) ...[
          CheckBoxLabel(
            text: 'Case',
            value: widget.helper.caseSensitive,
            onChanged: (value) {
              setState(() {
                widget.helper.caseSensitive = value;
              });
            },
          ),
          const SizedBox(width: 20),
        ],
        if (widget.helper.generic != GenericType.bool &&
            widget.helper.type != _ConditionType.isNull)
          Expanded(
            child: TextField(
              controller: widget.helper.controller,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              inputFormatters: [
                if (widget.helper.textFormatter != null)
                  widget.helper.textFormatter!
              ],
              style: GoogleFonts.sourceCodePro(),
            ),
          )
        else if (widget.helper.type != _ConditionType.isNull) ...[
          DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              value: widget.helper.boolValue,
              items: const [
                DropdownMenuItem(value: true, child: Text('TRUE')),
                DropdownMenuItem(value: false, child: Text('FALSE')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    widget.helper.boolValue = value;
                  });
                }
              },
            ),
          ),
          const Spacer()
        ] else
          const Spacer(),
        IconButton(
          color: Colors.blue,
          onPressed: () {
            widget.removeItem(widget.index);
          },
          icon: const Icon(Icons.clear),
        ),
      ],
    );
  }
}

class _GroupButton extends StatelessWidget {
  const _GroupButton({
    required this.onTap,
    required this.child,
    this.color,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

//ignore: one_member_abstracts
abstract class QueryBuilderUIHelper {
  QueryBuilderUIHelper clone();
}

class QueryBuilderUIGroupHelper extends QueryBuilderUIHelper {
  QueryBuilderUIGroupHelper();

  FilterGroupType operation = FilterGroupType.and;
  bool not = false;
  final children = <QueryBuilderUIHelper>[];

  @override
  QueryBuilderUIGroupHelper clone() {
    return QueryBuilderUIGroupHelper()
      ..operation = operation
      ..not = not
      ..children.addAll(children.map((e) => e.clone()).toList());
  }
}

enum _ConditionType {
  equalTo,
  greaterThan,
  greaterOrEqualThan,
  lessThan,
  lessOrEqualThan,
  startsWith,
  endsWith,
  contains,
  matches,
  isNull;
}

enum GenericType { int, double, string, bool }

class _ConditionHelper extends QueryBuilderUIHelper {
  _ConditionHelper(IProperty property) {
    _property = property;
    type = types.first;
  }

  late IProperty _property;
  bool not = false;
  bool caseSensitive = true;
  bool boolValue = true;
  late _ConditionType type;
  TextEditingController controller = TextEditingController();

  IProperty get property => _property;

  @override
  _ConditionHelper clone() {
    return _ConditionHelper(property)
      ..not = not
      ..caseSensitive = caseSensitive
      ..boolValue = boolValue
      ..type = type
      ..controller = controller;
  }

  set property(IProperty property) {
    _property = property;
    not = false;
    caseSensitive = true;
    boolValue = true;

    if (!types.contains(type)) {
      type = types.first;
    }

    controller.clear();
  }

  List<_ConditionType> get types {
    if (property.isId) {
      return const [
        _ConditionType.equalTo,
        _ConditionType.greaterThan,
        _ConditionType.greaterOrEqualThan,
        _ConditionType.lessThan,
        _ConditionType.lessOrEqualThan,
      ];
    }

    switch (property.type) {
      case IsarType.BoolList:
      case IsarType.Bool:
        return const [_ConditionType.equalTo, _ConditionType.isNull];

      case IsarType.ByteList:
      case IsarType.IntList:
      case IsarType.FloatList:
      case IsarType.LongList:
      case IsarType.DoubleList:
      case IsarType.Int:
      case IsarType.Float:
      case IsarType.Long:
      case IsarType.Byte:
      case IsarType.Double:
        return const [
          _ConditionType.equalTo,
          _ConditionType.greaterThan,
          _ConditionType.greaterOrEqualThan,
          _ConditionType.lessThan,
          _ConditionType.lessOrEqualThan,
          _ConditionType.isNull
        ];

      case IsarType.String:
      case IsarType.StringList:
        return const [
          _ConditionType.equalTo,
          _ConditionType.contains,
          _ConditionType.startsWith,
          _ConditionType.endsWith,
          _ConditionType.matches,
          _ConditionType.isNull
        ];
    }
  }

  CustomTextInputFormatter? get textFormatter {
    switch (property.type) {
      case IsarType.String:
      case IsarType.StringList:
      case IsarType.BoolList:
      case IsarType.Bool:
        return null;

      case IsarType.IntList:
      case IsarType.LongList:
      case IsarType.Int:
      case IsarType.Long:
        return CustomTextInputFormatter(IsarType.Int);

      case IsarType.ByteList:
      case IsarType.Byte:
        return CustomTextInputFormatter(IsarType.Byte);

      case IsarType.FloatList:
      case IsarType.DoubleList:
      case IsarType.Float:
      case IsarType.Double:
        return CustomTextInputFormatter(IsarType.Double);
    }
  }

  GenericType get generic {
    switch (property.type) {
      case IsarType.Bool:
      case IsarType.BoolList:
        return GenericType.bool;

      case IsarType.Long:
      case IsarType.Int:
      case IsarType.Byte:
      case IsarType.ByteList:
      case IsarType.IntList:
      case IsarType.LongList:
        return GenericType.int;

      case IsarType.Double:
      case IsarType.FloatList:
      case IsarType.Float:
      case IsarType.DoubleList:
        return GenericType.double;

      case IsarType.StringList:
      case IsarType.String:
        return GenericType.string;
    }
  }

  dynamic get parsedValue {
    switch (generic) {
      case GenericType.int:
        return int.tryParse(controller.text) ?? 0;

      case GenericType.double:
        return double.tryParse(controller.text) ?? 0.0;

      case GenericType.string:
        return controller.text;

      case GenericType.bool:
        return boolValue;
    }
  }
}

class _LinkHelper extends QueryBuilderUIHelper {
  _LinkHelper(this.link);

  FilterGroupType operation = FilterGroupType.and;
  ILink link;
  final children = <QueryBuilderUIHelper>[];

  @override
  _LinkHelper clone() {
    return _LinkHelper(link)
      ..operation = operation
      ..children.addAll(children.map((e) => e.clone()).toList());
  }
}
