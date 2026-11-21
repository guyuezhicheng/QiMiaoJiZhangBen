import { Book } from '../model/Models';
import { SymRes, Theme } from '../model/Theme';

@ComponentV2
export struct BookMenuPanel {
  @Param books: Book[] = [];
  @Param currentBookId: number = 0;
  @Event onPickBook: (id: number) => void = (_id: number) => {};
  @Event onManageBooks: () => void = () => {};

  build() {
    Column({ space: 4 }) {
      ForEach(this.books, (book: Book) => {
        Row({ space: 8 }) {
          if (book.id === this.currentBookId) {
            SymbolGlyph(SymRes.get('check'))
              .fontSize(16)
              .fontColor([Theme.cBrand])
          } else {
            Stack()
              .width(16)
              .height(16)
          }
          Text(book.name)
            .fontSize(Theme.fontBody)
            .fontColor(book.id === this.currentBookId ? Theme.cBrand : Theme.cText)
        }
        .width('100%')
        .height(40)
        .padding({ left: 12, right: 12 })
        .borderRadius(10)
        .onClick(() => this.onPickBook(book.id))
      }, (book: Book): string => book.id.toString())

      Divider()
        .color(Theme.cDivider)
        .margin({ top: 4, bottom: 4 })

      Row({ space: 8 }) {
        SymbolGlyph(SymRes.get('gear'))
          .fontSize(16)
          .fontColor([Theme.cText2])
        Text('管理账本')
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cText)
        Blank()
        SymbolGlyph(SymRes.get('chevron_right'))
          .fontSize(14)
          .fontColor([Theme.cText2])
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .borderRadius(10)
      .onClick(() => this.onManageBooks())
    }
    .width(200)
    .padding(8)
    .backgroundColor(Theme.cCard)
    .borderRadius(16)
    .border({ width: 0.5, color: Theme.cGlassBorder })
    .shadow({ radius: 24, color: '#1F000000', offsetX: 0, offsetY: 8 })
  }
}
