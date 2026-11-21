import { emitter } from '@kit.BasicServicesKit';
import { BarPointModel, CatStatRow, SummaryRowModel } from '../model/Models';
import { EVT_DATA_CHANGED, Store } from '../model/Rdb';
import { SymRes, Theme, Fmt } from '../model/Theme';
import { DateUtil, DisplayMode, HomePeriod, PeriodRange } from '../viewmodel/HomeVM';
import { StatCalc, StatMode, StatSummary } from '../viewmodel/StatVM';
import { BarChart } from '../components/BarChart';
import { DonutChart } from '../components/DonutChart';
import { DonutSegment } from '../model/Models';
import { WheelDatePicker } from '../components/WheelDatePicker';

const STAT_TABS: string[] = ['按周', '按月', '按年', '范围'];
const STAT_MODES: StatMode[] = ['week', 'month', 'year', 'range'];

@ComponentV2
export struct StatisticsPage {
  @Local statMode: StatMode = 'week';
  @Local anchor: number = Date.now();
  @Local rangeStart: number = Date.now() - 6 * 86400000;
  @Local rangeEnd: number = Date.now() + 86400000;
  @Local showStartPicker: boolean = false;
  @Local showEndPicker: boolean = false;
  @Local collapseSummary: boolean = false;
  @Local contentFlip: boolean = false;
  @Local summary: StatSummary = new StatSummary();
  @Local barPoints: BarPointModel[] = [];
  @Local barMode: string = 'expense';
  @Local detailMode: string = 'expense';
  @Local catRows: CatStatRow[] = [];
  @Local tableData: SummaryRowModel[] = [];
  @Param refreshTick: number = 0;

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

  private currentRange(): PeriodRange {
    const mode: StatMode = this.statMode;
    if (mode === 'range') {
      return new PeriodRange(this.rangeStart, this.rangeEnd);
    }
    return HomePeriod.rangeOf(mode, this.anchor);
  }

  private rebuild(): void {
    const store: Store = Store.get();
    const range: PeriodRange = this.currentRange();
    const dm: DisplayMode = this.statMode === 'range' ? 'week' : this.statMode;
    this.summary = StatCalc.summary(store.bills, range.start, range.end);
    this.barPoints = StatCalc.weekdayBars(store.bills, range.start, range.end);
    this.catRows = StatCalc.categoryStats(store.bills, this.detailMode, range.start, range.end);
    this.tableData = StatCalc.tableRows(store.bills, dm, range.start, range.end);
  }

  private statIdx(): number {
    const idx: number = STAT_MODES.indexOf(this.statMode);
    return idx < 0 ? 0 : idx;
  }

  private pickMode(idx: number): void {
    const target: StatMode = STAT_MODES[idx];
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.statMode = target;
    });
    this.rebuild();
  }

  private periodTitle(): string {
    if (this.statMode === 'range') {
      return `${DateUtil.dateLabel(this.rangeStart)} - ${DateUtil.dateLabel(this.rangeEnd - 86400000)}`;
    }
    return HomePeriod.title(this.statMode, this.anchor);
  }

  private move(dir: number): void {
    const mode: StatMode = this.statMode;
    if (mode === 'range') {
      this.rangeStart += dir * 86400000;
      this.rangeEnd += dir * 86400000;
    } else {
      this.anchor = HomePeriod.step(mode, this.anchor, dir);
    }
    this.rebuild();
  }

  private days(): number {
    const range: PeriodRange = this.currentRange();
    return Math.max(1, Math.round((range.end - range.start) / 86400000));
  }

  private avgRowLabel(): string {
    if (this.statMode === 'year') {
      return '月均';
    }
    return '日均';
  }

  private avgExpense(): number {
    const div: number = this.statMode === 'year' ? 12 : this.days();
    return Math.round(this.summary.expense / div);
  }

  private totalExpense(): number {
    let t: number = 0;
    for (let i: number = 0; i < this.tableData.length; i++) {
      t += this.tableData[i].expense;
    }
    return t;
  }

  private totalIncome(): number {
    let t: number = 0;
    for (let i: number = 0; i < this.tableData.length; i++) {
      t += this.tableData[i].income;
    }
    return t;
  }

  private donutSegments(): DonutSegment[] {
    const out: DonutSegment[] = [];
    for (let i: number = 0; i < this.catRows.length; i++) {
      const r: CatStatRow = this.catRows[i];
      out.push(new DonutSegment(r.name, r.amount, r.color));
    }
    return out;
  }

  private donutCenter(): string {
    let t: number = 0;
    for (let i: number = 0; i < this.catRows.length; i++) {
      t += this.catRows[i].amount;
    }
    return Fmt.compactYuan(t);
  }

  @Builder
  sectionTitle(label: string) {
    Row({ space: 6 }) {
      Column()
        .width(4)
        .height(14)
        .borderRadius(2)
        .backgroundColor(Theme.cBrand)
      Text(label)
        .fontSize(Theme.fontBody)
        .fontWeight(600)
        .fontColor(Theme.cText)
    }
  }

  @Builder
  summaryCard() {
    Column() {
      Row() {
        this.sectionTitle('收支统计')
        Blank()
        SymbolGlyph(SymRes.get(this.collapseSummary ? 'chevron_right' : 'chevron_down'))
          .fontSize(14)
          .fontColor([Theme.cText2])
          .onClick(() => {
            this.collapseSummary = !this.collapseSummary;
          })
      }
      .width('100%')

      if (!this.collapseSummary) {
        Column() {
          Row() {
            Column({ space: 4 }) {
              Text('支出')
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText2)
              Text(Fmt.compact(this.summary.expense, false))
                .fontSize(Theme.fontBody)
                .fontWeight(600)
                .fontColor(Theme.cText)
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .padding({ top: 8, bottom: 8 })
            Column({ space: 4 }) {
              Text('收入')
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText2)
              Text(Fmt.compact(this.summary.income, true))
                .fontSize(Theme.fontBody)
                .fontWeight(600)
                .fontColor(Theme.cGreen)
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .padding({ top: 8, bottom: 8 })
          }
          .width('100%')
          Row() {
            Column({ space: 4 }) {
              Text('结余')
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText2)
              Text(Fmt.compact(this.summary.balance, true))
                .fontSize(Theme.fontBody)
                .fontWeight(600)
                .fontColor(this.summary.balance >= 0 ? Theme.cGreen : Theme.cRed)
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .padding({ top: 8, bottom: 8 })
            Column({ space: 4 }) {
              Text('日均支出')
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText2)
              Text(Fmt.compact(this.summary.dayAvg, false))
                .fontSize(Theme.fontBody)
                .fontWeight(600)
                .fontColor(Theme.cText)
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .padding({ top: 8, bottom: 8 })
          }
          .width('100%')
          Row() {
            Column({ space: 4 }) {
              Text('不计收支')
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText2)
              Text(Fmt.compact(this.summary.excludeStat, false))
                .fontSize(Theme.fontBody)
                .fontWeight(600)
                .fontColor(Theme.cText)
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .padding({ top: 8, bottom: 8 })
            Column({ space: 4 }) {
              Text('不计预算')
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText2)
              Text(Fmt.compact(this.summary.excludeBudget, false))
                .fontSize(Theme.fontBody)
                .fontWeight(600)
                .fontColor(Theme.cText)
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .padding({ top: 8, bottom: 8 })
          }
          .width('100%')
        }
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }
    }
    .width('100%')
    .padding(Theme.cardPad)
    .backgroundColor(Theme.cCard)
    .borderRadius(Theme.cardRadius)
  }

  @Builder
  refundCard() {
    Row() {
      Column({ space: 4 }) {
        Text('待报销')
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
        Text(Fmt.compact(this.summary.pendingRefund, false))
          .fontSize(Theme.fontBody)
          .fontWeight(600)
          .fontColor(Theme.cOrange)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ top: 8, bottom: 8 })
      Column({ space: 4 }) {
        Text('报销入账')
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
        Text(Fmt.compact(this.summary.refunded, false))
          .fontSize(Theme.fontBody)
          .fontWeight(600)
          .fontColor(Theme.cGreen)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ top: 8, bottom: 8 })
    }
    .width('100%')
    .padding({ left: Theme.cardPad, right: Theme.cardPad, top: 4, bottom: 4 })
    .backgroundColor(Theme.cCard)
    .borderRadius(Theme.cardRadius)
  }

  @Builder
  chartCard() {
    Column({ space: 10 }) {
      Row() {
        this.sectionTitle('支出统计图')
        Blank()
        Text('↕ 不排除退款报销')
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
      }
      .width('100%')

      BarChart({ points: this.barPoints, mode: this.barMode })

      Row({ space: 4 }) {
        Text('支出')
          .fontSize(Theme.fontAux)
          .fontWeight(this.barMode === 'expense' ? 600 : FontWeight.Normal)
          .fontColor(this.barMode === 'expense' ? Theme.cText : Theme.cText2)
          .height(28)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.barMode === 'expense' ? Theme.cCard : Color.Transparent)
          .borderRadius(14)
          .onClick(() => {
            this.barMode = 'expense';
          })
        Text('收入')
          .fontSize(Theme.fontAux)
          .fontWeight(this.barMode === 'income' ? 600 : FontWeight.Normal)
          .fontColor(this.barMode === 'income' ? Theme.cText : Theme.cText2)
          .height(28)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.barMode === 'income' ? Theme.cCard : Color.Transparent)
          .borderRadius(14)
          .onClick(() => {
            this.barMode = 'income';
          })
      }
      .backgroundColor(Theme.cChip)
      .borderRadius(14)
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(Theme.cardPad)
    .backgroundColor(Theme.cCard)
    .borderRadius(Theme.cardRadius)
  }

  @Builder
  detailCard() {
    Column({ space: 10 }) {
      Row() {
        this.sectionTitle('支出详情')
        Blank()
        Text('支出')
          .fontSize(Theme.fontAux)
          .fontWeight(this.detailMode === 'expense' ? 600 : FontWeight.Normal)
          .fontColor(this.detailMode === 'expense' ? Theme.cText : Theme.cText2)
          .height(28)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.detailMode === 'expense' ? Theme.cCard : Color.Transparent)
          .borderRadius(14)
          .onClick(() => {
            this.detailMode = 'expense';
            this.rebuild();
          })
        Text('收入')
          .fontSize(Theme.fontAux)
          .fontWeight(this.detailMode === 'income' ? 600 : FontWeight.Normal)
          .fontColor(this.detailMode === 'income' ? Theme.cText : Theme.cText2)
          .height(28)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.detailMode === 'income' ? Theme.cCard : Color.Transparent)
          .borderRadius(14)
          .onClick(() => {
            this.detailMode = 'income';
            this.rebuild();
          })
      }
      .width('100%')

      DonutChart({ segments: this.donutSegments(), centerText: this.donutCenter() })

      ForEach(this.catRows, (row: CatStatRow) => {
        Row({ space: 10 }) {
          Stack() {
            SymbolGlyph(SymRes.get(row.icon))
              .fontSize(16)
              .fontColor([Color.White])
          }
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor(row.color)

          Column({ space: 4 }) {
            Text(row.name)
              .fontSize(Theme.fontAux)
              .fontColor(Theme.cText)
            Stack({ alignContent: Alignment.Start }) {
              Column()
                .width(`${Math.round(row.percent * 100)}%`)
                .height(6)
                .borderRadius(3)
                .backgroundColor(row.color)
            }
            .width('100%')
            .height(6)
            .backgroundColor(Theme.cDivider)
            .borderRadius(3)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(`${Math.round(row.percent * 100)}%  ${Fmt.compactYuan(row.amount)}`)
            .fontSize(Theme.fontAux)
            .fontColor(Theme.cText2)
        }
        .width('100%')
      }, (row: CatStatRow, idx: number): string =>
        `${row.name}_${idx}_${row.amount}_${Math.round(row.percent * 100)}`)

      Text('二级分类')
        .fontSize(Theme.fontAux)
        .fontColor(Theme.cBrand)
        .alignSelf(ItemAlign.End)
    }
    .width('100%')
    .padding(Theme.cardPad)
    .backgroundColor(Theme.cCard)
    .borderRadius(Theme.cardRadius)
  }

  @Builder
  tableHeadCell(label: string) {
    Text(label)
      .fontSize(Theme.fontAux)
      .fontColor(Theme.cText2)
      .layoutWeight(1)
      .textAlign(TextAlign.End)
  }

  @Builder
  tableBodyCell(value: string, color: ResourceColor) {
    Text(value)
      .fontSize(Theme.fontAux)
      .fontColor(color)
      .layoutWeight(1)
      .textAlign(TextAlign.End)
      .maxLines(1)
  }

  @Builder
  summaryTable() {
    Column({ space: 6 }) {
      Row() {
        this.sectionTitle('账单汇总')
        Blank()
        Text(this.periodTitle())
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
      }
      .width('100%')
      .padding({ bottom: 4 })

      Row() {
        Text('日期')
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
          .layoutWeight(1)
        this.tableHeadCell('支出')
        this.tableHeadCell('收入')
        this.tableHeadCell('结余')
      }
      .width('100%')
      .padding({ bottom: 2 })
      .border({ width: { bottom: 1 }, color: Theme.cDivider })

      ForEach(this.tableData, (row: SummaryRowModel, idx: number) => {
        Row() {
          Text(row.label)
            .fontSize(Theme.fontAux)
            .fontColor(Theme.cText)
            .layoutWeight(1)
          this.tableBodyCell(Fmt.compact(row.expense, false), Theme.cText)
          this.tableBodyCell(Fmt.compact(row.income, true), Theme.cGreen)
          this.tableBodyCell(Fmt.compact(row.balance, true), row.balance >= 0 ? Theme.cGreen : Theme.cRed)
        }
        .width('100%')
      }, (row: SummaryRowModel, idx: number): string => `${row.label}_${idx}_${row.expense}_${row.income}`)

      Row() {
        Text('总计')
          .fontSize(Theme.fontAux)
          .fontWeight(600)
          .fontColor(Theme.cText)
          .layoutWeight(1)
        Text(Fmt.compact(this.totalExpense(), false))
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
        Text(Fmt.compact(this.totalIncome(), true))
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cGreen)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
        Text(Fmt.compact(this.totalIncome() - this.totalExpense(), true))
          .fontSize(Theme.fontAux)
          .fontColor(this.totalIncome() - this.totalExpense() >= 0 ? Theme.cGreen : Theme.cRed)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
      }
      .width('100%')
      .padding({ top: 4 })
      .border({ width: { top: 1 }, color: Theme.cDivider })

      Row() {
        Text(this.avgRowLabel())
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText2)
          .layoutWeight(1)
        Text(Fmt.compact(this.avgExpense(), false))
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
        Text(Fmt.compact(Math.round(this.totalIncome() /
          (this.statMode === 'year' ? 12 : this.days())), true))
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cGreen)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
        this.tableBodyCell('--', Theme.cText2)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Theme.cardPad)
    .backgroundColor(Theme.cCard)
    .borderRadius(Theme.cardRadius)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.contentFlip) {
        this.pageContent()
      } else {
        this.pageContent()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  pageContent() {
    Scroll() {
        Column({ space: 12 }) {
          Text('统计')
            .fontSize(Theme.fontTitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.cText)
            .width('100%')

          Stack({ alignContent: Alignment.Start }) {
            Column()
              .width('25%')
              .height(32)
              .borderRadius(16)
              .backgroundColor(Theme.cCard)
              .translate({ x: `${this.statIdx() * 100}%` })
              .animation({ duration: 250, curve: Curve.EaseOut })
            Row() {
              ForEach(STAT_TABS, (label: string, idx: number) => {
                Text(label)
                  .fontSize(Theme.fontAux)
                  .fontWeight(this.statIdx() === idx ? 600 : FontWeight.Normal)
                  .fontColor(this.statIdx() === idx ? Theme.cText : Theme.cText2)
                  .height(32)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .onClick(() => this.pickMode(idx))
              }, (label: string): string => label)
            }
            .width('100%')
          }
          .width('100%')
          .height(36)
          .padding({ left: 2, right: 2 })
          .backgroundColor(Theme.cChip)
          .borderRadius(18)

          if (this.statMode === 'range') {
            Row({ space: 8 }) {
              Text(DateUtil.dateLabel(this.rangeStart))
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText)
                .height(28)
                .padding({ left: 12, right: 12 })
                .backgroundColor(Theme.cChip)
                .borderRadius(14)
                .onClick(() => {
                  this.showStartPicker = !this.showStartPicker;
                })
              Text('至')
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText2)
              Text(DateUtil.dateLabel(this.rangeEnd - 86400000))
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText)
                .height(28)
                .padding({ left: 12, right: 12 })
                .backgroundColor(Theme.cChip)
                .borderRadius(14)
                .onClick(() => {
                  this.showEndPicker = !this.showEndPicker;
                })
              Blank()
            }
            .width('100%')
          } else {
            Row({ space: 6 }) {
              Text(this.periodTitle())
                .fontSize(Theme.fontBody)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.cText)
              SymbolGlyph(SymRes.get('chevron_left'))
                .fontSize(18)
                .fontColor([Theme.cText2])
                .onClick(() => this.move(-1))
              SymbolGlyph(SymRes.get('chevron_right'))
                .fontSize(18)
                .fontColor([Theme.cText2])
                .onClick(() => this.move(1))
              Blank()
            }
            .width('100%')
          }

          this.summaryCard()
          this.refundCard()
          this.chartCard()
          this.detailCard()
          this.summaryTable()
        }
        .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 10, bottom: 120 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)

      if (this.showStartPicker || this.showEndPicker) {
        Column() {
          WheelDatePicker({
            currentTime: this.showStartPicker ? this.rangeStart : this.rangeEnd,
            onPickOk: (t: number) => {
              if (this.showStartPicker) {
                this.rangeStart = t;
                if (this.rangeStart > this.rangeEnd) {
                  this.rangeEnd = this.rangeStart + 86400000;
                }
              } else {
                this.rangeEnd = t + 86400000;
                if (this.rangeEnd < this.rangeStart) {
                  this.rangeStart = this.rangeEnd - 86400000;
                }
              }
              this.showStartPicker = false;
              this.showEndPicker = false;
              this.rebuild();
            },
            onPickCancel: () => {
              this.showStartPicker = false;
              this.showEndPicker = false;
            }
          })
        }
        .width('100%')
        .padding({ left: Theme.pagePad, right: Theme.pagePad, bottom: 96 })
        .transition(TransitionEffect.translate({ y: 60 }).animation({ duration: 250 })
          .combine(TransitionEffect.OPACITY.animation({ duration: 250 })))
      }
  }
}
