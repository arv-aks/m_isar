import 'package:flutter/material.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/schema.dart';

class EditPopup extends StatefulWidget {
  const EditPopup({
    super.key,
    required this.type,
    required this.value,
  });

  final IsarType type;
  final dynamic value;

  @override
  State<EditPopup> createState() => _EditPopupState();
}

class _EditPopupState extends State<EditPopup> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _focus = FocusNode();
  CustomTextInputFormatter? _inputFormatter;

  bool? _boolValue;

  @override
  void initState() {
    if (widget.type == IsarType.Bool) {
      _boolValue = widget.value == null || widget.value as bool;
    } else {
      _controller.text = widget.value == null ? '' : widget.value.toString();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );

      if (widget.type != IsarType.String) {
        _inputFormatter = CustomTextInputFormatter(widget.type);
      }

      _focus.requestFocus();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.type == IsarType.String ? 500 : 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.type == IsarType.Bool)
            DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: _boolValue,
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('TRUE'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('FALSE'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _boolValue = value;
                    });
                  }
                },
              ),
            )
          else
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                focusNode: _focus,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
                inputFormatters: [
                  if (_inputFormatter != null) _inputFormatter!
                ],
                maxLines: widget.type == IsarType.String ? 3 : 1,
                validator: (value) {
                  if (widget.type == IsarType.Byte) {
                    final val = int.parse(value!);
                    if (val < 0 || val > 255) {
                      return 'Byte values must between 0-255';
                    }
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
            ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _save, child: const Text('Save')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _save() {
    dynamic value;

    if (widget.type == IsarType.Bool) {
      value = _boolValue;
    } else {
      if (_formKey.currentState!.validate()) {
        //ignore: missing_enum_constant_in_switch
        switch (widget.type) {
          case IsarType.Float:
          case IsarType.Double:
            value = double.tryParse(_controller.text) ?? 0.0;
            break;

          case IsarType.Byte:
          case IsarType.Int:
          case IsarType.Long:
            value = int.tryParse(_controller.text) ?? 0;
            break;
        }
        value ??= _controller.text;
      } else {
        return;
      }
    }

    Navigator.pop(context, {'value': value});
  }
}
