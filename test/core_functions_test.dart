import 'package:flutter_test/flutter_test.dart';
import 'package:memory_box/viewmodels/add_memory_viewmodel.dart';

void main() {
  group('Unit Tests for Core Functions', () {
    test('Test 1: setTitle() - Should set the title correctly', () {
      print('\n=== Test 1: setTitle() ===');

      // Arrange
      final viewModel = AddMemoryViewModel();
      const String expectedTitle = 'My Memory';

      // Act
      viewModel.setTitle(expectedTitle);

      // Assert with console logs
      print('Expected: Title should be "$expectedTitle"');
      print('Actual: Title is "${viewModel.title}"');

      expect(viewModel.title, equals(expectedTitle));

      // Test with different value
      viewModel.setTitle('New Title');
      print('Expected: Title should be "New Title"');
      print('Actual: Title is "${viewModel.title}"');
      expect(viewModel.title, equals('New Title'));

      print('✓ Test 1 PASSED\n');
    });

    test('Test 2: setMapPosition() - Should clamp coordinates to valid range',
        () {
      print('\n=== Test 2: setMapPosition() ===');

      // Arrange
      final viewModel = AddMemoryViewModel();

      // Test case 1: Normal values
      print('Test Case 1: Normal values (50.0, 75.0)');
      viewModel.setMapPosition(50.0, 75.0);
      print('Expected: mapX should be 50.0');
      print('Actual: mapX is ${viewModel.mapX}');
      expect(viewModel.mapX, equals(50.0));

      print('Expected: mapY should be 75.0');
      print('Actual: mapY is ${viewModel.mapY}');
      expect(viewModel.mapY, equals(75.0));

      // Test case 2: Values above 100 (should be clamped)
      print('\nTest Case 2: Values above 100 (150.0, 200.0)');
      viewModel.setMapPosition(150.0, 200.0);
      print('Expected: mapX should be clamped to 100.0');
      print('Actual: mapX is ${viewModel.mapX}');
      expect(viewModel.mapX, equals(100.0));

      print('Expected: mapY should be clamped to 100.0');
      print('Actual: mapY is ${viewModel.mapY}');
      expect(viewModel.mapY, equals(100.0));

      // Test case 3: Negative values (should be clamped to 0)
      print('\nTest Case 3: Negative values (-10.0, -5.0)');
      viewModel.setMapPosition(-10.0, -5.0);
      print('Expected: mapX should be clamped to 0.0');
      print('Actual: mapX is ${viewModel.mapX}');
      expect(viewModel.mapX, equals(0.0));

      print('Expected: mapY should be clamped to 0.0');
      print('Actual: mapY is ${viewModel.mapY}');
      expect(viewModel.mapY, equals(0.0));

      print('✓ Test 2 PASSED\n');
    });

    test('Test 3: createMemory() - Should return null when title is empty', () {
      print('\n=== Test 3: createMemory() ===');

      // Arrange
      final viewModel = AddMemoryViewModel();

      // Test case 1: Empty title should return null
      print('Test Case 1: Empty title');
      viewModel.setTitle('');
      final result1 = viewModel.createMemory();
      print('Expected: createMemory() should return null');
      print(
          'Actual: createMemory() returned ${result1 == null ? "null" : "not null"}');
      expect(result1, isNull);

      // Test case 2: Valid title should return Memory object
      print('\nTest Case 2: Valid title');
      viewModel.setTitle('Test Memory');
      viewModel.setNote('This is a test note');
      viewModel.setEmoji('😊');
      viewModel.setMapPosition(50.0, 50.0);

      final result2 = viewModel.createMemory();
      print('Expected: createMemory() should return a Memory object');
      print(
          'Actual: createMemory() returned ${result2 == null ? "null" : "Memory object"}');
      expect(result2, isNotNull);

      if (result2 != null) {
        print('Expected: Memory title should be "Test Memory"');
        print('Actual: Memory title is "${result2.title}"');
        expect(result2.title, equals('Test Memory'));

        print('Expected: Memory note should be "This is a test note"');
        print('Actual: Memory note is "${result2.note}"');
        expect(result2.note, equals('This is a test note'));

        print('Expected: Memory emoji should be "😊"');
        print('Actual: Memory emoji is "${result2.emoji}"');
        expect(result2.emoji, equals('😊'));
      }

      print('✓ Test 3 PASSED\n');
    });
  });
}
