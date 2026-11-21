export class Theme {
  static readonly pagePad: number = 16;
  static readonly cardRadius: number = 20;
  static readonly cardPad: number = 16;
  static readonly fabSize: number = 56;

  static readonly fontTitle: number = 22;
  static readonly fontBigAmount: number = 30;
  static readonly fontListAmount: number = 18;
  static readonly fontBody: number = 16;
  static readonly fontAux: number = 12;

  static readonly cBgTop: Resource = $r('app.color.bg_page_top');
  static readonly cBgBottom: Resource = $r('app.color.bg_page_bottom');
  static readonly cBrand: Resource = $r('app.color.brand_blue');
  static readonly cBrandLight: Resource = $r('app.color.brand_blue_light');
  static readonly cRed: Resource = $r('app.color.expense_red');
  static readonly cGreen: Resource = $r('app.color.income_green');
  static readonly cCard: Resource = $r('app.color.card_bg');
  static readonly cText: Resource = $r('app.color.text_primary');
  static readonly cText2: Resource = $r('app.color.text_secondary');
  static readonly cText3: Resource = $r('app.color.text_tertiary');
  static readonly cDivider: Resource = $r('app.color.divider');
  static readonly cOrange: Resource = $r('app.color.tag_orange');
  static readonly cCatSel: Resource = $r('app.color.selected_cat_bg');
  static readonly cSearch: Resource = $r('app.color.search_bg');
  static readonly cChip: Resource = $r('app.color.chip_bg');
  static readonly cTabBar: Resource = $r('app.color.tab_bar_bg');
  static readonly cGlassBar: Resource = $r('app.color.glass_bar_bg');
  static readonly cGlassBorder: Resource = $r('app.color.glass_bar_border');
  static readonly cGlassCircle: Resource = $r('app.color.glass_circle_bg');
  static readonly cGlassSearch: Resource = $r('app.color.glass_search_bg');
  static readonly cFabShadow: Resource = $r('app.color.fab_shadow');
  static readonly cGlassShadow: Resource = $r('app.color.glass_shadow');
}

export class SymRes {
  private static readonly map: Record<string, Resource> = {
    'house': $r('sys.symbol.house'),
    'house_fill': $r('sys.symbol.house_fill'),
    'calendar': $r('sys.symbol.calendar'),
    'calendar_badge_plus': $r('sys.symbol.calendar_badge_plus'),
    'creditcard': $r('sys.symbol.creditcard'),
    'creditcard_fill': $r('sys.symbol.creditcard_fill'),
    'data_line': $r('sys.symbol.data_line'),
    'person': $r('sys.symbol.person_crop_circle_fill_1'),
    'chevron_down': $r('sys.symbol.chevron_down'),
    'chevron_up': $r('sys.symbol.chevron_up'),
    'chevron_left': $r('sys.symbol.chevron_left'),
    'chevron_right': $r('sys.symbol.chevron_right'),
    'plus': $r('sys.symbol.plus'),
    'search': $r('sys.symbol.magnifyingglass'),
    'close': $r('sys.symbol.xmark'),
    'trash': $r('sys.symbol.trash'),
    'check': $r('sys.symbol.checkmark'),
    'check_circle': $r('sys.symbol.checkmark_circle'),
    'check_circle_fill': $r('sys.symbol.checkmark_circle_fill'),
    'circle': $r('sys.symbol.circle'),
    'eye': $r('sys.symbol.eye'),
    'eye_slash': $r('sys.symbol.eye_slash'),
    'clock': $r('sys.symbol.clock'),
    'gear': $r('sys.symbol.gearshape'),
    'doc_text': $r('sys.symbol.doc_text'),
    'doc_plain': $r('sys.symbol.doc_plaintext'),
    'question': $r('sys.symbol.questionmark_circle'),
    'book': $r('sys.symbol.book'),
    'paperplane': $r('sys.symbol.paperplane'),
    'coins': $r('sys.symbol.coins'),
    'wallet': $r('sys.symbol.wallet'),
    'bag': $r('sys.symbol.bag'),
    'fork_knife': $r('sys.symbol.fork_knife'),
    'car': $r('sys.symbol.car'),
    'game': $r('sys.symbol.gamecontroller'),
    'cross_case': $r('sys.symbol.cross_case'),
    'graduationcap': $r('sys.symbol.graduationcap'),
    'phone': $r('sys.symbol.phone'),
    'gift': $r('sys.symbol.gift'),
    'ellipsis_circle': $r('sys.symbol.ellipsis_circle'),
    'grid': $r('sys.symbol.square_grid_2x2'),
    'heart': $r('sys.symbol.heart'),
    'briefcase': $r('sys.symbol.briefcase'),
    'share': $r('sys.symbol.share'),
    'icloud': $r('sys.symbol.icloud'),
    'arrow_down_circle': $r('sys.symbol.arrow_down_circle'),
    'arrow_up_circle': $r('sys.symbol.arrow_up_circle'),
    'alarm': $r('sys.symbol.alarm'),
    'list_bullet': $r('sys.symbol.list_bullet'),
    'message': $r('sys.symbol.message'),
    'arrow_right': $r('sys.symbol.arrow_right'),
    'arrow_clockwise': $r('sys.symbol.arrow_clockwise'),
    'arrow_counterclockwise': $r('sys.symbol.arrow_counterclockwise'),
    'flame': $r('sys.symbol.flame'),
    'wifi': $r('sys.symbol.wifi'),
    'medal': $r('sys.symbol.medal'),
    'diamond': $r('sys.symbol.diamond'),
    'calculator': $r('sys.symbol.calculator'),
    'label': $r('sys.symbol.label'),
    'keyboard': $r('sys.symbol.keyboard'),
    'camera': $r('sys.symbol.camera'),
    'building': $r('sys.symbol.building'),
    'store': $r('sys.symbol.store'),
    'bell': $r('sys.symbol.bell'),
    'star': $r('sys.symbol.star'),
    'bookmark': $r('sys.symbol.bookmark'),
    'lightbulb': $r('sys.symbol.lightbulb'),
    'wrench': $r('sys.symbol.wrench_and_screwdriver'),
    'cup': $r('sys.symbol.cup'),
    'cake': $r('sys.symbol.cake'),
    'movie': $r('sys.symbol.movie'),
    'headphones': $r('sys.symbol.headphones'),
    'basketball': $r('sys.symbol.basketball'),
    'stethoscope': $r('sys.symbol.stethoscope'),
    'timer': $r('sys.symbol.timer'),
    'stopwatch': $r('sys.symbol.stopwatch'),
    'sun': $r('sys.symbol.sun'),
    'moon': $r('sys.symbol.moon')
  };

  static get(name: string): Resource {
    const r: Resource | undefined = SymRes.map[name];
    if (r === undefined) {
      return $r('sys.symbol.ellipsis_circle');
    }
    return r;
  }
}

export class Fmt {
  static withCommas(intPart: string): string {
    let out: string = '';
    let count: number = 0;
    let i: number = intPart.length - 1;
    while (i >= 0) {
      out = intPart[i] + out;
      count += 1;
      if (count % 3 === 0 && i > 0) {
        out = ',' + out;
      }
      i -= 1;
    }
    return out;
  }

  static signed(cents: number, sign: boolean): string {
    const abs: number = Math.abs(cents);
    const yuan: string = Fmt.yuanStr(abs);
    const prefix: string = cents < 0 ? '-' : (sign && cents > 0 ? '+' : '');
    return prefix + yuan;
  }

  static yuanStr(cents: number): string {
    const abs: number = Math.abs(Math.round(cents));
    const intPart: number = Math.floor(abs / 100);
    const frac: number = abs % 100;
    const fracStr: string = frac < 10 ? '0' + frac.toString() : frac.toString();
    return Fmt.withCommas(intPart.toString()) + '.' + fracStr;
  }

  static signedMoney(cents: number, sign: boolean): string {
    const prefix: string = cents < 0 ? '-' : (sign && cents > 0 ? '+' : '');
    const abs: number = Math.abs(cents);
    if (abs >= 1000000) {
      return prefix + '¥' + (abs / 1000000).toFixed(2) + '万';
    }
    return prefix + '¥' + Fmt.yuanStr(abs);
  }

  static yuanStr2(cents: number, symbol: boolean): string {
    const pre: string = symbol ? '¥' : '';
    return pre + Fmt.yuanStr(Math.abs(cents));
  }

  static listAmount(cents: number, isIncome: boolean): string {
    return Fmt.signed(cents, isIncome);
  }

  static compact(cents: number, sign: boolean): string {
    const abs: number = Math.abs(cents);
    if (abs >= 1000000) {
      const wan: number = abs / 1000000;
      const prefix: string = cents < 0 ? '-' : (sign && cents > 0 ? '+' : '');
      return prefix + '¥' + wan.toFixed(2) + '万';
    }
    return Fmt.signed(cents, sign);
  }

  static compactYuan(cents: number): string {
    const abs: number = Math.abs(cents);
    if (abs >= 1000000) {
      const wan: number = abs / 1000000;
      return '¥' + wan.toFixed(2) + '万';
    }
    return '¥' + Fmt.yuanStr(abs);
  }

  static money(cents: number): string {
    const abs: number = Math.abs(cents);
    const pre: string = cents < 0 ? '-¥' : '¥';
    return pre + Fmt.yuanStr(abs);
  }

  static compactMoney(cents: number): string {
    const abs: number = Math.abs(cents);
    if (abs >= 1000000) {
      const pre: string = cents < 0 ? '-¥' : '¥';
      return pre + (abs / 1000000).toFixed(2) + '万';
    }
    return Fmt.money(cents);
  }
}
