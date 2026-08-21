import 'package:flutter/widgets.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida_example/demo_fonts.dart';
import 'package:kashida_example/justify.dart';

/// Shared playground state so the three scenes can be recorded as one story.
class DemoController extends ChangeNotifier {
  DemoController() : controller = TextEditingController(text: arabicSample);

  final TextEditingController controller;
  String patternName = 'arabic-naskh';
  String fontId = demoFonts.first.id;
  double fontSize = 24;
  double paragraphWidth = 600;
  double minKashidas = 2;
  double maxKashidas = 4;
  bool justify = true;
  bool applyKashida = true;
  bool removeExistingKashida = true;
  KashidaFillStyle? fillOverride;

  String get text => controller.text;

  DemoFont get font => demoFontById(fontId);

  TextStyle get textStyle => font.styleAt(fontSize);

  PatternSet get builtinSet => requiredBuiltinPatternSet(patternName);

  KashidaFillStyle get fillStyle => fillOverride ?? fillStyleFor(builtinSet);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _setText(String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void setText(String value) {
    _setText(value);
    notifyListeners();
  }

  void onTextChanged() => notifyListeners();

  void setPatternName(String name) {
    patternName = name;
    if (name == 'syriac' && text == arabicSample) {
      _setText(syriacSample);
      fontId = 'noto-sans-syriac';
    } else if (name != 'syriac' && text == syriacSample) {
      _setText(arabicSample);
      if (fontId == 'noto-sans-syriac') {
        fontId = demoFonts.first.id;
      }
    }
    fillOverride = null;
    notifyListeners();
  }

  void setFontId(String id) {
    fontId = id;
    final suggested = demoFontById(id).suggestedPattern;
    if (isBuiltinPatternSet(suggested)) {
      patternName = suggested;
      if (suggested == 'syriac' && text == arabicSample) {
        _setText(syriacSample);
      } else if (suggested != 'syriac' && text == syriacSample) {
        _setText(arabicSample);
      }
    }
    fillOverride = null;
    notifyListeners();
  }

  void setFontSize(double value) {
    fontSize = value;
    notifyListeners();
  }

  void setParagraphWidth(double value) {
    paragraphWidth = value;
    notifyListeners();
  }

  void setMinKashidas(double value) {
    minKashidas = value;
    if (minKashidas > maxKashidas) {
      maxKashidas = minKashidas;
    }
    notifyListeners();
  }

  void setMaxKashidas(double value) {
    maxKashidas = value;
    if (minKashidas > maxKashidas) {
      minKashidas = maxKashidas;
    }
    notifyListeners();
  }

  void setJustify(bool value) {
    justify = value;
    notifyListeners();
  }

  void setApplyKashida(bool value) {
    applyKashida = value;
    notifyListeners();
  }

  void setRemoveExistingKashida(bool value) {
    removeExistingKashida = value;
    notifyListeners();
  }

  void setFillOverride(KashidaFillStyle? value) {
    fillOverride = value;
    notifyListeners();
  }
}
