import { emitter } from '@kit.BasicServicesKit';
import { Bill } from '../model/Models';
import { EVT_DATA_CHANGED, Store } from '../model/Rdb';
import { SymRes, Theme, Fmt } from '../model/Theme';
import { DateUtil } from '../viewmodel/HomeVM';
import { BillItem } from '../components/BillItem';

export class CalCell {
  day: number = 0;
  inMonth: boolean = false;
  isToday: boolean = false;
  key: string = '';
  net: number = 0;
}

@ComponentV2
export struct CalendarPage {
  @Local calYear: number = new Date().getFullYear();
  @Local calMonth: number = new Date().getMonth();
  @Local cells: CalCell[] = [];
  @Local selectedKey: string = DateUtil.dateKey(Date.now());
  @Local dayBills: Bill[] = [];
  @Param refreshTick: number = 0;
  @Local contentFlip: boolean = false;

  @Monitor('refreshTick')
  onRefreshTick(): void {
    setTimeout(() => {
      this.rebuild();
      this.contentFlip = !this.contentFlip;
    }, 500);
    setTimeout(() => {
      this.rebuild();
      this.contentFlip = !this.contentFlip;
    }, 1000);
  }

  private dataCallback = (event: emitter.EventData): void => {
    this.rebuild();
  };

  aboutToAppear(): void {
    emitter.on({ eventId: EVT_DATA_CHANGED }, this.dataCallback);
    Store.get().ensureInited(getContext(this)).then(() => {
      this.rebuild();
    });
    this.rebuild();
  }

  aboutToDisappear(): void {
    emitter.off(EVT_DATA_CHANGED, this.dataCallback);
  }

  private rebuild(): void {
    const store: Store = Store.get();
    const first: Date = new Date(this.calYear, this.calMonth, 1);
    const start: Date = new Date(this.calYear, this.calMonth, 1 - first.getDay());
    const todayKey: string = DateUtil.dateKey(Date.now());
    const out: CalCell[] = [];
    for (let i: number = 0; i < 42; i++) {
      const d: Date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
      const key: string = DateUtil.dateKey(d.getTime());
      let net: number = 0;
      for (let j: number = 0; j < store.bills.length; j++) {
        const b: Bill = store.bills[j];
        if (DateUtil.dateKey(b.occurTime) === key) {
          if (b.type === 'income') {
            net += b.amount;
          } else if (b.type === 'expense') {
            net -= b.amount;
          }
        }
      }
      const cell: CalCell = new CalCell();
      cell.day = d.getDate();
      cell.inMonth = d.getMonth() === this.calMonth;
      cell.isToday = key === todayKey;
      cell.key = key;
      cell.net = net;
      out.push(cell);
    }
    this.cells = out;
    this.dayBills = store.bills.filter((b: Bill): boolean =>
      DateUtil.dateKey(b.occurTime) === this.selectedKey);
  }

  private shiftMonth(dir: number): void {
    const d: Date = new Date(this.calYear, this.calMonth + dir, 1);
    this.calYear = d.getFullYear();
    this.calMonth = d.getMonth();
    this.rebuild();
  }

  private netText(cell: CalCell): string {
    if (cell.net === 0) {
      return '';
    }
    return Fmt.signed(cell.net, cell.net > 0);
  }

  private monthTitle(): string {
    const m: string = this.calMonth + 1 < 10 ? '0' + (this.calMonth + 1).toString() : (this.calMonth + 1).toString();
    return `${this.calYear}年${m}月`;
  }

  private selectedLabel(): string {
    const parts: string[] = this.selectedKey.split('-');
    if (parts.length < 3) {
      return this.selectedKey;
    }
    return `${parseInt(parts[1])}月${parseInt(parts[2])}日 ${DateUtil.weekLabel(new Date(this.selectedKey).getTime())}`;
  }

  build() {
    if (this.contentFlip) {
      this.pageContent()
    } else {
      this.pageContent()
    }
  }

  @Builder
  pageContent() {
    Scroll() {
      Column() {
        Row({ space: 8 }) {
          Text(this.monthTitle())
            .fontSize(Theme.fontTitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.cText)
          Row({ space: 8 }) {
            Stack() {
              SymbolGlyph(SymRes.get('chevron_left'))
                .fontSize(16)
                .fontColor([Theme.cText2])
            }
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor(Theme.cCard)
            .shadow({ radius: 8, color: Theme.cGlassShadow, offsetX: 0, offsetY: 2 })
            .onClick(() => this.shiftMonth(-1))

            Stack() {
              SymbolGlyph(SymRes.get('chevron_right'))
                .fontSize(16)
                .fontColor([Theme.cText2])
            }
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor(Theme.cCard)
            .shadow({ radius: 8, color: Theme.cGlassShadow, offsetX: 0, offsetY: 2 })
            .onClick(() => this.shiftMonth(1))
          }
          .margin({ left: 10 })

          Blank()
        }
        .width('100%')
        .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 10, bottom: 8 })

      Row() {
        ForEach(['日', '一', '二', '三', '四', '五', '六'], (w: string) => {
          Text(w)
            .fontSize(Theme.fontAux)
            .fontColor(Theme.cText2)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }, (w: string): string => w)
      }
      .width('100%')
      .padding({ left: Theme.pagePad, right: Theme.pagePad, bottom: 6 })

      Grid() {
        ForEach(this.cells, (cell: CalCell) => {
          GridItem() {
            Column({ space: 2 }) {
              Stack() {
                if (cell.isToday) {
                  Circle()
                    .width(28)
                    .height(28)
                    .fill(Theme.cBrand)
                }
                Text(cell.day.toString())
                  .fontSize(Theme.fontBody)
                  .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(cell.isToday ? Color.White : (cell.inMonth ? Theme.cText : Theme.cText3))
              }
              .width(30)
              .height(30)
              if (this.netText(cell).length > 0) {
                Text(this.netText(cell))
                  .fontSize(9)
                  .fontColor(cell.net > 0 ? Theme.cGreen : Theme.cRed)
                  .maxLines(1)
              }
            }
            .width('100%')
            .height(52)
            .justifyContent(FlexAlign.Center)
            .borderRadius(12)
            .border({
              width: cell.key === this.selectedKey ? 1.5 : 0,
              color: Theme.cBrand
            })
            .onClick(() => {
              this.selectedKey = cell.key;
              this.rebuild();
            })
          }
        }, (cell: CalCell): string => cell.key + '_' + cell.net + (cell.isToday ? '_t' : ''))
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
      .width('100%')
      .height(340)
      .padding({ left: Theme.pagePad, right: Theme.pagePad })

      Row()
        .width('100%')
        .height(6)
        .backgroundColor(Theme.cDivider)
        .margin({ top: 8, bottom: 8 })

      Text(this.selectedLabel())
        .fontSize(Theme.fontBody)
        .fontWeight(600)
        .fontColor(Theme.cText)
        .width('100%')
        .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 4, bottom: 4 })

      if (this.dayBills.length === 0) {
        Column() {
          Text('暂无账单')
            .fontSize(Theme.fontBody)
            .fontColor(Theme.cText2)
        }
        .width('100%')
        .height(160)
        .justifyContent(FlexAlign.Center)
      } else {
        Column({ space: 4 }) {
          ForEach(this.dayBills, (bill: Bill) => {
            BillItem({ bill: bill })
          }, (bill: Bill): string => bill.id.toString())
        }
        .width('100%')
        .padding({ left: Theme.pagePad, right: Theme.pagePad })
      }
      }
      .width('100%')
      .padding({ bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }
}
