import { SymRes, Theme } from '../model/Theme';
import { DisplayMode } from '../viewmodel/HomeVM';

@ComponentV2
export struct DisplayModeMenuPanel {
  @Param mode: DisplayMode = 'week';
  @Event onPickMode: (mode: DisplayMode) => void = (_m: DisplayMode) => {};

  @Builder
  private modeRow(mode: DisplayMode, label: string) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(Theme.fontBody)
        .fontColor(this.mode === mode ? Theme.cBrand : Theme.cText)
        .layoutWeight(1)
      if (this.mode === mode) {
        SymbolGlyph(SymRes.get('check'))
          .fontSize(16)
          .fontColor([Theme.cBrand])
      }
    }
    .width('100%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .borderRadius(10)
    .onClick(() => this.onPickMode(mode))
  }

  build() {
    Column({ space: 2 }) {
      this.modeRow('year', '按年')
      this.modeRow('month', '按月')
      this.modeRow('week', '按周')
    }
    .width(140)
    .padding(8)
    .backgroundColor(Theme.cCard)
    .borderRadius(16)
  }
}
