import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes_app/core/constants/app_colors.dart';
import 'package:mynotes_app/main.dart';

void main() {
  testWidgets('MyNotesApp renders foundation shell and pastel color system',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyNotesApp(),
      ),
    );

    expect(find.text('MyNotes'), findsOneWidget);
    expect(AppColors.noteColorOptions.length, 8);
    expect(AppColors.fromHex('#A5F3AD'), AppColors.mintGreen);
  });
}
