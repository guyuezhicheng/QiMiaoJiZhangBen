import { SymRes, Theme } from '../model/Theme';

export class WdpConst {
  static readonly months: string[] =
    ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static readonly monthFull: string[] =
    ['January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'];
  static readonly weeks: string[] =
    ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static readonly yearStart: number = 2021;
  static readonly yearEnd: number = 2028;
}

@ComponentV2
export struct WheelDatePicker {
  @Param currentTime: number = Date.now();
  @Event onPickOk: (time: number) => void = (_t: number) => {};
  @Event onPickCancel: () => void = () => {};

  @Local mIdx: number = 0;
  @Local dIdx: number = 0;
  @Local yIdx: number = 0;

  aboutToAppear(): void {
    const d: Date = new Date(this.currentTime);
    this.mIdx = d.getMonth();
    this.dIdx = d.getDate() - 1;
    this.yIdx = d.getFullYear() - WdpConst.yearStart;
  }

  private dayCount(): number {
    const y: number = WdpConst.yearStart + this.yIdx;
    return new Date(y, this.mIdx + 1, 0).getDate();
  }

  private titleText(): string {
    const y: number = WdpConst.yearStart + this.yIdx;
    const day: number = Math.min(this.dIdx + 1, this.dayCount());
    const wd: Date = new Date(y, this.mIdx, day);
    return `${WdpConst.weeks[wd.getDay()]}, ${day} ${WdpConst.monthFull[this.mIdx]} ${y}`;
  }

  private daysRange(): string[] {
    const list: string[] = [];
    const n: number = this.dayCount();
    for (let i: number = 1; i <= n; i++) {
      list.push(i.toString());
    }
    return list;
  }

  private yearsRange(): string[] {
    const list: string[] = [];
    for (let y: number = WdpConst.yearStart; y <= WdpConst.yearEnd; y++) {
      list.push(y.toString());
    }
    return list;
  }

  build() {
    Column({ space: 10 }) {
      Text(this.titleText())
        .fontSize(Theme.fontBody)
        .fontWeight(600)
        .fontColor(Theme.cText)

      Row({ space: 8 }) {
        TextPicker({ range: WdpConst.months, selected: this.mIdx })
          .canLoop(true)
          .defaultPickerItemHeight(44)
          .layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            this.mIdx = typeof index === 'number' ? index : 0;
            if (this.dIdx + 1 > this.dayCount()) {
              this.dIdx = this.dayCount() - 1;
            }
          })
        TextPicker({ range: this.daysRange(), selected: this.dIdx })
          .canLoop(false)
          .defaultPickerItemHeight(44)
          .layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            this.dIdx = typeof index === 'number' ? index : 0;
          })
        TextPicker({ range: this.yearsRange(), selected: this.yIdx })
          .canLoop(false)
          .defaultPickerItemHeight(44)
          .layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            this.yIdx = typeof index === 'number' ? index : 0;
            if (this.dIdx + 1 > this.dayCount()) {
              this.dIdx = this.dayCount() - 1;
            }
          })
      }
      .width('100%')
      .height(160)

      Row() {
        Text('Cancel')
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cText2)
          .height(40)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => this.onPickCancel())
        Divider()
          .vertical(true)
          .height(24)
          .color(Theme.cDivider)
        Text('OK')
          .fontSize(Theme.fontBody)
          .fontWeight(600)
          .fontColor(Theme.cBrand)
          .height(40)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            const y: number = WdpConst.yearStart + this.yIdx;
            const day: number = Math.min(this.dIdx + 1, this.dayCount());
            this.onPickOk(new Date(y, this.mIdx, day, 12, 0, 0).getTime());
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Theme.cCard)
    .borderRadius(20)
  }
}
