# Mapo UI Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 8 Mapo screens from `mapo-screens.pdf` as reusable Flutter widgets and screens, built on top of the `List<ChatTurn>` state introduced in `docs/superpowers/plans/2026-07-25-perbaikan-arsitektur-mapo.md` (Tasks 1-5, already complete on this branch).

**Architecture:** Five of the eight screens (Home/Loading/Single/Options/Clarify) are render states of one `ChatScreen`, split into a thin provider-reading wrapper (`ChatScreen`) and a dumb, provider-free content widget (`ChatConversationBody`) so the debug preview gallery can feed it mock data without touching Riverpod. Riwayat and Profil follow the same wrapper/body split. Menu is a `Drawer`. All visual values come from `lib/themes/` (`AppColors`, `CategoryTone`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppText`) — no hardcoded colors or sizes anywhere in this plan.

**Tech Stack:** Flutter (Dart SDK ^3.12.2), flutter_riverpod ^3.3.2, hugeicons ^1.1.7, google_fonts ^8.2.0, cloud_firestore ^6.7.1, flutter_test.

## Global Constraints

- Full spec: `docs/superpowers/specs/2026-07-28-mapo-ui-screens-design.md`. Read it before questioning any decision below — the reasoning (especially the WCAG contrast math) lives there.
- Icons: `hugeicons` package only (`HugeIcons.strokeRounded*` constants + `HugeIcon` widget). Never `Icons.*` (Material) in new widgets.
- Accessibility rule A — **text/icon directly on a saturated `CategoryTone.base` fill** (this only happens inside `RecommendationCard`): wrap the text block in a flat scrim panel `Colors.black.withValues(alpha: 0.35)`. This exact value is derived in the spec from the worst-case category (brand/amber) hitting exactly 4.53:1 contrast with white text — do not lower it.
- Accessibility rule B — **category color as foreground on a light/white background** (`CategoryBadge`, `QuickReplyChip`, `MealHistoryTile`'s icon box): always `tone.fill` (background) + `tone.dark` (foreground). Never `tone.base` as a foreground color on a light background — it fails contrast in all four categories.
- Accessibility rule C — **`MapoHeader` title text**: `AppColors.ink`, never white, regardless of header color (`AppColors.brand` or `AppColors.green`). Verified 5-7:1 contrast either way. This is a deliberate deviation from the PDF mockup's white header text.
- Known accepted gap (do not attempt to fix in this plan): `tone.dark` text at caption/chip size (12-14px) on a white background is ~4.2:1 for green and ~3:1 for brand/amber — under the 4.5:1 AA-normal-text threshold. Fixing this requires darkening `AppColors.greenDark`/`brandDark`, which is a design-token change outside this plan's authority. Do not invent a per-category text-color special case to paper over it.
- Every icon-only interactive element gets `Semantics(label: ..., button: true)`. Tap target size follows the existing `AppSizes` tokens (e.g. `sendButton` = 42) where one applies; `MapoHeaderIconButton` and `RecommendationCard`'s retry button use an explicit 48×48 wrapper since no token covers that case. Both are comfortably above WCAG 2.5.8 AA's actual 24×24 minimum — don't invent a stricter blanket rule that fights the existing tokens.
- Tags/categories use `Wrap`, never `Row`, so they never overflow on narrow screens. Long text (`name`, `reason`) always has `maxLines` + `TextOverflow.ellipsis`.
- All screens that are "conversational" (Home/Loading/Single/Options/Clarify — i.e. `ChatScreen`) keep the field chat pinned at the bottom via `Column([Expanded(...), ChatInputBar()])`. Riwayat and Profil have no chat field.
- Language: casual Indonesian per the style guide ("Mangan opo?", "Pengen yang lain?", "Mapo lagi mikir..."). Never "Anda", never Title Case, no exclamation-mark spam.
- `flutter analyze` must stay clean (`No issues found!`) and all tests must pass before every commit — this repo is already at that baseline (19/19 tests passing at plan start).
- Commit after every task, Conventional Commits format (`feat:`, `test:`, `refactor:`, `docs:`).

---

### Task 1: `categoryIcon()` migration to HugeIcons + `CategoryBadge`

`lib/themes/app_colors.dart`'s `categoryIcon()` currently returns Material `IconData` (`Icons.ramen_dining` etc.). The style guide calls for a sharper icon set; the project already depends on `hugeicons` (not `tabler_icons`, which was never added — see spec §11). This task migrates `categoryIcon()` to return HugeIcons' `List<List<dynamic>>` icon data and adds the first reusable badge widget.

**Files:**
- Modify: `lib/themes/app_colors.dart` (`categoryIcon()` body + return type)
- Create: `lib/ui/widgets/category_badge.dart`
- Test: `test/themes/app_colors_test.dart`
- Test: `test/ui/widgets/category_badge_test.dart`

**Interfaces:**
- Consumes: `categoryTone(String category)` (already exists, unchanged)
- Produces: `List<List<dynamic>> categoryIcon(String category)` (return type changed from `IconData`), `CategoryBadge({required String category, required String label})`

- [ ] **Step 1: Write the failing test for `categoryIcon()`**

Create `test/themes/app_colors_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/themes/app_colors_test.dart`
Expected: FAIL — `categoryIcon('berkuah')` returns `Icons.ramen_dining` (an `IconData`), not `same(HugeIcons.strokeRoundedRiceBowl01)`, and the `categoryTone` test also fails to compile/pass until you confirm the enum values (this part should already pass — if `categoryTone` assertions fail, the existing function's switch doesn't match; fix only `categoryIcon`, leave `categoryTone` untouched, since Task 4/5 already depend on its current behavior).

- [ ] **Step 3: Migrate `categoryIcon()`**

In `lib/themes/app_colors.dart`, add the import at the top:

```dart
import 'package:hugeicons/hugeicons.dart';
```

Replace the entire `categoryIcon` function (currently returns `IconData`) with:

```dart
List<List<dynamic>> categoryIcon(String category) {
  switch (category) {
    case 'berkuah':
      return HugeIcons.strokeRoundedRiceBowl01;
    case 'pedas':
      return HugeIcons.strokeRoundedFire;
    case 'bakar':
      return HugeIcons.strokeRoundedBbqGrill;
    case 'goreng':
      return HugeIcons.strokeRoundedChickenThighs;
    case 'manis':
      return HugeIcons.strokeRoundedCakeSlice;
    case 'sehat':
      return HugeIcons.strokeRoundedSalad;
    case 'mie':
      return HugeIcons.strokeRoundedNoodles;
    case 'nasi':
      return HugeIcons.strokeRoundedRiceBowl02;
    case 'cemilan':
      return HugeIcons.strokeRoundedCupcake01;
    case 'cepat_saji':
      return HugeIcons.strokeRoundedFrenchFries01;
    default:
      return HugeIcons.strokeRoundedRestaurant;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/themes/app_colors_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Run full analyze — `categoryIcon` callers will now break**

Run: `flutter analyze 2>&1 | tail -20`
Expected: errors in `lib/ui/widgets/recommendation_card.dart` (the old Material-based card) — this file gets fully replaced in Task 3, so leave it broken for now; confirm no OTHER file references `categoryIcon`.

Run: `grep -rn "categoryIcon" lib/ --include="*.dart"`
Expected: only `lib/themes/app_colors.dart` (definition) and `lib/ui/widgets/recommendation_card.dart` (soon to be replaced).

- [ ] **Step 6: Write the failing test for `CategoryBadge`**

Create `test/ui/widgets/category_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/category_badge.dart';

void main() {
  testWidgets('menampilkan label kategori', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryBadge(category: 'pedas', label: 'pedas'),
        ),
      ),
    );

    expect(find.text('pedas'), findsOneWidget);
  });

  testWidgets('label dibawa lewat Semantics untuk pembaca layar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryBadge(category: 'sehat', label: 'sehat'),
        ),
      ),
    );

    expect(find.bySemanticsLabel('sehat'), findsOneWidget);
  });
}
```

- [ ] **Step 7: Run test to verify it fails**

Run: `flutter test test/ui/widgets/category_badge_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/category_badge.dart'`

- [ ] **Step 8: Create `CategoryBadge`**

Create `lib/ui/widgets/category_badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

/// Pill kecil warna kategori — ikon+label. Selalu `tone.fill` (latar) +
/// `tone.dark` (teks/ikon), sesuai Accessibility Rule B di plan: `tone.base`
/// sebagai foreground di atas latar terang gagal kontras di semua kategori.
class CategoryBadge extends StatelessWidget {
  final String category;
  final String label;

  const CategoryBadge({super.key, required this.category, required this.label});

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(category);
    return Semantics(
      label: label,
      child: Container(
        padding: AppSpacing.badgePad,
        decoration: BoxDecoration(color: tone.fill, borderRadius: AppRadius.rBadge),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: categoryIcon(category), color: tone.dark, size: AppSizes.iconSmall),
            const SizedBox(width: AppSpacing.xs / 2),
            Text(
              label,
              style: AppText.caption.copyWith(color: tone.dark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 9: Run test to verify it passes**

Run: `flutter test test/ui/widgets/category_badge_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 10: Commit**

```bash
git add lib/themes/app_colors.dart lib/ui/widgets/category_badge.dart test/themes/app_colors_test.dart test/ui/widgets/category_badge_test.dart
git commit -m "feat: migrasi categoryIcon ke HugeIcons, tambah CategoryBadge"
```

---

### Task 2: `GroundingBadge`

Renders `MapoResponse.contextUsed` as the "dipilih karena cuaca hujan" pill from the PDF. Sits on the plain page background (not inside a colored card), so it uses the `AppColors.blueFill`/`blueDark` pairing — same safe fill/dark pattern as `CategoryBadge`, just not tied to food category.

**Files:**
- Create: `lib/ui/widgets/grounding_badge.dart`
- Test: `test/ui/widgets/grounding_badge_test.dart`

**Interfaces:**
- Consumes: `ContextUsed` (`lib/models/mapo_response.dart`, already exists: `weather String?`, `timeOfDay String?`, `basedOnHistory bool`)
- Produces: `GroundingBadge({ContextUsed? contextUsed})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/grounding_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/ui/widgets/grounding_badge.dart';

void main() {
  testWidgets('tidak render apa pun kalau contextUsed null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GroundingBadge())),
    );

    expect(find.byType(GroundingBadge), findsOneWidget);
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('tidak render apa pun kalau semua field contextUsed kosong', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(contextUsed: ContextUsed()),
        ),
      ),
    );

    expect(find.byType(Container), findsNothing);
  });

  testWidgets('menampilkan cuaca kalau ada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(weather: 'hujan ringan'),
          ),
        ),
      ),
    );

    expect(find.textContaining('hujan ringan'), findsOneWidget);
  });

  testWidgets('menampilkan riwayat kalau basedOnHistory true dan cuaca kosong', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(basedOnHistory: true),
          ),
        ),
      ),
    );

    expect(find.textContaining('riwayat'), findsOneWidget);
  });

  testWidgets('menampilkan waktu tanpa underscore kalau cuma timeOfDay yang ada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroundingBadge(
            contextUsed: ContextUsed(timeOfDay: 'makan_siang'),
          ),
        ),
      ),
    );

    expect(find.textContaining('makan siang'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/grounding_badge_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/grounding_badge.dart'`

- [ ] **Step 3: Create `GroundingBadge`**

Create `lib/ui/widgets/grounding_badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/mapo_response.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class GroundingBadge extends StatelessWidget {
  final ContextUsed? contextUsed;

  const GroundingBadge({super.key, this.contextUsed});

  String? get _label {
    final ctx = contextUsed;
    if (ctx == null) return null;
    if (ctx.weather != null && ctx.weather!.isNotEmpty) {
      return 'dipilih karena cuaca ${ctx.weather}';
    }
    if (ctx.basedOnHistory) return 'dipilih berdasarkan riwayat kamu';
    if (ctx.timeOfDay != null && ctx.timeOfDay!.isNotEmpty) {
      return 'pas buat ${ctx.timeOfDay!.replaceAll('_', ' ')}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();

    return Semantics(
      label: label,
      child: Container(
        padding: AppSpacing.badgePad,
        decoration: BoxDecoration(
          color: AppColors.blueFill,
          borderRadius: AppRadius.rBadge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCloud,
              color: AppColors.blueDark,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSpacing.xs / 2),
            Flexible(
              child: Text(
                label,
                style: AppText.caption.copyWith(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/grounding_badge_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/ui/widgets/grounding_badge.dart test/ui/widgets/grounding_badge_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/grounding_badge.dart test/ui/widgets/grounding_badge_test.dart
git commit -m "feat: tambah GroundingBadge untuk context_used"
```

---

### Task 3: `RecommendationCard` — varian `hero`

The highest-priority component per the user's own ordering. This task **replaces** the existing `lib/ui/widgets/recommendation_card.dart` (currently a plain Material `Card` with emoji icons) with the on-brand version: category-color fill, icon in a translucent box, decorative circle, scrim-protected text (Accessibility Rule A), tag pills, "Makan ini" CTA + optional "lagi" retry button. Only the `hero` variant (used by the Single screen) in this task — `row` (Options) is Task 4.

**Files:**
- Modify: `lib/ui/widgets/recommendation_card.dart` (full rewrite)
- Test: `test/ui/widgets/recommendation_card_test.dart`

**Interfaces:**
- Consumes: `Recommendation` (`lib/models/mapo_response.dart`, already exists), `categoryTone`/`categoryIcon` (Task 1)
- Produces:
  - `enum RecommendationCardVariant { hero, row }`
  - `RecommendationCard({required Recommendation recommendation, RecommendationCardVariant variant = RecommendationCardVariant.hero, VoidCallback? onTap, VoidCallback? onPick, VoidCallback? onRetry})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/recommendation_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/ui/widgets/recommendation_card.dart';

const _rec = Recommendation(
  name: 'Soto Ayam',
  reason: 'Kuahnya anget pas buat cuaca hujan, ringan, dan masih di bawah budget kamu.',
  category: 'berkuah',
  priceEstimate: 13000,
  spiceLevel: 'sedang',
  prepTime: 'cepat',
  tags: ['hangat'],
);

void main() {
  testWidgets('hero menampilkan nama, alasan, dan tombol Makan ini', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: _rec)),
      ),
    );

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.textContaining('Kuahnya anget'), findsOneWidget);
    expect(find.text('Makan ini'), findsOneWidget);
  });

  testWidgets('hero menampilkan tag kategori, spice level, prep time, dan tag tambahan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: _rec)),
      ),
    );

    expect(find.text('berkuah'), findsOneWidget);
    expect(find.text('sedang'), findsOneWidget);
    expect(find.text('cepat'), findsOneWidget);
    expect(find.text('hangat'), findsOneWidget);
  });

  testWidgets('tombol lagi cuma muncul kalau onRetry diisi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: _rec)),
      ),
    );
    expect(find.bySemanticsLabel('Cari saran lain'), findsNothing);

    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(recommendation: _rec, onRetry: () => retried = true),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Cari saran lain'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Cari saran lain'));
    expect(retried, isTrue);
  });

  testWidgets('tap Makan ini memanggil onPick', (tester) async {
    var picked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(recommendation: _rec, onPick: () => picked = true),
        ),
      ),
    );

    await tester.tap(find.text('Makan ini'));
    expect(picked, isTrue);
  });

  testWidgets('tags kosong tidak merender Wrap kosong', (tester) async {
    const noTags = Recommendation(
      name: 'Nasi Putih',
      reason: 'Netral, cocok buat pendamping apa saja.',
      category: 'nasi',
      priceEstimate: 5000,
      spiceLevel: 'tidak_pedas',
      prepTime: 'cepat',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecommendationCard(recommendation: noTags)),
      ),
    );

    // spiceLevel 'tidak_pedas' sengaja tidak ditampilkan sebagai tag (lihat _tags).
    expect(find.text('tidak pedas'), findsNothing);
    expect(find.text('nasi'), findsOneWidget);
    expect(find.text('cepat'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/recommendation_card_test.dart`
Expected: FAIL — current `RecommendationCard` constructor doesn't accept `variant`/`onPick`/`onRetry`, and doesn't render a "Makan ini" button.

- [ ] **Step 3: Rewrite `RecommendationCard`**

Replace the entire content of `lib/ui/widgets/recommendation_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/mapo_response.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

enum RecommendationCardVariant { hero, row }

class RecommendationCard extends StatefulWidget {
  final Recommendation recommendation;
  final RecommendationCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onPick;
  final VoidCallback? onRetry;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.variant = RecommendationCardVariant.hero,
    this.onTap,
    this.onPick,
    this.onRetry,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(widget.recommendation.category);
    final isHero = widget.variant == RecommendationCardVariant.hero;

    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: tone.base,
        borderRadius: isHero ? AppRadius.rCardLarge : AppRadius.rCardSmall,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: isHero
              ? _HeroContent(
                  recommendation: widget.recommendation,
                  onPick: widget.onPick,
                  onRetry: widget.onRetry,
                )
              : _RowContent(recommendation: widget.recommendation),
        ),
      ),
    );

    // Hero adalah kartu "utama" — di layar tablet lebar penuh terasa kayak
    // banner, bukan pesan chat. Row (Options) sengaja tidak dibatasi, tetap
    // ikut lebar list seperti daftar pilihan biasa.
    if (!isHero) return card;
    return ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: card);
  }
}

/// Panel scrim rata di belakang teks — Accessibility Rule A. 0.35 dipilih
/// supaya kasus terburuk (brand/amber) masih lolos kontras AA 4.5:1 dengan
/// teks putih (lihat spec §4 untuk perhitungannya). Jangan diturunkan.
class _ScrimText extends StatelessWidget {
  final Widget child;

  const _ScrimText({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.iconBox),
      ),
      child: child,
    );
  }
}

List<String> _tags(Recommendation r) => [
      r.category,
      if (r.spiceLevel != 'tidak_pedas') r.spiceLevel.replaceAll('_', ' '),
      r.prepTime,
      ...r.tags,
    ];

class _HeroContent extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback? onPick;
  final VoidCallback? onRetry;

  const _HeroContent({required this.recommendation, this.onPick, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    final tags = _tags(r);

    return Padding(
      padding: AppSpacing.cardPadLarge,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: AppColors.overlayCircle, shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.iconBoxLarge,
                height: AppSizes.iconBoxLarge,
                decoration: BoxDecoration(color: AppColors.overlayIcon, borderRadius: AppRadius.rIconBox),
                child: Center(
                  child: HugeIcon(icon: categoryIcon(r.category), color: Colors.white, size: AppSizes.iconLarge),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ScrimText(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.name,
                      style: AppText.title.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      r.reason,
                      style: AppText.bodyLarge.copyWith(color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: tags
                            .map(
                              (t) => Container(
                                padding: AppSpacing.badgePad,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.rBadge,
                                ),
                                child: Text(t, style: AppText.caption.copyWith(color: Colors.white)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPick,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Makan ini'),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      label: 'Cari saran lain',
                      button: true,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: onRetry,
                          style: IconButton.styleFrom(backgroundColor: AppColors.overlayIcon),
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedRefresh,
                            color: Colors.white,
                            size: AppSizes.iconMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  final Recommendation recommendation;

  const _RowContent({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    return Padding(
      padding: AppSpacing.cardPadSmall,
      child: Row(
        children: [
          Container(
            width: AppSizes.iconBoxSmall,
            height: AppSizes.iconBoxSmall,
            decoration: BoxDecoration(color: AppColors.overlayIcon, borderRadius: AppRadius.rIconBox),
            child: Center(
              child: HugeIcon(icon: categoryIcon(r.category), color: Colors.white, size: AppSizes.iconMedium),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ScrimText(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.name,
                    style: AppText.section.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${r.category} · ${r.spiceLevel.replaceAll('_', ' ')}',
                    style: AppText.caption.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Rp${_formatPrice(r.priceEstimate)}',
            style: AppText.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(int price) => price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/recommendation_card_test.dart`
Expected: PASS (5 tests)

Note: Step 3's rewrite included `_RowContent` (the `row` variant) alongside `_HeroContent` in the same pass, since both variants share the `_ScrimText`/`_tags`/`_formatPrice` helpers and splitting them into two separate file edits would mean rewriting the same file twice. Steps 5-7 below lock down the `row` variant's behavior with its own tests (it has zero coverage so far — the tests above only exercise `hero`).

- [ ] **Step 5: Write tests for the `row` variant**

Append to `test/ui/widgets/recommendation_card_test.dart`, inside `void main() { ... }`, after the last test:

```dart
  testWidgets('row menampilkan nama, kategori, spice level, dan harga', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecommendationCard(
            recommendation: _rec,
            variant: RecommendationCardVariant.row,
          ),
        ),
      ),
    );

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.text('berkuah · sedang'), findsOneWidget);
    expect(find.text('Rp13.000'), findsOneWidget);
    expect(find.text('Makan ini'), findsNothing);
  });

  testWidgets('row tidak menampilkan tombol Makan ini walau onPick diisi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(
            recommendation: _rec,
            variant: RecommendationCardVariant.row,
            onPick: () {},
          ),
        ),
      ),
    );

    expect(find.text('Makan ini'), findsNothing);
  });

  testWidgets('row memanggil onTap saat kartu ditekan', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationCard(
            recommendation: _rec,
            variant: RecommendationCardVariant.row,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(RecommendationCard));
    expect(tapped, isTrue);
  });
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/ui/widgets/recommendation_card_test.dart`
Expected: PASS (8 tests). If `'row menampilkan nama, kategori, spice level, dan harga'` fails on the price string, double check `_formatPrice(13000)` — it must produce `13.000` (dot as thousands separator, no currency decimals), matching the existing formatter this replaces.

- [ ] **Step 7: Run analyze**

Run: `flutter analyze 2>&1 | tail -20`
Expected: `No issues found!` — this was the last file referencing the old `IconData`-based `categoryIcon`, so the migration from Task 1 Step 5 is now fully clean.

- [ ] **Step 8: Commit**

```bash
git add lib/ui/widgets/recommendation_card.dart test/ui/widgets/recommendation_card_test.dart
git commit -m "feat: redesign RecommendationCard (hero + row) — kartu warna kategori, scrim kontras, CTA Makan ini"
```

---

### Task 4: `ChatInputBar`

Second-priority component. Extracts and restyles the informal `_InputBar` currently inline in `lib/ui/chat_screen.dart` into a standalone, reusable widget with an `enabled` flag (redim + placeholder swap while Mapo is thinking, per the Loading screen spec).

**Files:**
- Create: `lib/ui/widgets/chat_input_bar.dart`
- Test: `test/ui/widgets/chat_input_bar_test.dart`

**Interfaces:**
- Consumes: nothing beyond Flutter/theme
- Produces: `ChatInputBar({required TextEditingController controller, required ValueChanged<String> onSend, bool enabled = true})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/chat_input_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/chat_input_bar.dart';

void main() {
  testWidgets('tap tombol kirim memanggil onSend dengan teks yang diketik', (tester) async {
    final controller = TextEditingController();
    String? sent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (t) => sent = t),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'laper');
    await tester.tap(find.bySemanticsLabel('Kirim pesan'));

    expect(sent, 'laper');
  });

  testWidgets('teks kosong tidak memanggil onSend', (tester) async {
    final controller = TextEditingController();
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (_) => called = true),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Kirim pesan'));
    expect(called, isFalse);
  });

  testWidgets('teks spasi-doang tidak memanggil onSend', (tester) async {
    final controller = TextEditingController();
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (_) => called = true),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.bySemanticsLabel('Kirim pesan'));
    expect(called, isFalse);
  });

  testWidgets('enabled false menonaktifkan field dan ganti hint', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (_) {}, enabled: false),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(find.text('Tunggu sebentar...'), findsOneWidget);
  });

  testWidgets('submit lewat keyboard action memanggil onSend', (tester) async {
    final controller = TextEditingController();
    String? sent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(controller: controller, onSend: (t) => sent = t),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'pengen yang pedas');
    await tester.testTextInput.receiveAction(TextInputAction.send);

    expect(sent, 'pengen yang pedas');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/chat_input_bar_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/chat_input_bar.dart'`

- [ ] **Step 3: Create `ChatInputBar`**

Create `lib/ui/widgets/chat_input_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool enabled;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  void _submit() {
    final text = controller.text;
    if (text.trim().isEmpty) return;
    onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.page,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: AppText.bodyLarge,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: enabled ? 'Lagi pengen apa?' : 'Tunggu sebentar...',
                fillColor: enabled ? null : AppColors.line,
              ),
              onSubmitted: enabled ? (_) => _submit() : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: 'Kirim pesan',
            button: true,
            child: SizedBox(
              width: AppSizes.sendButton,
              height: AppSizes.sendButton,
              child: Material(
                color: enabled ? AppColors.brand : AppColors.inkFaint,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? _submit : null,
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSent02,
                      color: Colors.white,
                      size: AppSizes.iconMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/chat_input_bar_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/ui/widgets/chat_input_bar.dart test/ui/widgets/chat_input_bar_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/chat_input_bar.dart test/ui/widgets/chat_input_bar_test.dart
git commit -m "feat: tambah ChatInputBar reusable dengan state disabled"
```

---

### Task 5: `QuickReplyChip`

Needed by the Clarify screen (Task 12). `follow_up.quick_replies` is freeform text from Gemini (e.g. "yang murah", "yang pedas", "yang cepet") — it is **not** one of the 10 fixed category enum values from `mapo_schema.dart`, so this widget cannot reuse `categoryTone(String category)`. It instead uses a small keyword heuristic scoped to this file only, purely for visual variety (matches the PDF's per-chip accent colors).

**Files:**
- Create: `lib/ui/widgets/quick_reply_chip.dart`
- Test: `test/ui/widgets/quick_reply_chip_test.dart`

**Interfaces:**
- Consumes: `CategoryTone` (`lib/themes/app_colors.dart`, already exists)
- Produces: `QuickReplyChip({required String label, required VoidCallback onTap, bool selected = false})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/quick_reply_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/quick_reply_chip.dart';

void main() {
  testWidgets('menampilkan label dan memanggil onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickReplyChip(label: 'yang pedas', onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('yang pedas'), findsOneWidget);
    await tester.tap(find.text('yang pedas'));
    expect(tapped, isTrue);
  });

  testWidgets('Semantics menandai selected saat state true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickReplyChip(label: 'yang murah', onTap: () {}, selected: true),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(QuickReplyChip));
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
  });

  testWidgets('Semantics tidak selected secara default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickReplyChip(label: 'yang cepet', onTap: () {}),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(QuickReplyChip));
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/quick_reply_chip_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/quick_reply_chip.dart'`

- [ ] **Step 3: Create `QuickReplyChip`**

Create `lib/ui/widgets/quick_reply_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class QuickReplyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const QuickReplyChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  /// Quick reply dari Gemini adalah teks bebas, bukan salah satu dari 10
  /// category enum di mapo_schema.dart — tone di sini cuma tebakan kata
  /// kunci untuk variasi visual, bukan pemetaan kategori yang tegas.
  CategoryTone get _tone {
    final lower = label.toLowerCase();
    if (lower.contains('pedas') || lower.contains('bakar')) return CategoryTone.red;
    if (lower.contains('sehat')) return CategoryTone.green;
    if (lower.contains('murah') || lower.contains('budget') || lower.contains('hemat')) {
      return CategoryTone.amber;
    }
    return CategoryTone.blue;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: AppSpacing.chipPad,
          decoration: BoxDecoration(
            color: selected ? tone.fill : Colors.transparent,
            border: Border.all(color: tone.dark, width: 1.5),
            borderRadius: AppRadius.rChip,
          ),
          child: Text(label, style: AppText.chip.copyWith(color: tone.dark)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/quick_reply_chip_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/ui/widgets/quick_reply_chip.dart test/ui/widgets/quick_reply_chip_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/quick_reply_chip.dart test/ui/widgets/quick_reply_chip_test.dart
git commit -m "feat: tambah QuickReplyChip untuk layar clarify"
```

---

### Task 6: `MapoHeader` + `MapoHeaderIconButton`

The pill-shaped, rounded-bottom header used by every screen (brand color by default, green for Riwayat per the spec). Title text is `AppColors.ink`, not white — Accessibility Rule C, a deliberate deviation from the PDF mockup (verified ~5-7:1 contrast either way, vs. ~2:1 with white).

**Files:**
- Create: `lib/ui/widgets/mapo_header.dart`
- Test: `test/ui/widgets/mapo_header_test.dart`

**Interfaces:**
- Consumes: nothing beyond Flutter/theme
- Produces:
  - `MapoHeader({required String title, String? subtitle, Color color = AppColors.brand, Widget? leading, List<Widget>? actions})` implementing `PreferredSizeWidget`
  - `MapoHeaderIconButton({required List<List<dynamic>> icon, required String label, required VoidCallback onTap})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/mapo_header_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mapo_app/themes/app_colors.dart';
import 'package:mapo_app/ui/widgets/mapo_header.dart';

void main() {
  testWidgets('menampilkan judul dan subjudul', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: MapoHeader(title: 'Mangan opo hari ini?', subtitle: 'Halo! Bingung mau makan apa?'),
        ),
      ),
    );

    expect(find.text('Mangan opo hari ini?'), findsOneWidget);
    expect(find.text('Halo! Bingung mau makan apa?'), findsOneWidget);
  });

  testWidgets('judul dipakai warna ink, bukan putih, di atas warna apa pun', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: MapoHeader(title: 'Riwayat makan', color: AppColors.green),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Riwayat makan'));
    expect(text.style?.color, AppColors.ink);
  });

  testWidgets('leading dan actions dirender kalau diisi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: MapoHeader(
            title: 'Cari makan',
            leading: MapoHeaderIconButton(
              icon: HugeIcons.strokeRoundedMenu01,
              label: 'Buka menu',
              onTap: () {},
            ),
            actions: [
              MapoHeaderIconButton(
                icon: HugeIcons.strokeRoundedUserCircle,
                label: 'Profil',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Buka menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Profil'), findsOneWidget);
  });

  testWidgets('MapoHeaderIconButton memanggil onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapoHeaderIconButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            label: 'Kembali',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Kembali'));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/mapo_header_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/mapo_header.dart'`

- [ ] **Step 3: Create `MapoHeader`**

Create `lib/ui/widgets/mapo_header.dart`:

```dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class MapoHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final Widget? leading;
  final List<Widget>? actions;

  const MapoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.color = AppColors.brand,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 108 : 132);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.cardLarge),
          bottomRight: Radius.circular(AppRadius.cardLarge),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.screenPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null || actions != null)
                Row(
                  children: [
                    if (leading != null) leading!,
                    const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              if (leading != null || actions != null) const SizedBox(height: AppSpacing.sm),
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: AppText.bodyMedium.copyWith(color: AppColors.ink.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 2),
              ],
              Text(title, style: AppText.display2.copyWith(color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon bulat putih di dalam header berwarna — dipakai untuk
/// back/hamburger/profil. Selalu 48x48 dan Semantics-labeled.
class MapoHeaderIconButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  const MapoHeaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: HugeIcon(icon: icon, color: AppColors.ink, size: AppSizes.iconMedium),
            ),
          ),
        ),
      ),
    );
  }
}
```

Add the missing import at the top for `HugeIcon`:

```dart
import 'package:hugeicons/hugeicons.dart';
```

(insert it alongside the other imports at the top of the file, before `app_colors.dart`)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/mapo_header_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/ui/widgets/mapo_header.dart test/ui/widgets/mapo_header_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/mapo_header.dart test/ui/widgets/mapo_header_test.dart
git commit -m "feat: tambah MapoHeader dan MapoHeaderIconButton"
```

---

### Task 7: `PendingChecklist`

The Loading screen's staged checklist ("Ngecek cuaca..." → "Ngecek riwayat makan..." → "Menyusun saran..."). Per spec §5/§6 this is a **timed simulation**, not real progress — `MapoRecommender._contextBlock` has no way to report sub-progress across its `Future.wait`. `stepDuration` is exposed as a constructor param specifically so tests don't need real wall-clock delays.

**Files:**
- Create: `lib/ui/widgets/pending_checklist.dart`
- Test: `test/ui/widgets/pending_checklist_test.dart`

**Interfaces:**
- Consumes: nothing beyond Flutter/theme
- Produces: `PendingChecklist({Duration stepDuration = const Duration(milliseconds: 600)})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/pending_checklist_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/pending_checklist.dart';

void main() {
  testWidgets('menampilkan Mapo lagi mikir dan step pertama di awal', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PendingChecklist(stepDuration: Duration(milliseconds: 50)),
        ),
      ),
    );

    expect(find.text('Mapo lagi mikir...'), findsOneWidget);
    expect(find.text('Ngecek cuaca...'), findsOneWidget);

    // Bereskan timer yang masih jalan sebelum widget tree di-dispose.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('step berikutnya muncul bertahap seiring waktu', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PendingChecklist(stepDuration: Duration(milliseconds: 50)),
        ),
      ),
    );

    expect(find.text('Ngecek riwayat makan...'), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Ngecek riwayat makan...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Menyusun saran...'), findsOneWidget);

    // Tidak ada step ke-4 — timer berhenti sendiri di step terakhir.
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Menyusun saran...'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/pending_checklist_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/pending_checklist.dart'`

- [ ] **Step 3: Create `PendingChecklist`**

Create `lib/ui/widgets/pending_checklist.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class PendingChecklist extends StatefulWidget {
  final Duration stepDuration;

  const PendingChecklist({super.key, this.stepDuration = const Duration(milliseconds: 600)});

  @override
  State<PendingChecklist> createState() => _PendingChecklistState();
}

class _PendingChecklistState extends State<PendingChecklist> {
  static const _steps = ['Ngecek cuaca...', 'Ngecek riwayat makan...', 'Menyusun saran...'];

  int _stage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.stepDuration, (timer) {
      if (_stage >= _steps.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _stage++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSquareLock01,
              color: AppColors.brandDark,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('Mapo lagi mikir...', style: AppText.section),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < _steps.length; i++)
          AnimatedOpacity(
            opacity: i <= _stage ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  HugeIcon(
                    icon: i < _stage
                        ? HugeIcons.strokeRoundedCheckmarkCircle01
                        : HugeIcons.strokeRoundedClock01,
                    color: i < _stage ? AppColors.green : AppColors.inkFaint,
                    size: AppSizes.iconSmall,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_steps[i], style: AppText.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/pending_checklist_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/ui/widgets/pending_checklist.dart test/ui/widgets/pending_checklist_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/pending_checklist.dart test/ui/widgets/pending_checklist_test.dart
git commit -m "feat: tambah PendingChecklist untuk layar loading"
```

---

### Task 8: `MapoDrawer`

The hamburger menu, built ahead of `ChatScreen`'s redesign (Task 9) since `ChatScreen` needs it as its `Scaffold.drawer`. `mealCount` is nullable: the real count comes from `mealHistoryEntriesProvider`, which doesn't exist until Task 13 — Task 16 wires the real value in once it does. Favorit/Pengaturan have no screen in this plan (not part of the 8 PDF screens), so they render disabled with a "segera hadir" label rather than silently doing nothing.

**Files:**
- Create: `lib/ui/widgets/mapo_drawer.dart`
- Test: `test/ui/widgets/mapo_drawer_test.dart`

**Interfaces:**
- Consumes: nothing beyond Flutter/theme
- Produces:
  - `enum MapoDrawerItem { cariMakan, riwayat, favorit, pengaturan }`
  - `MapoDrawer({required String userName, int? mealCount, required ValueChanged<MapoDrawerItem> onNavigate})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/mapo_drawer_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/widgets/mapo_drawer.dart';

void main() {
  testWidgets('menampilkan nama dan jumlah makan kalau ada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', mealCount: 12, onNavigate: (_) {}),
        ),
      ),
    );
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Ammar'), findsOneWidget);
    expect(find.textContaining('12 kali'), findsOneWidget);
  });

  testWidgets('subjudul generik kalau mealCount null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', onNavigate: (_) {}),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.textContaining('kali'), findsNothing);
  });

  testWidgets('tap Cari makan memanggil onNavigate dengan item yang benar', (tester) async {
    MapoDrawerItem? navigated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', mealCount: 3, onNavigate: (i) => navigated = i),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cari makan'));
    expect(navigated, MapoDrawerItem.cariMakan);
  });

  testWidgets('Favorit dan Pengaturan disabled dan berlabel segera hadir', (tester) async {
    MapoDrawerItem? navigated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: MapoDrawer(userName: 'Ammar', mealCount: 3, onNavigate: (i) => navigated = i),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.textContaining('Favorit (segera hadir)'), findsOneWidget);
    await tester.tap(find.textContaining('Favorit'));
    expect(navigated, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/mapo_drawer_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/mapo_drawer.dart'`

- [ ] **Step 3: Create `MapoDrawer`**

Create `lib/ui/widgets/mapo_drawer.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

enum MapoDrawerItem { cariMakan, riwayat, favorit, pengaturan }

class MapoDrawer extends StatelessWidget {
  final String userName;
  final int? mealCount;
  final ValueChanged<MapoDrawerItem> onNavigate;

  const MapoDrawer({
    super.key,
    required this.userName,
    this.mealCount,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.paper,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: AppSpacing.screenPad,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(AppRadius.cardLarge)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: AppSizes.iconBoxSmall / 2,
                    backgroundColor: Colors.white,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserCircle,
                      color: AppColors.brand,
                      size: AppSizes.iconLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(userName, style: AppText.title.copyWith(color: AppColors.ink)),
                  Text(
                    mealCount == null
                        ? 'Ayo mulai cerita ke Mapo'
                        : 'Sudah $mealCount kali makan bareng Mapo',
                    style: AppText.bodyMedium.copyWith(color: AppColors.ink.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DrawerTile(
              icon: HugeIcons.strokeRoundedSearchArea,
              label: 'Cari makan',
              onTap: () => onNavigate(MapoDrawerItem.cariMakan),
            ),
            _DrawerTile(
              icon: HugeIcons.strokeRoundedClock01,
              label: 'Riwayat makan',
              onTap: () => onNavigate(MapoDrawerItem.riwayat),
            ),
            const _DrawerTile(icon: HugeIcons.strokeRoundedFavourite, label: 'Favorit'),
            const _DrawerTile(icon: HugeIcons.strokeRoundedSettings01, label: 'Pengaturan'),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;

  const _DrawerTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: enabled ? AppColors.ink : AppColors.inkFaint,
        size: AppSizes.iconMedium,
      ),
      title: Text(
        enabled ? label : '$label (segera hadir)',
        style: AppText.bodyLarge.copyWith(color: enabled ? AppColors.ink : AppColors.inkFaint),
      ),
      enabled: enabled,
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/mapo_drawer_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/ui/widgets/mapo_drawer.dart test/ui/widgets/mapo_drawer_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/mapo_drawer.dart test/ui/widgets/mapo_drawer_test.dart
git commit -m "feat: tambah MapoDrawer"
```

---

**Note on task order from here on:** Tasks 9-12 build Riwayat and Profil (data layer → widget → screens) *before* Task 13 redesigns `ChatScreen`. This is a dependency-order swap, not a priority change — the user's priority (`RecommendationCard` → `ChatInputBar` → Single → Clarify → the rest) is about which *components* matter most and is fully honored (Tasks 3-4 built those first). But `ChatScreen`'s drawer needs to navigate to a real `RiwayatScreen`/`ProfilScreen` — building `ChatScreen`'s navigation before those screens exist would mean wiring dead-end callbacks now and coming back to patch them later, which the plan's no-placeholder rule forbids. Building Riwayat/Profil first means `ChatScreen`'s navigation is real and complete the first time.

### Task 9: `MealHistoryEntry` model + `MealHistoryStats` + `MealHistoryService.getMealHistory()`

`MealHistoryService.getRecentMeals()` (used by `MapoRecommender`, untouched) only returns `List<String>` — names only. Riwayat needs category, time, and (eventually) price per entry. Firestore already stores `name`/`category`/`eaten_at` (not price — that's Task 6 of the architecture plan, still out of scope); this task adds a **read-only** query method alongside the existing one, without touching the write path.

**Files:**
- Create: `lib/models/meal_history_entry.dart`
- Modify: `lib/data/meal_history_service.dart` (add `getMealHistory`, do not change `getRecentMeals`/`getPreferences`/`saveMeal`)
- Modify: `lib/providers/mapo_providers.dart` (add `mealHistoryEntriesProvider`)
- Test: `test/models/meal_history_entry_test.dart`

**Interfaces:**
- Consumes: `currentUserIdProvider`, `mealHistoryProvider` (both already exist)
- Produces:
  - `class MealHistoryEntry { name, category, eatenAt, price }` with `factory MealHistoryEntry.fromDoc(Map<String, dynamic>)`
  - `class MealHistoryStats { countThisWeek, mostCommonCategory }` with `factory MealHistoryStats.fromEntries(List<MealHistoryEntry>)`
  - `MealHistoryService.getMealHistory(String userId, {int limit = 20}) → Future<List<MealHistoryEntry>>`
  - `final mealHistoryEntriesProvider = FutureProvider<List<MealHistoryEntry>>`

- [ ] **Step 1: Write the failing tests**

Create `test/models/meal_history_entry_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/meal_history_entry.dart';

void main() {
  group('MealHistoryEntry.fromDoc', () {
    test('parsing lengkap dengan harga', () {
      final entry = MealHistoryEntry.fromDoc({
        'name': 'Soto Ayam',
        'category': 'berkuah',
        'eaten_at': Timestamp.fromDate(DateTime(2026, 7, 28, 13, 20)),
        'price': 13000,
      });

      expect(entry.name, 'Soto Ayam');
      expect(entry.category, 'berkuah');
      expect(entry.eatenAt, DateTime(2026, 7, 28, 13, 20));
      expect(entry.price, 13000);
    });

    test('tanpa harga (belum tersimpan sampai Task 6 arsitektur)', () {
      final entry = MealHistoryEntry.fromDoc({
        'name': 'Ayam Bakar',
        'category': 'bakar',
        'eaten_at': Timestamp.fromDate(DateTime(2026, 7, 27, 19, 5)),
      });

      expect(entry.price, isNull);
    });

    test('field hilang tidak throw', () {
      final entry = MealHistoryEntry.fromDoc({
        'eaten_at': Timestamp.fromDate(DateTime(2026, 7, 27, 19, 5)),
      });

      expect(entry.name, '');
      expect(entry.category, 'nasi');
    });
  });

  group('MealHistoryStats.fromEntries', () {
    test('daftar kosong menghasilkan stats kosong', () {
      final stats = MealHistoryStats.fromEntries([]);

      expect(stats.countThisWeek, 0);
      expect(stats.mostCommonCategory, isNull);
    });

    test('menghitung entri minggu ini dan kategori paling sering', () {
      final now = DateTime.now();
      final entries = [
        MealHistoryEntry(name: 'Soto Ayam', category: 'berkuah', eatenAt: now),
        MealHistoryEntry(
          name: 'Bakso',
          category: 'berkuah',
          eatenAt: now.subtract(const Duration(days: 1)),
        ),
        MealHistoryEntry(
          name: 'Ayam Bakar',
          category: 'bakar',
          eatenAt: now.subtract(const Duration(days: 2)),
        ),
        MealHistoryEntry(
          name: 'Menu Lama',
          category: 'nasi',
          eatenAt: now.subtract(const Duration(days: 30)),
        ),
      ];

      final stats = MealHistoryStats.fromEntries(entries);

      expect(stats.countThisWeek, 3);
      expect(stats.mostCommonCategory, 'berkuah');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/meal_history_entry_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/models/meal_history_entry.dart'`

- [ ] **Step 3: Create `MealHistoryEntry` and `MealHistoryStats`**

Create `lib/models/meal_history_entry.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MealHistoryEntry {
  final String name;
  final String category;
  final DateTime eatenAt;
  final int? price;

  const MealHistoryEntry({
    required this.name,
    required this.category,
    required this.eatenAt,
    this.price,
  });

  factory MealHistoryEntry.fromDoc(Map<String, dynamic> data) => MealHistoryEntry(
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? 'nasi',
        eatenAt: (data['eaten_at'] as Timestamp).toDate(),
        price: (data['price'] as num?)?.toInt(),
      );
}

class MealHistoryStats {
  final int countThisWeek;
  final String? mostCommonCategory;

  const MealHistoryStats({required this.countThisWeek, this.mostCommonCategory});

  factory MealHistoryStats.fromEntries(List<MealHistoryEntry> entries) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = entries.where((e) => e.eatenAt.isAfter(weekAgo)).toList();

    if (thisWeek.isEmpty) {
      return const MealHistoryStats(countThisWeek: 0, mostCommonCategory: null);
    }

    final counts = <String, int>{};
    for (final e in thisWeek) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final mostCommon = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return MealHistoryStats(countThisWeek: thisWeek.length, mostCommonCategory: mostCommon);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/meal_history_entry_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Add `getMealHistory` to `MealHistoryService`**

In `lib/data/meal_history_service.dart`, add the import at the top:

```dart
import '../models/meal_history_entry.dart';
```

Add this method to the `MealHistoryService` class, after `getRecentMeals` (do not modify `getRecentMeals`, `getPreferences`, or `saveMeal`):

```dart
  /// Read-only, dipakai layar Riwayat. Berbeda dari getRecentMeals (yang
  /// dipakai MapoRecommender dan cuma butuh nama) — ini butuh kategori,
  /// waktu, dan harga per entri.
  Future<List<MealHistoryEntry>> getMealHistory(String userId, {int limit = 20}) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('meal_history')
        .orderBy('eaten_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => MealHistoryEntry.fromDoc(d.data())).toList();
  }
```

- [ ] **Step 6: Add `mealHistoryEntriesProvider`**

In `lib/providers/mapo_providers.dart`, add the import:

```dart
import '../models/meal_history_entry.dart';
```

Add this provider anywhere after `mealHistoryProvider` and `currentUserIdProvider` are both declared:

```dart
final mealHistoryEntriesProvider = FutureProvider<List<MealHistoryEntry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(mealHistoryProvider).getMealHistory(userId);
});
```

- [ ] **Step 7: Run full test suite and analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS (existing 19 + 5 new = 24), `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/models/meal_history_entry.dart lib/data/meal_history_service.dart lib/providers/mapo_providers.dart test/models/meal_history_entry_test.dart
git commit -m "feat: tambah MealHistoryEntry, MealHistoryStats, dan getMealHistory read-only"
```

---

### Task 10: `MealHistoryTile`

Riwayat's list row. Unlike `RecommendationCard`, this sits on the plain white/page background (per the PDF mockup — a small colored icon square next to ink-colored text, not a fully-colored card), so it uses Accessibility Rule B (`tone.fill`/`tone.dark`) throughout and has no contrast concerns to solve.

**Files:**
- Create: `lib/ui/widgets/meal_history_tile.dart`
- Test: `test/ui/widgets/meal_history_tile_test.dart`

**Interfaces:**
- Consumes: `MealHistoryEntry` (Task 9), `categoryTone`/`categoryIcon` (Task 1)
- Produces: `MealHistoryTile({required MealHistoryEntry entry})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/widgets/meal_history_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/meal_history_entry.dart';
import 'package:mapo_app/ui/widgets/meal_history_tile.dart';

void main() {
  testWidgets('menampilkan nama, kategori, waktu, dan harga', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealHistoryTile(
            entry: MealHistoryEntry(
              name: 'Soto Ayam',
              category: 'berkuah',
              eatenAt: DateTime(2026, 7, 28, 13, 20),
              price: 13000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.textContaining('berkuah'), findsOneWidget);
    expect(find.textContaining('13:20'), findsOneWidget);
    expect(find.text('Rp13.000'), findsOneWidget);
  });

  testWidgets('harga null menampilkan pesan, bukan Rp0 atau crash', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealHistoryTile(
            entry: MealHistoryEntry(
              name: 'Ayam Bakar',
              category: 'bakar',
              eatenAt: DateTime(2026, 7, 27, 19, 5),
            ),
          ),
        ),
      ),
    );

    expect(find.text('harga belum tercatat'), findsOneWidget);
    expect(find.textContaining('Rp'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/widgets/meal_history_tile_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/widgets/meal_history_tile.dart'`

- [ ] **Step 3: Create `MealHistoryTile`**

Create `lib/ui/widgets/meal_history_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/meal_history_entry.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';

class MealHistoryTile extends StatelessWidget {
  final MealHistoryEntry entry;

  const MealHistoryTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final tone = categoryTone(entry.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSizes.listAvatar,
            height: AppSizes.listAvatar,
            decoration: BoxDecoration(color: tone.fill, borderRadius: AppRadius.rIconBox),
            child: Center(
              child: HugeIcon(icon: categoryIcon(entry.category), color: tone.dark, size: AppSizes.iconMedium),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${entry.category} · ${_formatTime(entry.eatenAt)}', style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            entry.price == null ? 'harga belum tercatat' : 'Rp${_formatPrice(entry.price!)}',
            style: entry.price == null
                ? AppText.caption.copyWith(fontStyle: FontStyle.italic)
                : AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatPrice(int price) => price.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]}.',
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/widgets/meal_history_tile_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Run analyze**

Run: `flutter analyze lib/ui/widgets/meal_history_tile.dart test/ui/widgets/meal_history_tile_test.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/meal_history_tile.dart test/ui/widgets/meal_history_tile_test.dart
git commit -m "feat: tambah MealHistoryTile untuk layar riwayat"
```

---

### Task 11: `RiwayatScreen`

Split into a thin `RiwayatScreen` (reads `mealHistoryEntriesProvider`) and a dumb `RiwayatBody` (pure props — this is what the debug gallery in Task 16 will render directly with mock data). No chat field — Riwayat is not a conversational screen.

**Files:**
- Create: `lib/ui/screens/riwayat_screen.dart`
- Test: `test/ui/screens/riwayat_screen_test.dart`

**Interfaces:**
- Consumes: `mealHistoryEntriesProvider` (Task 9), `MealHistoryEntry`/`MealHistoryStats` (Task 9), `MealHistoryTile` (Task 10), `MapoHeader`/`MapoHeaderIconButton` (Task 6)
- Produces: `RiwayatScreen` (`ConsumerWidget`, no constructor params), `RiwayatBody({required List<MealHistoryEntry> entries})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/screens/riwayat_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/meal_history_entry.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/riwayat_screen.dart';

void main() {
  group('RiwayatBody', () {
    testWidgets('daftar kosong menampilkan pesan ramah', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RiwayatBody(entries: []))),
      );

      expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
    });

    testWidgets('mengelompokkan entri per hari dan menampilkan statistik', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiwayatBody(
              entries: [
                MealHistoryEntry(name: 'Soto Ayam', category: 'berkuah', eatenAt: now, price: 13000),
                MealHistoryEntry(
                  name: 'Ayam Bakar',
                  category: 'bakar',
                  eatenAt: now.subtract(const Duration(days: 1)),
                  price: 20000,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('HARI INI'), findsOneWidget);
      expect(find.text('KEMARIN'), findsOneWidget);
      expect(find.text('Soto Ayam'), findsOneWidget);
      expect(find.text('Ayam Bakar'), findsOneWidget);
      expect(find.textContaining('berkuah'), findsWidgets);
    });
  });

  group('RiwayatScreen', () {
    testWidgets('data dari provider dirender lewat RiwayatBody', (tester) async {
      final entry = MealHistoryEntry(
        name: 'Bakso',
        category: 'berkuah',
        eatenAt: DateTime.now(),
        price: 15000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [mealHistoryEntriesProvider.overrideWith((ref) async => [entry])],
          child: const MaterialApp(home: RiwayatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bakso'), findsOneWidget);
      expect(find.text('Riwayat makan'), findsOneWidget);
    });

    testWidgets('error dari provider menampilkan pesan ramah', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealHistoryEntriesProvider.overrideWith((ref) async => throw Exception('boom')),
          ],
          child: const MaterialApp(home: RiwayatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Mapo lagi bingung'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/screens/riwayat_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/screens/riwayat_screen.dart'`

- [ ] **Step 3: Create `RiwayatScreen`**

Create directory `lib/ui/screens/` and the file `lib/ui/screens/riwayat_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/meal_history_entry.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/mapo_header.dart';
import '../widgets/meal_history_tile.dart';

class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(mealHistoryEntriesProvider);

    return Scaffold(
      appBar: MapoHeader(
        title: 'Riwayat makan',
        subtitle: 'Mapo pakai ini biar gak nyaranin yang sama',
        color: AppColors.green,
        leading: MapoHeaderIconButton(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          label: 'Kembali',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPad,
            child: Text('Mapo lagi bingung, coba lagi ya', style: AppText.bodyLarge),
          ),
        ),
        data: (entries) => RiwayatBody(entries: entries),
      ),
    );
  }
}

class RiwayatBody extends StatelessWidget {
  final List<MealHistoryEntry> entries;

  const RiwayatBody({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.screenPad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Belum ada riwayat.', style: AppText.section, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mulai cerita ke Mapo yuk, biar riwayat makanmu kecatat di sini.',
                style: AppText.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final stats = MealHistoryStats.fromEntries(entries);
    final grouped = _groupByDay(entries);

    return ListView(
      padding: AppSpacing.screenPad,
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(value: '${stats.countThisWeek}', label: 'makan minggu ini')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(value: stats.mostCommonCategory ?? '—', label: 'paling sering'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final group in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(group.key, style: AppText.caption.copyWith(letterSpacing: 1)),
          ),
          for (final entry in group.value) MealHistoryTile(entry: entry),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Map<String, List<MealHistoryEntry>> _groupByDay(List<MealHistoryEntry> entries) {
    final grouped = <String, List<MealHistoryEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(_dayLabel(e.eatenAt), () => []).add(e);
    }
    return grouped;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadSmall,
      decoration: BoxDecoration(color: AppColors.brandFill, borderRadius: AppRadius.rCardSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppText.title.copyWith(color: AppColors.brandDark)),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/screens/riwayat_screen_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Run full test suite and analyze**

Run: `flutter test && flutter analyze`
Expected: all PASS, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/screens/riwayat_screen.dart test/ui/screens/riwayat_screen_test.dart
git commit -m "feat: tambah layar Riwayat"
```

---

### Task 12: `prefsProvider`, `currentUserDisplayProvider`, `ProfilScreen`

Profil needs read-only access to `UserPrefs` (already fully modeled — `getPreferences` already exists in `MealHistoryService`, this just adds a provider) and to the current user's display name / anonymous flag. That second part gets its own tiny provider — `currentUserIdProvider` already set the precedent of wrapping raw `FirebaseAuth.instance` access in a provider specifically so tests don't need a real Firebase app; `currentUserDisplayProvider` does the same for the two fields `ProfilScreen` needs. Google Sign-In itself is a UI stub only (confirmed out of scope) — the "Masuk" button shows a snackbar, it does not call `linkWithCredential` or add the `google_sign_in` package.

**Files:**
- Modify: `lib/providers/mapo_providers.dart` (add `prefsProvider`, `currentUserDisplayProvider`)
- Create: `lib/ui/screens/profil_screen.dart`
- Test: `test/ui/screens/profil_screen_test.dart`

**Interfaces:**
- Consumes: `currentUserIdProvider`, `mealHistoryProvider`, `firebaseAuthProvider` (all already exist), `UserPrefs` (`lib/models/user_prefs.dart`, already exists: `budgetRange`, `restrictions`)
- Produces:
  - `final prefsProvider = FutureProvider<UserPrefs>`
  - `final currentUserDisplayProvider = Provider<({String displayName, bool isAnonymous})>`
  - `ProfilScreen` (`ConsumerWidget`, no constructor params)
  - `ProfilBody({required String displayName, required bool isAnonymous, required UserPrefs prefs, required VoidCallback onGoogleSignInTap})`

- [ ] **Step 1: Add the two providers**

In `lib/providers/mapo_providers.dart`, add the import:

```dart
import '../models/user_prefs.dart';
```

Add these two providers anywhere after `currentUserIdProvider` and `mealHistoryProvider` are declared:

```dart
final prefsProvider = FutureProvider<UserPrefs>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const UserPrefs();
  return ref.watch(mealHistoryProvider).getPreferences(userId);
});

/// Seam yang sama seperti currentUserIdProvider: widget tak pernah menyentuh
/// FirebaseAuth.instance langsung, jadi test bisa override tanpa Firebase asli.
final currentUserDisplayProvider = Provider<({String displayName, bool isAnonymous})>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  return (displayName: user?.displayName ?? 'Kamu', isAnonymous: user?.isAnonymous ?? true);
});
```

- [ ] **Step 2: Write the failing tests**

Create `test/ui/screens/profil_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/user_prefs.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/profil_screen.dart';

void main() {
  group('ProfilBody', () {
    testWidgets('anonim menampilkan banner simpan histori', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(budgetRange: '15.000-25.000', restrictions: []),
              onGoogleSignInTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ammar'), findsOneWidget);
      expect(find.textContaining('Anonim'), findsOneWidget);
      expect(find.text('Simpan histori kamu'), findsOneWidget);
      expect(find.text('tidak ada'), findsOneWidget);
      expect(find.text('15.000-25.000'), findsOneWidget);
    });

    testWidgets('bukan anonim menyembunyikan banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: false,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Simpan histori kamu'), findsNothing);
    });

    testWidgets('pantangan yang terisi ditampilkan gabungan koma', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(restrictions: ['halal', 'tidak pedas']),
              onGoogleSignInTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('halal, tidak pedas'), findsOneWidget);
    });

    testWidgets('tap Masuk memanggil onGoogleSignInTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilBody(
              displayName: 'Ammar',
              isAnonymous: true,
              prefs: const UserPrefs(),
              onGoogleSignInTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Masuk'));
      expect(tapped, isTrue);
    });
  });

  group('ProfilScreen', () {
    testWidgets('prefs dari provider dirender lewat ProfilBody', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith(
              (ref) async => const UserPrefs(budgetRange: '> 50.000', restrictions: ['halal']),
            ),
            currentUserDisplayProvider.overrideWithValue(
              (displayName: 'Ammar', isAnonymous: true),
            ),
          ],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ammar'), findsOneWidget);
      expect(find.text('> 50.000'), findsOneWidget);
      expect(find.text('halal'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/ui/screens/profil_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/screens/profil_screen.dart'`

- [ ] **Step 4: Create `ProfilScreen`**

Create `lib/ui/screens/profil_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/user_prefs.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/mapo_header.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(prefsProvider);
    final userDisplay = ref.watch(currentUserDisplayProvider);

    return Scaffold(
      appBar: MapoHeader(
        title: 'Profil',
        leading: MapoHeaderIconButton(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          label: 'Kembali',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPad,
            child: Text('Mapo lagi bingung, coba lagi ya', style: AppText.bodyLarge),
          ),
        ),
        data: (prefs) => ProfilBody(
          displayName: userDisplay.displayName,
          isAnonymous: userDisplay.isAnonymous,
          prefs: prefs,
          onGoogleSignInTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Masuk Google belum tersambung — segera hadir')),
            );
          },
        ),
      ),
    );
  }
}

class ProfilBody extends StatelessWidget {
  final String displayName;
  final bool isAnonymous;
  final UserPrefs prefs;
  final VoidCallback onGoogleSignInTap;

  const ProfilBody({
    super.key,
    required this.displayName,
    required this.isAnonymous,
    required this.prefs,
    required this.onGoogleSignInTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPad,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: AppSizes.iconBoxLarge,
                height: AppSizes.iconBoxLarge,
                decoration: const BoxDecoration(color: AppColors.brandFill, shape: BoxShape.circle),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUserCircle,
                    color: AppColors.brand,
                    size: AppSizes.iconLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(displayName, style: AppText.title),
              Text(
                isAnonymous ? 'Anonim · belum tersimpan' : 'Tersimpan dengan Google',
                style: AppText.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isAnonymous)
          Container(
            padding: AppSpacing.cardPadSmall,
            decoration: BoxDecoration(color: AppColors.blueFill, borderRadius: AppRadius.rCardSmall),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Simpan histori kamu',
                        style: AppText.bodyLarge.copyWith(
                          color: AppColors.blueDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Masuk Google biar gak hilang',
                        style: AppText.caption.copyWith(color: AppColors.blueDark),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onGoogleSignInTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Masuk'),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text('PREFERENSI', style: AppText.caption.copyWith(letterSpacing: 1)),
        const SizedBox(height: AppSpacing.xs),
        _PrefRow(icon: HugeIcons.strokeRoundedWallet01, label: 'Budget biasa', value: prefs.budgetRange),
        _PrefRow(
          icon: HugeIcons.strokeRoundedFire,
          label: 'Pantangan',
          value: prefs.restrictions.isEmpty ? 'tidak ada' : prefs.restrictions.join(', '),
        ),
      ],
    );
  }
}

class _PrefRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;

  const _PrefRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: AppColors.inkSoft, size: AppSizes.iconMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppText.bodyLarge)),
          Text(value, style: AppText.bodyMedium.copyWith(color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/ui/screens/profil_screen_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 6: Run full test suite and analyze**

Run: `flutter test && flutter analyze`
Expected: all PASS, `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/providers/mapo_providers.dart lib/ui/screens/profil_screen.dart test/ui/screens/profil_screen_test.dart
git commit -m "feat: tambah layar Profil dan prefsProvider read-only"
```

---

### Task 13: `ChatScreen` redesign — Home, Loading, Single, Options, Clarify, error

The main event. Every widget this needs (`RecommendationCard` hero+row, `ChatInputBar`, `QuickReplyChip`, `GroundingBadge`, `PendingChecklist`, `MapoHeader`, `MapoDrawer`, `RiwayatScreen`, `ProfilScreen`) already exists from Tasks 1-12, so all five response-driven states are implemented in one pass rather than split further — `ResponseType`'s switch is one exhaustive block; splitting it across tasks would force a placeholder branch for the not-yet-done cases, which the no-placeholder rule forbids.

This **replaces** `lib/ui/chat_screen.dart` (the Task 4/5 architecture-plan version — functionally correct, visually plain Material) with `lib/ui/screens/chat_screen.dart`, split into a thin `ChatScreen` (provider wrapper) and a dumb `ChatConversationBody` (pure props — this is what Task 16's debug gallery renders directly with mock `List<ChatTurn>`, no `ProviderScope` needed).

**Files:**
- Create: `lib/ui/screens/chat_screen.dart`
- Delete: `lib/ui/chat_screen.dart`
- Modify: `lib/main.dart` (update the import path)
- Test: `test/ui/screens/chat_screen_test.dart`

**Interfaces:**
- Consumes: `chatProvider`, `coordsProvider`, `currentUserDisplayProvider`, `mealHistoryEntriesProvider` (all already exist), every widget listed above
- Produces:
  - `ChatScreen` (`ConsumerStatefulWidget`, no constructor params)
  - `ChatConversationBody({required List<ChatTurn> turns, required TextEditingController controller, required Future<void> Function(String) onSend, required ScrollController scrollController, bool inputEnabled = true, VoidCallback? onRetryLast, void Function(Recommendation)? onPick})`

- [ ] **Step 1: Write the failing tests**

Create `test/ui/screens/chat_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/providers/mapo_providers.dart';
import 'package:mapo_app/ui/screens/chat_screen.dart';
import 'package:mapo_app/ui/screens/riwayat_screen.dart';

MapoResponse _singleResponse({List<Recommendation>? recommendations}) => MapoResponse(
      responseType: ResponseType.single,
      message: 'Buat kamu yang lagi pengen anget',
      recommendations: recommendations ??
          const [
            Recommendation(
              name: 'Soto Ayam',
              reason: 'Kuahnya anget pas buat cuaca hujan.',
              category: 'berkuah',
              priceEstimate: 13000,
              spiceLevel: 'sedang',
              prepTime: 'cepat',
            ),
          ],
      contextUsed: const ContextUsed(weather: 'hujan ringan'),
    );

const _optionsResponse = MapoResponse(
  responseType: ResponseType.options,
  message: 'Ada 3 pilihan yang cocok buat cuaca hujan hari ini:',
  recommendations: [
    Recommendation(
      name: 'Soto Ayam',
      reason: 'anget',
      category: 'berkuah',
      priceEstimate: 13000,
      spiceLevel: 'sedang',
      prepTime: 'cepat',
    ),
    Recommendation(
      name: 'Bakso',
      reason: 'pedas',
      category: 'pedas',
      priceEstimate: 15000,
      spiceLevel: 'pedas',
      prepTime: 'cepat',
    ),
  ],
);

const _clarifyResponse = MapoResponse(
  responseType: ResponseType.clarify,
  message: 'Siap bantu!',
  followUp: FollowUp(
    question: 'Biar pas, kamu lagi pengen yang gimana nih?',
    quickReplies: ['yang murah', 'yang pedas', 'yang cepet', 'yang sehat'],
  ),
);

class _FixedChatNotifier extends ChatNotifier {
  final List<ChatTurn> initial;
  _FixedChatNotifier(this.initial);

  @override
  List<ChatTurn> build() => initial;
}

void main() {
  group('ChatConversationBody', () {
    testWidgets('turns kosong menampilkan Home dengan contoh pertanyaan tappable', (tester) async {
      String? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [],
              controller: TextEditingController(),
              onSend: (t) async => sent = t,
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('Cerita aja ke Mapo'), findsOneWidget);
      expect(find.text('lagi hujan, pengen anget'), findsOneWidget);

      await tester.tap(find.text('lagi hujan, pengen anget'));
      expect(sent, 'lagi hujan, pengen anget');
    });

    testWidgets('UserTurn dirender sebagai bubble', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('lagi hujan, pengen anget')],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('lagi hujan, pengen anget'), findsOneWidget);
    });

    testWidgets('PendingTurn menampilkan PendingChecklist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('laper'), PendingTurn()],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
              inputEnabled: false,
            ),
          ),
        ),
      );

      expect(find.text('Mapo lagi mikir...'), findsOneWidget);
      // Bereskan Timer PendingChecklist yang masih jalan sebelum test selesai.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('ErrorTurn menampilkan pesan dan tombol coba lagi', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('laper'), ErrorTurn('Mapo lagi bingung, coba lagi ya')],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
              onRetryLast: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Mapo lagi bingung, coba lagi ya'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(retried, isTrue);
    });

    testWidgets('MapoTurn single menampilkan RecommendationCard hero dan badge cuaca', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: [const UserTurn('laper'), MapoTurn(_singleResponse())],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('Soto Ayam'), findsOneWidget);
      expect(find.text('Makan ini'), findsOneWidget);
      expect(find.textContaining('hujan ringan'), findsOneWidget);
    });

    testWidgets('tap Makan ini memanggil onPick dengan rekomendasi yang benar', (tester) async {
      Recommendation? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: [const UserTurn('laper'), MapoTurn(_singleResponse())],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
              onPick: (r) => picked = r,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Makan ini'));
      expect(picked?.name, 'Soto Ayam');
    });

    testWidgets('MapoTurn single dengan recommendations kosong menampilkan notice', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: [
                const UserTurn('laper'),
                MapoTurn(_singleResponse(recommendations: const [])),
              ],
              controller: TextEditingController(),
              onSend: (_) async {},
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.textContaining('belum nemu saran'), findsOneWidget);
    });

    testWidgets('MapoTurn options menampilkan beberapa row dan tap mengirim pesan pilih', (tester) async {
      String? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('bingung'), MapoTurn(_optionsResponse)],
              controller: TextEditingController(),
              onSend: (t) async => sent = t,
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.text('Soto Ayam'), findsOneWidget);
      expect(find.text('Bakso'), findsOneWidget);

      await tester.tap(find.text('Bakso'));
      expect(sent, 'pilih Bakso');
    });

    testWidgets('MapoTurn clarify menampilkan pertanyaan dan quick reply', (tester) async {
      String? sent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversationBody(
              turns: const [UserTurn('aku laper'), MapoTurn(_clarifyResponse)],
              controller: TextEditingController(),
              onSend: (t) async => sent = t,
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

      expect(find.textContaining('gimana nih'), findsOneWidget);
      expect(find.text('yang murah'), findsOneWidget);

      await tester.tap(find.text('yang pedas'));
      expect(sent, 'yang pedas');
    });
  });

  group('ChatScreen', () {
    testWidgets('membuka drawer dan navigasi ke Riwayat', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatProvider.overrideWith(() => _FixedChatNotifier(const [])),
            coordsProvider.overrideWith((ref) async => null),
            currentUserDisplayProvider.overrideWithValue((displayName: 'Ammar', isAnonymous: true)),
            mealHistoryEntriesProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Buka menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Riwayat makan'));
      await tester.pumpAndSettle();

      expect(find.byType(RiwayatScreen), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/screens/chat_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/screens/chat_screen.dart'`

- [ ] **Step 3: Create the new `ChatScreen`**

Create `lib/ui/screens/chat_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/chat_turn.dart';
import '../../models/mapo_response.dart';
import '../../providers/mapo_providers.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_text_styles.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/grounding_badge.dart';
import '../widgets/mapo_drawer.dart';
import '../widgets/mapo_header.dart';
import '../widgets/pending_checklist.dart';
import '../widgets/quick_reply_chip.dart';
import '../widgets/recommendation_card.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final coords = await ref.read(coordsProvider.future);
    if (!mounted) return;

    await ref.read(chatProvider.notifier).ask(text, lat: coords?.lat, lng: coords?.lng);

    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _retryLast(List<ChatTurn> turns) {
    for (final turn in turns.reversed) {
      if (turn is UserTurn) {
        _send(turn.text);
        return;
      }
    }
  }

  /// "Makan ini" belum tersambung ke Firestore — itu Task 6 dari plan
  /// arsitektur, di luar scope plan ini. Tanpa handler ini sama sekali,
  /// RecommendationCard's onPick jadi null dan tombol "Makan ini" — CTA
  /// utama menurut style guide — akan tampil disabled/abu-abu. SnackBar
  /// ini kasih umpan balik nyata tanpa berpura-pura sudah tersimpan permanen.
  void _pickMeal(BuildContext context, Recommendation recommendation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Oke, ${recommendation.name} dicatat!')),
    );
  }

  void _navigateFromDrawer(BuildContext context, MapoDrawerItem item) {
    Navigator.of(context).pop();
    switch (item) {
      case MapoDrawerItem.cariMakan:
        break;
      case MapoDrawerItem.riwayat:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiwayatScreen()));
      case MapoDrawerItem.favorit:
      case MapoDrawerItem.pengaturan:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(chatProvider);
    final isPending = turns.isNotEmpty && turns.last is PendingTurn;
    final entriesAsync = ref.watch(mealHistoryEntriesProvider);

    return Scaffold(
      appBar: MapoHeader(
        title: turns.isEmpty ? 'Mangan opo hari ini?' : 'Mapo',
        subtitle: turns.isEmpty ? 'Halo! Bingung mau makan apa?' : null,
        leading: Builder(
          builder: (context) => MapoHeaderIconButton(
            icon: HugeIcons.strokeRoundedMenu01,
            label: 'Buka menu',
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          MapoHeaderIconButton(
            icon: HugeIcons.strokeRoundedUserCircle,
            label: 'Profil',
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilScreen())),
          ),
        ],
      ),
      drawer: MapoDrawer(
        userName: ref.watch(currentUserDisplayProvider).displayName,
        mealCount: entriesAsync.valueOrNull?.length,
        onNavigate: (item) => _navigateFromDrawer(context, item),
      ),
      body: ChatConversationBody(
        turns: turns,
        controller: _controller,
        onSend: _send,
        scrollController: _scroll,
        inputEnabled: !isPending,
        onRetryLast: turns.isEmpty ? null : () => _retryLast(turns),
        onPick: (r) => _pickMeal(context, r),
      ),
    );
  }
}

class ChatConversationBody extends StatelessWidget {
  final List<ChatTurn> turns;
  final TextEditingController controller;
  final Future<void> Function(String) onSend;
  final ScrollController scrollController;
  final bool inputEnabled;
  final void Function(Recommendation)? onPick;
  final VoidCallback? onRetryLast;

  const ChatConversationBody({
    super.key,
    required this.turns,
    required this.controller,
    required this.onSend,
    required this.scrollController,
    this.inputEnabled = true,
    this.onRetryLast,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: turns.isEmpty
              ? _HomeEmptyState(onExampleTap: onSend)
              : ListView.builder(
                  controller: scrollController,
                  padding: AppSpacing.screenPad,
                  itemCount: turns.length,
                  itemBuilder: (context, i) {
                    final isLast = i == turns.length - 1;
                    return _TurnEntrance(
                      child: _TurnView(
                        turn: turns[i],
                        onQuickReply: onSend,
                        onRetry: isLast ? onRetryLast : null,
                        onPick: onPick,
                      ),
                    );
                  },
                ),
        ),
        ChatInputBar(controller: controller, onSend: onSend, enabled: inputEnabled),
      ],
    );
  }
}

class _TurnEntrance extends StatelessWidget {
  final Widget child;
  const _TurnEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
      ),
      child: child,
    );
  }
}

class _TurnView extends StatelessWidget {
  final ChatTurn turn;
  final ValueChanged<String> onQuickReply;
  final VoidCallback? onRetry;
  final void Function(Recommendation)? onPick;

  const _TurnView({
    required this.turn,
    required this.onQuickReply,
    this.onRetry,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return switch (turn) {
      UserTurn(:final text) => _UserBubble(text: text),
      PendingTurn() => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: PendingChecklist(),
        ),
      ErrorTurn(:final message) => _ErrorBubble(message: message, onRetry: onRetry),
      MapoTurn(:final response) => _MapoResponseView(
          response: response,
          onQuickReply: onQuickReply,
          onRetry: onRetry,
          onPick: onPick,
        ),
    };
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration:
            BoxDecoration(color: AppColors.brandFill, borderRadius: BorderRadius.circular(AppRadius.chip)),
        child: Text(text, style: AppText.bodyLarge.copyWith(color: AppColors.ink)),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorBubble({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadSmall,
      decoration: BoxDecoration(color: AppColors.redFill, borderRadius: AppRadius.rCardSmall),
      child: Row(
        children: [
          Expanded(child: Text(message, style: AppText.bodyMedium.copyWith(color: AppColors.redDark))),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ],
      ),
    );
  }
}

class _MapoResponseView extends StatelessWidget {
  final MapoResponse response;
  final ValueChanged<String> onQuickReply;
  final VoidCallback? onRetry;
  final void Function(Recommendation)? onPick;

  const _MapoResponseView({
    required this.response,
    required this.onQuickReply,
    this.onRetry,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(response.message, style: AppText.section),
          const SizedBox(height: AppSpacing.xs),
          GroundingBadge(contextUsed: response.contextUsed),
          const SizedBox(height: AppSpacing.sm),
          ..._body(),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (response.responseType) {
      case ResponseType.single:
        if (response.recommendations.isEmpty) return const [_NoRecommendationsNotice()];
        final first = response.recommendations.first;
        return [
          RecommendationCard(
            recommendation: first,
            onRetry: onRetry,
            onPick: onPick == null ? null : () => onPick!(first),
          ),
        ];
      case ResponseType.options:
        if (response.recommendations.isEmpty) return const [_NoRecommendationsNotice()];
        return response.recommendations
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: RecommendationCard(
                  recommendation: r,
                  variant: RecommendationCardVariant.row,
                  onTap: () => onQuickReply('pilih ${r.name}'),
                ),
              ),
            )
            .toList();
      case ResponseType.clarify:
        final followUp = response.followUp;
        if (followUp == null) return const [];
        return [
          Text(followUp.question, style: AppText.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: followUp.quickReplies
                .map((r) => QuickReplyChip(label: r, onTap: () => onQuickReply(r)))
                .toList(),
          ),
        ];
    }
  }
}

class _NoRecommendationsNotice extends StatelessWidget {
  const _NoRecommendationsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadSmall,
      decoration: BoxDecoration(color: AppColors.lineSoft, borderRadius: AppRadius.rCardSmall),
      child: Text('Mapo belum nemu saran yang pas. Coba ceritain lebih detail ya.', style: AppText.bodyMedium),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  final ValueChanged<String> onExampleTap;
  const _HomeEmptyState({required this.onExampleTap});

  static const _examples = ['lagi hujan, pengen anget', 'budget 15rb, yang murah', 'pengen yang pedas'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.iconBoxLarge,
            height: AppSizes.iconBoxLarge,
            decoration: const BoxDecoration(color: AppColors.brandFill, shape: BoxShape.circle),
            child: Center(
              child:
                  HugeIcon(icon: HugeIcons.strokeRoundedSmile, color: AppColors.brand, size: AppSizes.iconLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Cerita aja ke Mapo', style: AppText.section),
          const SizedBox(height: AppSpacing.xs),
          Text('Lagi pengen apa, budget berapa, mood apa — Mapo bantu pilihin', style: AppText.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text('COBA TANYA', style: AppText.caption.copyWith(letterSpacing: 1)),
          const SizedBox(height: AppSpacing.xs),
          ..._examples.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _ExampleChip(text: e, onTap: () => onExampleTap(e)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _ExampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: AppRadius.rChip,
      child: InkWell(
        borderRadius: AppRadius.rChip,
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.chipPad,
          child: Text(text, style: AppText.bodyMedium.copyWith(color: AppColors.ink)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Delete the old `ChatScreen` and update `main.dart`**

Run: `rm lib/ui/chat_screen.dart`

In `lib/main.dart`, change:

```dart
import 'package:mapo_app/ui/chat_screen.dart';
```

to:

```dart
import 'package:mapo_app/ui/screens/chat_screen.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/ui/screens/chat_screen_test.dart`
Expected: PASS (10 tests)

- [ ] **Step 6: Run full test suite and analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS, `No issues found!` If analyze complains about an unused import in `lib/main.dart` or a dangling reference to the old `lib/ui/chat_screen.dart` path anywhere (check with `grep -rn "ui/chat_screen" lib/ test/`), fix it before committing.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/screens/chat_screen.dart lib/main.dart test/ui/screens/chat_screen_test.dart
git rm lib/ui/chat_screen.dart
git commit -m "feat: redesign ChatScreen — Home, Loading, Single, Options, Clarify, error"
```

---

### Task 14: Debug screens gallery + `main.dart` wiring

The last piece from the spec: every screen/state previewable without a live API call. This is only possible now that `ChatConversationBody`, `RiwayatBody`, and `ProfilBody` exist as dumb, provider-free widgets (Tasks 13, 11, 12). Gated behind `kDebugMode` — a compile-time constant, so Dart's release compiler eliminates this entire code path from release builds (standard Flutter idiom, not a runtime check that could leak through).

**Files:**
- Create: `lib/ui/debug/mock_data.dart`
- Create: `lib/ui/debug/screens_gallery.dart`
- Modify: `lib/main.dart`
- Test: `test/ui/debug/mock_data_test.dart`
- Test: `test/ui/debug/screens_gallery_test.dart`

**Interfaces:**
- Consumes: `ChatConversationBody` (Task 13), `RiwayatBody` (Task 11), `ProfilBody` (Task 12), `MapoDrawer` (Task 8), `MapoHeader` (Task 6), `ChatTurn`/`MapoResponse`/`MealHistoryEntry`/`UserPrefs` models (all already exist)
- Produces: `mockSingleResponse()`, `mockOptionsResponse()`, `mockClarifyResponse()`, `mockTurnsHome()`, `mockTurnsLoading()`, `mockTurnsSingle()`, `mockTurnsOptions()`, `mockTurnsClarify()`, `mockTurnsError()`, `mockMealHistoryEntries()`, `mockMealHistoryEmpty`, `ScreensGallery` widget

- [ ] **Step 1: Write the failing tests for mock data**

Create `test/ui/debug/mock_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/models/chat_turn.dart';
import 'package:mapo_app/models/mapo_response.dart';
import 'package:mapo_app/ui/debug/mock_data.dart';

void main() {
  test('mockTurnsHome kosong', () {
    expect(mockTurnsHome(), isEmpty);
  });

  test('mockTurnsLoading berakhir dengan PendingTurn', () {
    expect(mockTurnsLoading().last, isA<PendingTurn>());
  });

  test('mockTurnsSingle berakhir dengan MapoTurn response_type single', () {
    final last = mockTurnsSingle().last as MapoTurn;
    expect(last.response.responseType, ResponseType.single);
    expect(last.response.recommendations, isNotEmpty);
  });

  test('mockTurnsOptions punya lebih dari satu rekomendasi', () {
    final last = mockTurnsOptions().last as MapoTurn;
    expect(last.response.responseType, ResponseType.options);
    expect(last.response.recommendations.length, greaterThan(1));
  });

  test('mockTurnsClarify punya quick_replies', () {
    final last = mockTurnsClarify().last as MapoTurn;
    expect(last.response.responseType, ResponseType.clarify);
    expect(last.response.followUp?.quickReplies, isNotEmpty);
  });

  test('mockTurnsError berakhir dengan ErrorTurn', () {
    expect(mockTurnsError().last, isA<ErrorTurn>());
  });

  test('mockMealHistoryEntries menyertakan satu entri harga null', () {
    expect(mockMealHistoryEntries().where((e) => e.price == null), isNotEmpty);
  });

  test('mockMealHistoryEmpty kosong', () {
    expect(mockMealHistoryEmpty, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/debug/mock_data_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/debug/mock_data.dart'`

- [ ] **Step 3: Create `mock_data.dart`**

Create directory `lib/ui/debug/` and the file `lib/ui/debug/mock_data.dart`:

```dart
import '../../models/chat_turn.dart';
import '../../models/mapo_response.dart';
import '../../models/meal_history_entry.dart';

MapoResponse mockSingleResponse() => const MapoResponse(
      responseType: ResponseType.single,
      message: 'Buat kamu yang lagi pengen anget',
      recommendations: [
        Recommendation(
          name: 'Soto Ayam',
          reason: 'Kuahnya anget pas buat cuaca hujan, ringan, dan masih di bawah budget kamu.',
          category: 'berkuah',
          priceEstimate: 13000,
          spiceLevel: 'sedang',
          prepTime: 'cepat',
          tags: ['hangat'],
        ),
      ],
      contextUsed: ContextUsed(weather: 'hujan ringan'),
    );

MapoResponse mockOptionsResponse() => const MapoResponse(
      responseType: ResponseType.options,
      message: 'Ada 3 pilihan yang cocok buat cuaca hujan hari ini:',
      recommendations: [
        Recommendation(
          name: 'Soto Ayam',
          reason: 'Kuahnya anget',
          category: 'berkuah',
          priceEstimate: 13000,
          spiceLevel: 'sedang',
          prepTime: 'cepat',
        ),
        Recommendation(
          name: 'Bakso',
          reason: 'Kuahnya agak pedas',
          category: 'pedas',
          priceEstimate: 15000,
          spiceLevel: 'pedas',
          prepTime: 'cepat',
        ),
        Recommendation(
          name: 'Bakmi Godog',
          reason: 'Gurih dan mengenyangkan',
          category: 'mie',
          priceEstimate: 12000,
          spiceLevel: 'tidak_pedas',
          prepTime: 'sedang',
        ),
      ],
    );

MapoResponse mockClarifyResponse() => const MapoResponse(
      responseType: ResponseType.clarify,
      message: 'Siap bantu!',
      followUp: FollowUp(
        question: 'Biar pas, kamu lagi pengen yang gimana nih?',
        quickReplies: ['yang murah', 'yang pedas', 'yang cepet', 'yang sehat'],
      ),
    );

List<ChatTurn> mockTurnsHome() => const [];

List<ChatTurn> mockTurnsLoading() => const [UserTurn('lagi hujan, pengen anget'), PendingTurn()];

List<ChatTurn> mockTurnsSingle() =>
    [const UserTurn('lagi hujan, pengen anget'), MapoTurn(mockSingleResponse())];

List<ChatTurn> mockTurnsOptions() =>
    [const UserTurn('bingung, kasih pilihan dong'), MapoTurn(mockOptionsResponse())];

List<ChatTurn> mockTurnsClarify() => [const UserTurn('aku laper'), MapoTurn(mockClarifyResponse())];

List<ChatTurn> mockTurnsError() =>
    const [UserTurn('laper'), ErrorTurn('Mapo lagi bingung, coba lagi ya')];

List<MealHistoryEntry> mockMealHistoryEntries() => [
      MealHistoryEntry(
        name: 'Soto Ayam',
        category: 'berkuah',
        eatenAt: DateTime.now().subtract(const Duration(hours: 2)),
        price: 13000,
      ),
      MealHistoryEntry(
        name: 'Ayam Bakar',
        category: 'bakar',
        eatenAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        price: 20000,
      ),
      // Harga null — kondisi nyata sebelum Task 6 arsitektur menyimpan harga.
      MealHistoryEntry(
        name: 'Bakso',
        category: 'berkuah',
        eatenAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      ),
    ];

const mockMealHistoryEmpty = <MealHistoryEntry>[];
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/debug/mock_data_test.dart`
Expected: PASS (8 tests)

- [ ] **Step 5: Write the failing test for the gallery**

Create `test/ui/debug/screens_gallery_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapo_app/ui/debug/screens_gallery.dart';

void main() {
  testWidgets('menampilkan semua entri dan membuka preview Single', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScreensGallery()));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Single'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Clarify'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Riwayat (terisi)'), findsOneWidget);
    expect(find.text('Riwayat (kosong)'), findsOneWidget);
    expect(find.text('Profil (anonim)'), findsOneWidget);
    expect(find.text('Menu (drawer)'), findsOneWidget);

    await tester.tap(find.text('Single'));
    await tester.pumpAndSettle();

    expect(find.text('Soto Ayam'), findsOneWidget);
    expect(find.text('Makan ini'), findsOneWidget);
  });

  testWidgets('preview Riwayat kosong menampilkan pesan ramah', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScreensGallery()));

    await tester.tap(find.text('Riwayat (kosong)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/ui/debug/screens_gallery_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:mapo_app/ui/debug/screens_gallery.dart'`

- [ ] **Step 7: Create `screens_gallery.dart`**

Create `lib/ui/debug/screens_gallery.dart`:

```dart
import 'package:flutter/material.dart';
import '../../models/chat_turn.dart';
import '../../models/user_prefs.dart';
import '../../themes/app_colors.dart';
import '../screens/chat_screen.dart';
import '../screens/profil_screen.dart';
import '../screens/riwayat_screen.dart';
import '../widgets/mapo_drawer.dart';
import '../widgets/mapo_header.dart';
import 'mock_data.dart';

class ScreensGallery extends StatelessWidget {
  const ScreensGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_GalleryEntry>[
      _GalleryEntry('Home', () => _ChatPreview(turns: mockTurnsHome())),
      _GalleryEntry('Loading', () => _ChatPreview(turns: mockTurnsLoading())),
      _GalleryEntry('Single', () => _ChatPreview(turns: mockTurnsSingle())),
      _GalleryEntry('Options', () => _ChatPreview(turns: mockTurnsOptions())),
      _GalleryEntry('Clarify', () => _ChatPreview(turns: mockTurnsClarify())),
      _GalleryEntry('Error', () => _ChatPreview(turns: mockTurnsError())),
      _GalleryEntry(
        'Riwayat (terisi)',
        () => Scaffold(
          appBar: const MapoHeader(title: 'Riwayat makan', color: AppColors.green),
          body: RiwayatBody(entries: mockMealHistoryEntries()),
        ),
      ),
      _GalleryEntry(
        'Riwayat (kosong)',
        () => const Scaffold(
          appBar: MapoHeader(title: 'Riwayat makan', color: AppColors.green),
          body: RiwayatBody(entries: mockMealHistoryEmpty),
        ),
      ),
      _GalleryEntry(
        'Profil (anonim)',
        () => Scaffold(
          appBar: const MapoHeader(title: 'Profil'),
          body: ProfilBody(
            displayName: 'Ammar',
            isAnonymous: true,
            prefs: const UserPrefs(),
            onGoogleSignInTap: () {},
          ),
        ),
      ),
      _GalleryEntry(
        'Menu (drawer)',
        () => Scaffold(
          appBar: const MapoHeader(title: 'Cari makan'),
          drawer: MapoDrawer(userName: 'Ammar', mealCount: 12, onNavigate: (_) {}),
          body: const Center(child: Text('Buka drawer lewat ikon menu di header')),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mapo — semua tampilan (debug)')),
      body: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => ListTile(
          title: Text(entries[i].label),
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => entries[i].builder())),
        ),
      ),
    );
  }
}

class _GalleryEntry {
  final String label;
  final Widget Function() builder;
  _GalleryEntry(this.label, this.builder);
}

class _ChatPreview extends StatefulWidget {
  final List<ChatTurn> turns;
  const _ChatPreview({required this.turns});

  @override
  State<_ChatPreview> createState() => _ChatPreviewState();
}

class _ChatPreviewState extends State<_ChatPreview> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.turns.isNotEmpty && widget.turns.last is PendingTurn;
    return Scaffold(
      appBar: const MapoHeader(title: 'Mapo (preview)'),
      body: ChatConversationBody(
        turns: widget.turns,
        controller: _controller,
        onSend: (_) async {},
        scrollController: _scroll,
        inputEnabled: !isPending,
        onPick: (r) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('(preview) ${r.name} dipilih')),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/ui/debug/screens_gallery_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 9: Wire the debug entry point into `main.dart`**

In `lib/main.dart`, add the import:

```dart
import 'package:hugeicons/hugeicons.dart';
import 'package:mapo_app/ui/debug/screens_gallery.dart';
```

Replace the `MapoApp` class body:

```dart
class MapoApp extends StatelessWidget {
  const MapoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapoApp',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routes: kDebugMode ? {'/debug': (context) => const ScreensGallery()} : const {},
      home: kDebugMode ? const _DebugHome() : const ChatScreen(),
    );
  }
}

class _DebugHome extends StatelessWidget {
  const _DebugHome();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ChatScreen(),
        Positioned(
          right: 16,
          bottom: 88,
          child: FloatingActionButton.small(
            heroTag: 'debug-gallery-fab',
            onPressed: () => Navigator.of(context).pushNamed('/debug'),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedIdea01, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 10: Run full test suite and analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS, `No issues found!`

- [ ] **Step 11: Commit**

```bash
git add lib/ui/debug/mock_data.dart lib/ui/debug/screens_gallery.dart lib/main.dart test/ui/debug/mock_data_test.dart test/ui/debug/screens_gallery_test.dart
git commit -m "feat: tambah debug screens gallery dan wiring main.dart"
```

---

## Post-implementation checklist

- [ ] `flutter test` — all tests pass
- [ ] `flutter analyze` — `No issues found!`
- [ ] Manually run `flutter run` in debug mode, tap through all 10 gallery entries, confirm nothing crashes or overflows on a small simulated screen (iPhone SE size) and a tablet size
- [ ] Manually run the real flow once (send a message, get a real Gemini response) to confirm `ChatConversationBody` renders live data the same way it renders mock data
- [ ] Confirm the debug FAB and `/debug` route are absent from a release build (`flutter build apk --release` or equivalent; `kDebugMode` should have stripped `_DebugHome`/`ScreensGallery` — spot check by grepping the compiled output is unnecessary, trusting `kDebugMode`'s standard Flutter guarantee is sufficient)

