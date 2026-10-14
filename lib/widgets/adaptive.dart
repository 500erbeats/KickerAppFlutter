import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Auf iOS wird ein SwiftUI-nahes Cupertino-Design verwendet (damit sich für iOS-Nutzer
/// nichts ändert), auf Android das normale Material-3-Design.
bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

Route<T> adaptiveRoute<T>(WidgetBuilder builder, {bool fullscreenDialog = false}) => isIOS
    ? CupertinoPageRoute<T>(builder: builder, fullscreenDialog: fullscreenDialog)
    : MaterialPageRoute<T>(builder: builder, fullscreenDialog: fullscreenDialog);

/// Modale Seite (entspricht .sheet in SwiftUI) über den Root-Navigator, damit sie die Tab-Leiste überdeckt.
Future<T?> pushModal<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context, rootNavigator: true).push<T>(adaptiveRoute<T>(builder, fullscreenDialog: true));

Future<T?> pushPage<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context).push<T>(adaptiveRoute<T>(builder));

// ------------------------------------------------------------------ Farben

Color labelColor(BuildContext c) =>
    isIOS ? CupertinoColors.label.resolveFrom(c) : Theme.of(c).colorScheme.onSurface;
Color secondaryLabelColor(BuildContext c) =>
    isIOS ? CupertinoColors.secondaryLabel.resolveFrom(c) : Theme.of(c).colorScheme.onSurfaceVariant;
Color accentColor(BuildContext c) =>
    isIOS ? CupertinoTheme.of(c).primaryColor : Theme.of(c).colorScheme.primary;
Color cardColor(BuildContext c) =>
    isIOS ? CupertinoColors.systemGrey6.resolveFrom(c) : Theme.of(c).colorScheme.surfaceContainerHighest;
Color separatorColor(BuildContext c) =>
    isIOS ? CupertinoColors.separator.resolveFrom(c) : Theme.of(c).dividerColor;
Color successColor() => isIOS ? CupertinoColors.systemGreen : Colors.green;
Color errorColor() => isIOS ? CupertinoColors.systemRed : Colors.red;

// ---------------------------------------------------------------- Textstile

TextStyle headlineStyle(BuildContext c) => TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: labelColor(c));
TextStyle bodyStyle(BuildContext c) => TextStyle(fontSize: 17, color: labelColor(c));
TextStyle footnoteStyle(BuildContext c) => TextStyle(fontSize: 13, color: secondaryLabelColor(c));
TextStyle captionStyle(BuildContext c) => TextStyle(fontSize: 12, color: secondaryLabelColor(c));

// -------------------------------------------------------------- Scaffold

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.children,
    this.leading,
    this.trailing,
    this.grouped = false,
    this.inlineTitle = false,
    this.bottom,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final List<Widget> children;
  final Widget? leading;
  final Widget? trailing;
  final bool grouped;
  final bool inlineTitle;
  final Widget? bottom;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      final bg = grouped
          ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
          : CupertinoColors.systemBackground.resolveFrom(context);

      final scroll = CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (!inlineTitle)
            CupertinoSliverNavigationBar(
              largeTitle: Text(title),
              leading: leading,
              trailing: trailing,
              automaticallyImplyLeading: leading == null,
            ),
          SliverSafeArea(
            top: inlineTitle,
            bottom: bottom == null,
            sliver: SliverPadding(
              padding: padding,
              sliver: SliverList(delegate: SliverChildListDelegate(children)),
            ),
          ),
        ],
      );

      final body = bottom == null
          ? scroll
          : Column(children: [Expanded(child: scroll), SafeArea(top: false, child: bottom!)]);

      return CupertinoPageScaffold(
        backgroundColor: bg,
        navigationBar: inlineTitle
            ? CupertinoNavigationBar(
                middle: Text(title),
                leading: leading,
                trailing: trailing,
                automaticallyImplyLeading: leading == null,
              )
            : null,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: trailing == null ? null : [trailing!, const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: padding,
                children: children,
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

class BarIconButton extends StatelessWidget {
  const BarIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minSize: 32,
        onPressed: onPressed,
        child: Icon(icon, size: 22),
      );
    }
    return IconButton(icon: Icon(icon), onPressed: onPressed, tooltip: tooltip);
  }
}

class BarTextButton extends StatelessWidget {
  const BarTextButton({super.key, required this.label, required this.onPressed, this.bold = false});
  final String label;
  final VoidCallback? onPressed;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 32,
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      );
    }
    return TextButton(
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    );
  }
}

// --------------------------------------------------------------- Buttons

class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.prominent = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool prominent;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    Widget button;
    if (isIOS) {
      if (prominent) {
        button = CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(10),
          onPressed: onPressed,
          child: content,
        );
      } else {
        final accent = accentColor(context);
        button = CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          onPressed: onPressed,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: accent),
            child: IconTheme.merge(data: IconThemeData(color: accent), child: content),
          ),
        );
      }
    } else {
      button = prominent
          ? FilledButton(onPressed: onPressed, child: content)
          : FilledButton.tonal(onPressed: onPressed, child: content);
    }
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ----------------------------------------------------------- Eingabefelder

class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.borderless = false,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool borderless;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        autocorrect: autocorrect,
        padding: borderless ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.all(8),
        style: TextStyle(color: labelColor(context)),
        decoration: borderless ? const BoxDecoration() : null,
      );
    }
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      decoration: InputDecoration(labelText: placeholder, isDense: true, border: const OutlineInputBorder()),
    );
  }
}

class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) =>
      isIOS ? CupertinoSwitch(value: value, onChanged: onChanged) : Switch(value: value, onChanged: onChanged);
}

class AdaptiveSegmented<T extends Object> extends StatelessWidget {
  const AdaptiveSegmented({super.key, required this.value, required this.options, required this.onChanged});
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          children: {
            for (final e in options.entries)
              e.key: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(e.value, style: const TextStyle(fontSize: 13)),
              ),
          },
          onValueChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [for (final e in options.entries) ButtonSegment<T>(value: e.key, label: Text(e.value))],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

/// Entspricht SwiftUIs Stepper: Beschriftung links, [−|+] rechts.
class AdaptiveStepper extends StatelessWidget {
  const AdaptiveStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 50,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final text = Text('$label: $value', style: bodyStyle(context));
    if (isIOS) {
      final fill = CupertinoColors.tertiarySystemFill.resolveFrom(context);
      Widget btn(IconData icon, VoidCallback? onTap) => CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: onTap,
            child: SizedBox(
              width: 47,
              child: Icon(icon, size: 18, color: onTap == null ? CupertinoColors.systemGrey3 : labelColor(context)),
            ),
          );
      return Row(
        children: [
          Expanded(child: text),
          Container(
            decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              btn(CupertinoIcons.minus, value > min ? () => onChanged(value - 1) : null),
              Container(width: 1, height: 18, color: separatorColor(context)),
              btn(CupertinoIcons.plus, value < max ? () => onChanged(value + 1) : null),
            ]),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: text),
        IconButton(icon: const Icon(Icons.remove), onPressed: value > min ? () => onChanged(value - 1) : null),
        IconButton(icon: const Icon(Icons.add), onPressed: value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

// ---------------------------------------------------------------- Sektionen

/// Entspricht einer SwiftUI-`Section` in einer Form/List (iOS: inset-grouped).
class AdaptiveSection extends StatelessWidget {
  const AdaptiveSection({super.key, this.header, this.footer, required this.children});
  final String? header;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final c in children) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: c),
    ];
    if (isIOS) {
      return CupertinoListSection.insetGrouped(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        header: header == null ? null : Text(header!.toUpperCase(), style: footnoteStyle(context)),
        footer: footer == null ? null : Text(footer!, style: footnoteStyle(context)),
        children: rows,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Text(header!, style: Theme.of(context).textTheme.titleSmall),
            ),
          Card(margin: EdgeInsets.zero, child: Column(children: rows)),
          if (footer != null)
            Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(footer!, style: footnoteStyle(context))),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Dialoge

Future<void> showInfoAlert(BuildContext context, {required String title, String? message, String okLabel = 'OK'}) {
  if (isIOS) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: Text(okLabel)),
        ],
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(okLabel))],
    ),
  );
}

// ------------------------------------------------------------ Namens-Chips

/// Umbrechende Chip-Auswahl (kein horizontales Scrollen).
class NameChips extends StatelessWidget {
  const NameChips({super.key, required this.names, required this.selected, required this.onToggle});
  final List<String> names;
  final Set<String> selected;
  final void Function(String name, bool wasSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in names)
          Builder(builder: (context) {
            final isOn = selected.contains(name);
            if (!isIOS) {
              return FilterChip(label: Text(name), selected: isOn, onSelected: (_) => onToggle(name, isOn));
            }
            return GestureDetector(
              onTap: () => onToggle(name, isOn),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOn ? accent.withOpacity(0.15) : accent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isOn ? accent : const Color(0x00000000), width: 2),
                ),
                child: Text(name, style: TextStyle(fontSize: 17, color: isOn ? accent : CupertinoColors.white)),
              ),
            );
          }),
      ],
    );
  }
}
