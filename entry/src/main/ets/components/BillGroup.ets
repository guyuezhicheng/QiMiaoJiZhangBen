import { Bill, BillGroupModel } from '../model/Models';
import { SymRes, Theme, Fmt } from '../model/Theme';
import { BillItem } from './BillItem';

@ComponentV2
export struct BillGroup {
  @Param group: BillGroupModel = new BillGroupModel();
  @Param selectMode: boolean = false;
  @Param groupSelected: boolean = false;
  @Param selectedIds: number[] = [];
  @Event onHeaderTap: () => void = () => {};
  @Event onGroupCheckTap: () => void = () => {};
  @Event onBillTap: (id: number) => void = (_id: number) => {};
  @Event onBillLongPress: (id: number) => void = (_id: number) => {};

  private isBillSelected(bill: Bill): boolean {
    return this.selectedIds.indexOf(bill.id) >= 0;
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        if (this.selectMode) {
          Stack() {
            if (this.groupSelected) {
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
          .onClick(() => this.onGroupCheckTap())
        }
        Column({ space: 2 }) {
          Text(this.group.dateLabel)
            .fontSize(Theme.fontBody)
            .fontWeight(600)
            .fontColor(Theme.cText)
          Text(this.group.weekLabel)
            .fontSize(Theme.fontAux)
            .fontColor(Theme.cText2)
        }
        .alignItems(HorizontalAlign.Start)
        .onClick(() => this.onHeaderTap())

        Blank()

        if (this.group.expenseSum > 0) {
          Text('支出 ' + Fmt.signedMoney(-this.group.expenseSum, false))
            .fontSize(Theme.fontAux)
            .fontColor(Theme.cRed)
        }
        if (this.group.incomeSum > 0) {
          Text('收入 ' + Fmt.signedMoney(this.group.incomeSum, true))
            .fontSize(Theme.fontAux)
            .fontColor(Theme.cGreen)
        }
        SymbolGlyph(SymRes.get('chevron_down'))
          .fontSize(14)
          .fontColor([Theme.cText2])
          .rotate({ angle: this.group.collapsed ? -90 : 0 })
          .animation({ duration: 200 })
          .onClick(() => this.onHeaderTap())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })

      if (!this.group.collapsed) {
        Column() {
          ForEach(this.group.bills, (bill: Bill) => {
            BillItem({
              bill: bill,
              selectMode: this.selectMode,
              selected: this.isBillSelected(bill),
              onItemTap: () => this.onBillTap(bill.id),
              onItemLongPress: () => this.onBillLongPress(bill.id)
            })
          }, (bill: Bill): string => bill.id.toString())
        }
        .width('100%')
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }
    }
    .width('100%')
  }
}
