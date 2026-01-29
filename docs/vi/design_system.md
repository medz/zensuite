# Kiến trúc hệ thống thiết kế (Design System)

Tài liệu này mô tả cách xây dựng hệ thống thiết kế modular, có khả năng mở rộng sử dụng `theme_tailor`, cung cấp theming type-safe và tính nhất quán của component trong ứng dụng Flutter.

## Các khái niệm cốt lõi

### Cấu trúc hệ thống thiết kế

Hệ thống thiết kế tuân theo kiến trúc ba tầng:

```mermaid
graph TD
    A[ZenoriesTheme] -->|Chứa| B[Tokens]
    A -->|Chứa| C[Atomic Components]
    A -->|Chứa| D[Components]
    B --> E[Colors]
    B --> F[Typography]
    B --> G[Spacing]
    B --> H[BorderRadius]
    C --> I[FlexStack]
    C --> J[ZStack]
    D --> K[Button]
    D --> L[Card]
    D --> M[Chip]
    D --> N[Các Components khác...]
```

**Ba tầng**:
1. **Tokens**: Các giá trị thiết kế nền tảng (colors, typography, spacing, border radius)
2. **Atomic Components**: Các primitives layout cấp thấp được sử dụng để xây dựng components
3. **Components**: Các phần tử UI có thể tái sử dụng (buttons, cards, chips, etc.)

### Tại sao dùng theme_tailor?

[theme_tailor](https://pub.dev/packages/theme_tailor) là công cụ sinh mã cung cấp:

- **Theming type-safe**: Truy cập giá trị theme với compile-time safety
- **Tự động lerping**: Chuyển đổi theme mượt mà giữa light/dark modes
- **BuildContext extensions**: Truy cập theme tiện lợi qua `context.zenoriesTheme`
- **Component modularity**: Mỗi component định nghĩa theme extension riêng

## Thiết lập hệ thống thiết kế

### Bước 1: Định nghĩa lớp Token

Tokens là nền tảng của hệ thống thiết kế. Tạo các file riêng biệt cho mỗi danh mục token.

#### Colors

Định nghĩa bảng màu toàn diện dựa trên Material 3:

```dart
// lib/src/ui/colors.dart
import 'package:flutter/material.dart' show ColorScheme;

class ZenoriesColors {
  const ZenoriesColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    // ... tất cả Material 3 color roles
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
  });

  factory ZenoriesColors.fromMaterial(ColorScheme colorScheme) => 
      ZenoriesColors(
        primary: colorScheme.primary,
        onPrimary: colorScheme.onPrimary,
        // ... ánh xạ tất cả màu
      );

  // Primary colors
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  
  // Surface colors
  final Color surface;
  final Color onSurface;
  final Color surfaceContainer;
  
  // Error colors
  final Color error;
  final Color onError;
  
  // ... tất cả các Material 3 roles khác
}
```

**Tạo custom encoder cho theme_tailor**:

```dart
class ZenoriesColorsEncoder extends ThemeEncoder<ZenoriesColors> {
  const ZenoriesColorsEncoder();

  @override
  ZenoriesColors lerp(ZenoriesColors a, ZenoriesColors b, double t) {
    return ZenoriesColors(
      primary: Color.lerp(a.primary, b.primary, t)!,
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
      // ... lerp tất cả màu
    );
  }
}
```

#### Typography

Tạo hệ thống typography với đặt tên ngữ nghĩa:

```dart
// lib/src/ui/typography.dart
class ZenoriesTypography {
  const ZenoriesTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.bodyMedium,
    required this.labelSmall,
    // ... tất cả text styles
  });

  factory ZenoriesTypography.standard() => ZenoriesTypography(
    displayLarge: TextStyle(
      fontFamily: 'YourFont',
      fontSize: 57,
      height: 1.12,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'YourFont',
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w400,
    ),
    // ... định nghĩa tất cả styles
  );

  final TextStyle displayLarge;
  final TextStyle bodyMedium;
  final TextStyle labelSmall;
  // ... tất cả styles
}
```

**Typography encoder**:

```dart
class ZenoriesTypographyEncoder extends ThemeEncoder<ZenoriesTypography> {
  const ZenoriesTypographyEncoder();

  @override
  ZenoriesTypography lerp(ZenoriesTypography a, ZenoriesTypography b, double t) {
    return ZenoriesTypography(
      displayLarge: TextStyle.lerp(a.displayLarge, b.displayLarge, t)!,
      bodyMedium: TextStyle.lerp(a.bodyMedium, b.bodyMedium, t)!,
      // ... lerp tất cả styles
    );
  }
}
```

#### Spacing

Định nghĩa thang spacing nhất quán:

```dart
// lib/src/ui/spacing.dart
class ZenoriesSpacing {
  const ZenoriesSpacing({
    required this.none,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  static const ZenoriesSpacing standard = ZenoriesSpacing(
    none: 0,
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
  );

  final double none;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
}
```

#### Border Radius

Định nghĩa các giá trị bo góc:

```dart
// lib/src/ui/border_radius.dart
class ZenoriesBorderRadius {
  const ZenoriesBorderRadius({
    required this.none,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  static const standard = ZenoriesBorderRadius(
    none: 0,
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    full: 9999,
  );

  final double none;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;

  // Convenience getters
  BorderRadius get mdRadius => BorderRadius.circular(md);
  BorderRadius get lgRadius => BorderRadius.circular(lg);
}
```

### Bước 2: Tạo Token Container

Kết hợp tất cả tokens vào một class token duy nhất:

```dart
// lib/src/ui/theme.dart
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'theme.tailor.dart';

@tailorMixinComponent
@ZenoriesColorsEncoder()
@ZenoriesTypographyEncoder()
@ZenoriesSpacingEncoder()
@ZenoriesBorderRadiusEncoder()
class ZenoriesToken extends ThemeExtension<ZenoriesToken>
    with _$ZenoriesTokenTailorMixin {
  const ZenoriesToken({
    required this.colors,
    required this.typography,
    this.spacing = .standard,
    this.borderRadius = .standard,
    required this.brightness,
  });

  final Brightness brightness;
  final ZenoriesColors colors;
  final ZenoriesTypography typography;
  final ZenoriesSpacing spacing;
  final ZenoriesBorderRadius borderRadius;
}
```

**Điểm chính**:
- Sử dụng `@tailorMixinComponent` để đánh dấu đây là theme component
- Sử dụng custom encoders với annotations `@ZenoriesColorsEncoder()`
- Cung cấp giá trị mặc định cho spacing và border radius với `.standard`

### Bước 3: Định nghĩa Component Themes

Mỗi component nên có class theme riêng định nghĩa các thuộc tính styling của nó.

#### Ví dụ: Button Theme

```dart
// lib/src/ui/button.dart
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'button.tailor.dart';

@tailorMixinComponent
class ZButtonTheme extends ThemeExtension<ZButtonTheme>
    with _$ZButtonThemeTailorMixin {
  ZButtonTheme({
    required this.shape,
    required this.surface,
    required this.onSurface,
    required this.textStyle,
    required this.constraints,
    required this.padding,
  });

  factory ZButtonTheme.standard(ZenoriesToken token) {
    final ZenoriesToken(:colors, :typography, :borderRadius, :spacing) = token;

    return ZButtonTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius.xl),
      ),
      surface: WidgetStateColor.fromMap({
       WidgetState.disabled: colors.onSurface.withOpacity(0.12),
        WidgetState.pressed: colors.primary.withOpacity(0.6),
        WidgetState.any: colors.primary,
      }),
      onSurface: WidgetStateColor.fromMap({
        WidgetState.disabled: colors.onSurface.withOpacity(0.38),
        WidgetState.any: colors.onPrimary,
      }),
      textStyle: typography.bodyMedium,
      constraints: BoxConstraints(minHeight: 44, minWidth: 44),
      padding: EdgeInsets.all(spacing.sm),
    );
  }

  final ShapeBorder shape;
  final WidgetStateProperty<Color> surface;
  final WidgetStateProperty<Color> onSurface;
  final TextStyle textStyle;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry padding;
}
```

**Mô hình**:
- Định nghĩa `ThemeExtension` cho component
- Tạo factory `.standard(ZenoriesToken)` xây dựng styling mặc định từ tokens
- Sử dụng `WidgetStateProperty` cho các trạng thái tương tác (hover, pressed, disabled)

### Bước 4: Tạo Master Theme

Kết hợp tokens và component themes:

```dart
// lib/src/ui/theme.dart
@TailorMixin(themeGetter: ThemeGetter.onBuildContextProps)
class ZenoriesTheme extends ThemeExtension<ZenoriesTheme>
    with _$ZenoriesThemeTailorMixin {
  const ZenoriesTheme({
    required this.token,
    required this.button,
    required this.card,
    required this.chip,
    // ... tất cả component themes
  });

  final ZenoriesToken token;
  final ZButtonTheme button;
  final ZCardTheme card;
  final ZChipTheme chip;
  //... tất cả component themes
}
```

**Điểm chính**:
- Sử dụng `@TailorMixin(themeGetter: ThemeGetter.onBuildContextProps)` để sinh extension `context.zenoriesTheme`
- Bao gồm token và tất cả component themes

### Bước 5: Tạo Theme Presets

Định nghĩa các theme instances light và dark:

```dart
// lib/src/ui/presets.dart
import 'package:flex_color_scheme/flex_color_scheme.dart';

ZenoriesTheme createTheme(ZenoriesToken token) {
  return ZenoriesTheme(
    token: token,
    button: ZButtonTheme.standard(token),
    card: ZCardTheme.standard(token),
    chip: ZChipTheme.standard(token),
    // ... tất cả components
  );
}

final lightTheme = () {
  final flexColorTheme = FlexThemeData.light(scheme: FlexScheme.amber);
  final token = ZenoriesToken(
    colors: ZenoriesColors.fromMaterial(flexColorTheme.colorScheme),
    typography: ZenoriesTypography.standard(),
    brightness: Brightness.light,
  );

  return createTheme(token);
}();

final darkTheme = () {
  final flexColorTheme = FlexThemeData.dark(scheme: FlexScheme.aquaBlue);
  final token = ZenoriesToken(
    colors: ZenoriesColors.fromMaterial(flexColorTheme.colorScheme),
    typography: ZenoriesTypography.standard(),
    brightness: Brightness.dark,
  );

  return createTheme(token);
}();
```

### Bước 6: Tạo Theme Provider

Bọc ứng dụng của bạn với theme provider:

```dart
// lib/src/ui/theme.dart
class ZenoriesThemeProvider extends StatefulWidget {
  const ZenoriesThemeProvider({super.key, this.data, required this.child});

  final ZenoriesTheme? data;
  final Widget child;

  @override
  State<ZenoriesThemeProvider> createState() => _ZenoriesThemeProviderState();
}

class _ZenoriesThemeProviderState extends State<ZenoriesThemeProvider> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data ?? 
        switch (MediaQuery.platformBrightnessOf(context)) {
          Brightness.light => lightTheme,
          Brightness.dark => darkTheme,
        };

    return Theme(
      data: ThemeData(extensions: [data]),
      child: widget.child,
    );
  }
}
```

### Bước 7: Chạy Code Generation

Chạy build_runner để sinh mã theme_tailor:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Điều này sinh ra:
- `theme.tailor.dart` - Theme extensions và BuildContext getters
- `button.tailor.dart` - Button theme extensions
- ... cho mỗi component

## Sử dụng hệ thống thiết kế

### Truy cập Theme trong Widgets

Sử dụng các extension methods đã được sinh:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.zenoriesTheme;
    final token = context.token;
    final button = context.button;

    return Container(
      color: token.colors.surface,
      padding: EdgeInsets.all(token.spacing.md),
      child: Text(
        'Hello',
        style: token.typography.bodyMedium,
      ),
    );
  }
}
```

### Tạo Components

Xây dựng components sử dụng theme của chúng:

```dart
class ZButton extends StatefulWidget {
  const ZButton({
    super.key,
    required this.child,
    this.onPressed,
    this.modifier,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final ThemeModifier<ZButtonTheme>? modifier;

  @override
  State<ZButton> createState() => _ZButtonState();
}

class _ZButtonState extends State<ZButton> {
  @override
  Widget build(BuildContext context) {
    final theme = context.zenoriesTheme;
    final style = widget.modifier?.call(theme, theme.button) ?? theme.button;

    return GestureDetector(
      onTap: widget.onPressed,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: style.shape,
          color: style.surface.resolve(states),
        ),
        child: DefaultTextStyle.merge(
          style: style.textStyle.copyWith(
            color: style.onSurface.resolve(states),
          ),
          child: Padding(
            padding: style.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
```

### Mô hình Theme Modification

Cho phép components được tùy chỉnh với theme modifiers:

```dart
// Định nghĩa modifiers như static methods
class ZButton extends StatefulWidget {
  static ThemeModifier<ZButtonTheme> get accentModifier =>
      (theme, style) => style.copyWith(
        surface: WidgetStateColor.fromMap({
          WidgetState.any: theme.token.colors.surfaceContainer,
        }),
        onSurface: WidgetStateColor.fromMap({
          WidgetState.any: theme.token.colors.onSurfaceVariant,
        }),
      );

  static ThemeModifier<ZButtonTheme> get outlinedModifier =>
      (theme, style) => style.copyWith(
        surface: WidgetStateColor.fromMap({
          WidgetState.any: theme.token.colors.surface,
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.token.borderRadius.xl),
          side: BorderSide(color: theme.token.colors.outline),
        ),
      );
}

// Sử dụng
ZButton(
  modifier: ZButton.accentModifier,
  onPressed: () {},
  child: Text('Accent Button'),
)
```

## Mô hình nâng cao

### Variable Fonts

Sử dụng variable fonts cho kiểm soát chi tiết:

```dart
factory ZenoriesTypography.standard() => ZenoriesTypography(
  displayLarge: TextStyle(
    fontFamily: 'GoogleSansFlex',
    fontSize: 57,
    fontVariations: [
      FontVariation('wght', 350),
      FontVariation('opsz', 144),
      FontVariation('ROND', 50), // roundness
    ],
  ),
);
```

### Hỗ trợ Dynamic Color

Tích hợp với Material You dynamic colors:

```dart
// lib/src/ui/dynamic_color.dart
extension DynamicColorExtension on Widget {
  Widget withDynamicColor() {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // Sử dụng system colors nếu có
        if (lightDynamic != null && darkDynamic != null) {
          return this; // Áp dụng dynamic colors
        }
        return this; // Fallback về static colors
      },
    );
  }
}
```

### Mô hình Custom Component

Tuân theo mô hình này cho tất cả components:

1. **Tạo theme class** với `@tailorMixinComponent`
2. **Định nghĩa factory `.standard(ZenoriesToken)`** cho styling mặc định
3. **Tạo component widget** sử dụng theme của nó
4. **Hỗ trợ modifiers** cho customization
5. **Export từ `ui.dart`**

## Tổ chức File

```
lib/src/ui/
├── design_system.dart       # Token exports
├── ui.dart                  # Public API
├── theme.dart               # Master theme
├── presets.dart             # Theme instances
│
├── colors.dart              # Color tokens
├── typography.dart          # Typography tokens
├── spacing.dart             # Spacing tokens
├── border_radius.dart       # Border radius tokens
│
├── button.dart              # Button component
├── button.tailor.dart       # Generated
├── card.dart                # Card component
├── card.tailor.dart         # Generated
└── ...                      # Các components khác
```

## Các phương pháp tốt nhất

### 1. Thiết kế Token-First

Luôn tham chiếu tokens, không bao giờ hardcode giá trị:

✅ **Tốt**:
```dart
color: token.colors.primary,
padding: EdgeInsets.all(token.spacing.md),
borderRadius: BorderRadius.circular(token.borderRadius.lg),
```

❌ **Không tốt**:
```dart
color: Colors.blue,
padding: EdgeInsets.all(12),
borderRadius: BorderRadius.circular(12),
```

### 2. Tên màu ngữ nghĩa

Sử dụng Material 3 semantic color roles:

```dart
// Primary actions
surface: colors.primary,
onSurface: colors.onPrimary,

// Secondary actions
surface: colors.secondaryContainer,
onSurface: colors.onSecondaryContainer,

// Surfaces
background: colors.surface,
text: colors.onSurface,
```

### 3. Tính độc lập Component

Mỗi component theme nên tự chứa (self-contained):

```dart
// Button không biết về Card
factory ZButtonTheme.standard(ZenoriesToken token) {
  // Chỉ sử dụng token, không dùng component themes khác
  return ZButtonTheme(...);
}
```

### 4. Quy ước đặt tên nhất quán

Tuân theo quy ước đặt tên:

- Theme classes: `Z{Component}Theme`
- Components: `Z{Component}`
- Modifiers: `{variant}Modifier` (static methods)
- Tokens: `Zenories{Token}` (ví dụ: `ZenoriesColors`)

### 5. Quản lý trạng thái

Sử dụng `WidgetStateProperty` cho các trạng thái tương tác:

```dart
surface: WidgetStateColor.fromMap({
  WidgetState.disabled: colors.onSurface.withOpacity(0.12),
  WidgetState.hovered: colors.primary.withOpacity(0.8),
  WidgetState.pressed: colors.primary.withOpacity(0.6),
  WidgetState.focused: colors.primary.withOpacity(0.9),
  WidgetState.any: colors.primary,
}),
```

## Tóm tắt

Hệ thống thiết kế cung cấp:

- ✅ **Type-safe**: Truy cập theme compile-time qua generated extensions
- ✅ **Modular**: Mỗi component có theme riêng
- ✅ **Scalable**: Dễ dàng thêm tokens và components mới
- ✅ **Consistent**: Single source of truth cho giá trị thiết kế
- ✅ **Flexible**: Theme modifiers cho component customization
- ✅ **Maintainable**: Tách biệt rõ ràng tokens, themes, và components
