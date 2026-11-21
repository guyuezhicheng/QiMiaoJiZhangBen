import { SymRes, Theme } from '../model/Theme';

@ComponentV2
export struct NumberPad {
  @Event onPadKey: (key: string) => void = (_key: string) => {};
  @Event onAgain: () => void = () => {};
  @Event onDone: () => void = () => {};

  @Builder
  digitKey(label: string) {
    Text(label)
      .fontSize(20)
      .fontWeight(FontWeight.Medium)
      .fontColor(Theme.cText)
      .width('100%')
      .height('100%')
      .textAlign(TextAlign.Center)
      .onClick(() => this.onPadKey(label))
  }

  @Builder
  opKey(label: string, key: string) {
    Text(label)
      .fontSize(22)
      .fontWeight(FontWeight.Medium)
      .fontColor(Theme.cText)
      .width('100%')
      .height('100%')
      .textAlign(TextAlign.Center)
      .onClick(() => this.onPadKey(key))
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Column() { this.digitKey('1') }.layoutWeight(1).height(46)
        Column() { this.digitKey('2') }.layoutWeight(1).height(46)
        Column() { this.digitKey('3') }.layoutWeight(1).height(46)
        Column() {
          SymbolGlyph(SymRes.get('close'))
            .fontSize(20)
            .fontColor([Theme.cText])
        }
        .layoutWeight(1)
        .height(46)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onPadKey('del'))
      }
      .width('100%')

      Row({ space: 6 }) {
        Column() { this.digitKey('4') }.layoutWeight(1).height(46)
        Column() { this.digitKey('5') }.layoutWeight(1).height(46)
        Column() { this.digitKey('6') }.layoutWeight(1).height(46)
        Column() { this.opKey('−', 'minus') }.layoutWeight(1).height(46)
      }
      .width('100%')

      Row({ space: 6 }) {
        Column() { this.digitKey('7') }.layoutWeight(1).height(46)
        Column() { this.digitKey('8') }.layoutWeight(1).height(46)
        Column() { this.digitKey('9') }.layoutWeight(1).height(46)
        Column() { this.opKey('+', 'plus') }.layoutWeight(1).height(46)
      }
      .width('100%')

      Row({ space: 6 }) {
        Text('再记')
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cText)
          .layoutWeight(1)
          .height(46)
          .textAlign(TextAlign.Center)
          .onClick(() => this.onAgain())
        Column() { this.digitKey('0') }.layoutWeight(1).height(46)
        Column() { this.digitKey('.') }.layoutWeight(1).height(46)
        Text('完成')
          .fontSize(Theme.fontBody)
          .fontWeight(600)
          .fontColor(Color.White)
          .layoutWeight(1)
          .height(46)
          .textAlign(TextAlign.Center)
          .backgroundColor(Theme.cRed)
          .borderRadius(12)
          .onClick(() => this.onDone())
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 4, bottom: 12 })
  }
}
