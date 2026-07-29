import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mapo_app/themes/app_colors.dart';

void main() {
  test('categoryTone memetakan tiap kategori ke tone yang benar', () {
    expect(categoryTone('berkuah'), CategoryTone.blue);
    expect(categoryTone('nasi'), CategoryTone.blue);
    expect(categoryTone('cepat_saji'), CategoryTone.blue);
    expect(categoryTone('unknown_category'), CategoryTone.blue);
    expect(categoryTone('pedas'), CategoryTone.red);
    expect(categoryTone('bakar'), CategoryTone.red);
    expect(categoryTone('goreng'), CategoryTone.red);
    expect(categoryTone('sehat'), CategoryTone.green);
    expect(categoryTone('mie'), CategoryTone.green);
    expect(categoryTone('manis'), CategoryTone.amber);
    expect(categoryTone('cemilan'), CategoryTone.amber);
  });

  test('categoryIcon mengembalikan HugeIcons yang sesuai per kategori', () {
    expect(categoryIcon('berkuah'), same(HugeIcons.strokeRoundedRiceBowl01));
    expect(categoryIcon('pedas'), same(HugeIcons.strokeRoundedFire));
    expect(categoryIcon('bakar'), same(HugeIcons.strokeRoundedBbqGrill));
    expect(categoryIcon('goreng'), same(HugeIcons.strokeRoundedChickenThighs));
    expect(categoryIcon('manis'), same(HugeIcons.strokeRoundedCakeSlice));
    expect(categoryIcon('sehat'), same(HugeIcons.strokeRoundedSalad));
    expect(categoryIcon('mie'), same(HugeIcons.strokeRoundedNoodles));
    expect(categoryIcon('nasi'), same(HugeIcons.strokeRoundedRiceBowl02));
    expect(categoryIcon('cemilan'), same(HugeIcons.strokeRoundedCupcake01));
    expect(categoryIcon('cepat_saji'), same(HugeIcons.strokeRoundedFrenchFries01));
    expect(categoryIcon('unknown_category'), same(HugeIcons.strokeRoundedRestaurant));
  });
}
