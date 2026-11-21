import { Bill, Category } from '../model/Models';
import { CategoryData } from '../model/CategoryData';
import { Store } from '../model/Rdb';
import { SymRes, Theme, Fmt } from '../model/Theme';
import { DateUtil } from '../viewmodel/HomeVM';

@ComponentV2
export struct BillItem {
  @Param bill: Bill = new Bill();
  @Param selectMode: boolean = false;
  @Param selected: boolean = false;
  @Event onItemTap: () => void = () => {};
  @Event onItemLongPress: () => void = () => {};

  private catOf(): Category {
    const store: Store = Store.get();
    const id: string = this.bill.subId !== '' ? this.bill.subId : this.bill.categoryId;
    return CategoryData.findCategory(store.categories, id);
  }

  private amountText(): string {
    if (this.bill.type === 'income') {
      return Fmt.signedMoney(this.bill.amount, true);
    }
    return Fmt.signedMoney(-this.bill.amount, false);
  }

  private amountColor(): ResourceColor {
    if (this.bill.type === 'income') {
      return Theme.cGreen;
    }
    return Theme.cRed;
  }

  private timeText(): string {
    return DateUtil.hhmm(this.bill.occurTime);
  }

  build() {
    Row({ space: 10 }) {
      if (this.selectMode) {
        Stack() {
          if (this.selected) {
            SymbolGlyph(SymRes.get('check_circle_fill'))
              .fontSize(22)
              .fontColor([Theme.cBrand])
          } else {
            SymbolGlyph(SymRes.get('circle'))
              .fontSize(22)
              .fontColor([Theme.cText3])
          }
        }
        .width(22)
        .height(22)
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 })
          .combine(TransitionEffect.scale({ x: 0.6, y: 0.6 }).animation({ duration: 200 })))
      }
      Stack() {
        SymbolGlyph(SymRes.get(this.catOf().icon))
          .fontSize(20)
          .fontColor([Color.White])
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.catOf().color)

      Column({ space: 3 }) {
        Text(this.catOf().name)
          .fontSize(Theme.fontBody)
          .fontWeight(600)
          .fontColor(Theme.cText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.timeText() + (this.bill.remark.length > 0 ? ' · ' + this.bill.remark : ''))
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.bill.tags.length > 0) {
          Row({ space: 6 }) {
            ForEach(this.bill.tags, (tag: string) => {
              Text(tag)
                .fontSize(10)
                .fontColor(Theme.cOrange)
                .backgroundColor('#1AFAAD14')
                .borderRadius(8)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            }, (tag: string): string => tag)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 3 }) {
        Text(this.amountText())
          .fontSize(Theme.fontListAmount)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.amountColor())
        Text(this.bill.account)
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .borderRadius(Theme.cardRadius)
    .backgroundColor(this.selected ? Theme.cBrandLight : Color.Transparent)
    .onClick(() => this.onItemTap())
    .gesture(LongPressGesture({ fingers: 1, repeat: false, duration: 400 })
      .onAction(() => {
        this.onItemLongPress();
      }))
  }
}
