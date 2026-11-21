import { emitter } from '@kit.BasicServicesKit';
import { AssetAccount } from '../model/Models';
import { EVT_DATA_CHANGED, Store } from '../model/Rdb';
import { SymRes, Theme, Fmt } from '../model/Theme';
import { AssetCalc, AssetSummary } from '../viewmodel/AssetVM';

@ComponentV2
export struct AssetPage {
  @Local hidden: boolean = false;
  @Local summary: AssetSummary = new AssetSummary();
  @Local accounts: AssetAccount[] = [];
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
    this.accounts = store.accounts.slice(0);
    this.summary = AssetCalc.summary(store.accounts);
  }

  private netText(): string {
    if (this.hidden) {
      return '****';
    }
    return Fmt.compactMoney(this.summary.net);
  }

  @Builder
  smallCard(label: string, cents: number) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(Theme.fontAux)
        .fontColor(Theme.cText2)
      Text(Fmt.money(cents))
        .fontSize(Theme.fontBody)
        .fontWeight(600)
        .fontColor(Theme.cText)
    }
    .layoutWeight(1)
    .padding(10)
    .backgroundColor(Theme.cCard)
    .borderRadius(16)
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
      Column({ space: 12 }) {
        Text('资产')
          .fontSize(Theme.fontTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.cText)
          .width('100%')

        Column({ space: 8 }) {
          Row({ space: 10 }) {
            Text('净资产')
              .fontSize(Theme.fontBody)
              .fontWeight(600)
              .fontColor(Color.White)
            SymbolGlyph(SymRes.get(this.hidden ? 'eye_slash' : 'eye'))
              .fontSize(18)
              .fontColor([Color.White])
              .onClick(() => {
                this.hidden = !this.hidden;
              })
          }

          Text(this.netText())
            .fontSize(Theme.fontBigAmount)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .blur(this.hidden ? 12 : 0)
            .animation({ duration: 200 })

          Row() {
            Column({ space: 2 }) {
              Text('总资产')
                .fontSize(Theme.fontAux)
                .fontColor('#CCFFFFFF')
              Text(Fmt.money(this.summary.assets))
                .fontSize(Theme.fontAux)
                .fontColor(Color.White)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column({ space: 2 }) {
              Text('总负债')
                .fontSize(Theme.fontAux)
                .fontColor('#CCFFFFFF')
              Text(Fmt.money(this.summary.liabilities))
                .fontSize(Theme.fontAux)
                .fontColor(Color.White)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(Theme.cardPad)
        .borderRadius(20)
        .linearGradient({ angle: 135, colors: [['#9C8BFF', 0.0], ['#6C58D6', 1.0]] })

        Row({ space: 10 }) {
          this.smallCard('总借入', this.summary.borrowIn)
          this.smallCard('总借出', this.summary.lendOut)
          this.smallCard('总应收', this.summary.receivable)
        }
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Text('存款账户')
              .fontSize(Theme.fontBody)
              .fontWeight(600)
              .fontColor(Theme.cText)
            Blank()
            Text('余额合计 ' + Fmt.money(this.summary.assets))
              .fontSize(Theme.fontAux)
              .fontColor(Theme.cText2)
          }
          .width('100%')

          ForEach(this.accounts, (acc: AssetAccount) => {
            Row({ space: 12 }) {
              Stack() {
                SymbolGlyph(SymRes.get(acc.icon))
                  .fontSize(18)
                  .fontColor([Color.White])
              }
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor(acc.balance >= 0 ? Theme.cBrand : Theme.cRed)

              Column({ space: 2 }) {
                Text(acc.name)
                  .fontSize(Theme.fontBody)
                  .fontColor(Theme.cText)
                Text(acc.type === 'bank' ? '银行卡' : (acc.type === 'wechat' ? '微信' : '存款'))
                  .fontSize(Theme.fontAux)
                  .fontColor(Theme.cText2)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(Fmt.money(acc.balance))
                .fontSize(Theme.fontBody)
                .fontWeight(FontWeight.Bold)
                .fontColor(acc.balance >= 0 ? Theme.cText : Theme.cRed)

              SymbolGlyph(SymRes.get('chevron_right'))
                .fontSize(14)
                .fontColor([Theme.cText2])
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          }, (acc: AssetAccount): string => acc.id.toString())
        }
        .width('100%')
        .padding(Theme.cardPad)
        .backgroundColor(Theme.cCard)
        .borderRadius(Theme.cardRadius)
      }
      .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 10, bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }
}
