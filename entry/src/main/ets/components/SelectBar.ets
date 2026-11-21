import { SymRes, Theme } from '../model/Theme';

@ComponentV2
export struct SelectBar {
  @Param count: number = 0;
  @Param allSelected: boolean = false;
  @Event onClose: () => void = () => {};
  @Event onSelectAll: () => void = () => {};
  @Event onDelete: () => void = () => {};

  build() {
    Row({ space: 20 }) {
      SymbolGlyph(SymRes.get('close'))
        .fontSize(20)
        .fontColor([Theme.cText])
        .onClick(() => this.onClose())
      Row({ space: 6 }) {
        SymbolGlyph(SymRes.get(this.allSelected ? 'check_circle_fill' : 'circle'))
          .fontSize(18)
          .fontColor([this.allSelected ? Theme.cBrand : Theme.cText3])
        Text('全选')
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cText)
      }
      .onClick(() => this.onSelectAll())

      Blank()

      Text(this.count > 0 ? `删除 (${this.count})` : '删除')
        .fontSize(Theme.fontBody)
        .fontWeight(600)
        .fontColor(Theme.cRed)
        .onClick(() => this.onDelete())
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .backgroundColor(Theme.cCard)
    .borderRadius(26)
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
    .transition(TransitionEffect.translate({ y: 80 }).animation({ duration: 200 })
      .combine(TransitionEffect.OPACITY.animation({ duration: 200 })))
  }
}
