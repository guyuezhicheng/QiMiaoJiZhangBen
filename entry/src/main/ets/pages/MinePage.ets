import { SymRes, Theme } from '../model/Theme';

class MineGridItem {
  label: string = '';
  icon: string = 'ellipsis_circle';

  constructor(label: string, icon: string) {
    this.label = label;
    this.icon = icon;
  }
}

const GRID_ITEMS: MineGridItem[] = [
  new MineGridItem('记账设置', 'gear'),
  new MineGridItem('预算管理', 'calculator'),
  new MineGridItem('模板记账', 'list_bullet'),
  new MineGridItem('周期记账', 'arrow_clockwise'),
  new MineGridItem('标签管理', 'label'),
  new MineGridItem('分类管理', 'grid'),
  new MineGridItem('账单导入', 'arrow_down_circle'),
  new MineGridItem('账单导出', 'arrow_up_circle'),
  new MineGridItem('资产管理', 'wallet'),
  new MineGridItem('债务管理', 'coins'),
  new MineGridItem('报销管理', 'doc_text'),
  new MineGridItem('证件管理', 'bookmark'),
  new MineGridItem('预算提醒', 'alarm'),
  new MineGridItem('记账提醒', 'bell'),
  new MineGridItem('搜索', 'search'),
  new MineGridItem('回收站', 'trash')
];

class SeqUtil {
  static strs(n: number): string[] {
    const out: string[] = [];
    for (let i: number = 0; i < n; i++) {
      out.push(i.toString());
    }
    return out;
  }
}

const SETTINGS: MineGridItem[] = [
  new MineGridItem('通用设置', 'gear'),
  new MineGridItem('记账设置', 'calculator'),
  new MineGridItem('数据备份', 'icloud'),
  new MineGridItem('提醒设置', 'bell'),
  new MineGridItem('帮助与反馈', 'question'),
  new MineGridItem('给我们好评', 'star'),
  new MineGridItem('分享给好友', 'share'),
  new MineGridItem('关于', 'heart')
];

@ComponentV2
export struct MinePage {
  @Local gridPage: number = 0;

  private pages(): MineGridItem[][] {
    const out: MineGridItem[][] = [];
    for (let i: number = 0; i < GRID_ITEMS.length; i += 8) {
      const end: number = Math.min(i + 8, GRID_ITEMS.length);
      out.push(GRID_ITEMS.slice(i, end));
    }
    return out;
  }

  private pageCount(): number {
    return Math.ceil(GRID_ITEMS.length / 8);
  }

  @Builder
  gridCell(item: MineGridItem) {
    Column({ space: 6 }) {
      Stack() {
        SymbolGlyph(SymRes.get(item.icon))
          .fontSize(20)
          .fontColor([Theme.cText])
      }
      .width(44)
      .height(44)
      .borderRadius(14)
      .backgroundColor(Theme.cChip)

      Text(item.label)
        .fontSize(Theme.fontAux)
        .fontColor(Theme.cText2)
        .maxLines(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  vipCard(title: string, sub: string, icon: string, c0: string, c1: string) {
    Row({ space: 10 }) {
      Stack() {
        SymbolGlyph(SymRes.get(icon))
          .fontSize(20)
          .fontColor([Color.White])
      }
      .width(36)
      .height(36)
      .borderRadius(12)
      .backgroundColor('#33FFFFFF')

      Column({ space: 2 }) {
        Text(title)
          .fontSize(Theme.fontBody)
          .fontWeight(600)
          .fontColor(Color.White)
        Text(sub)
          .fontSize(Theme.fontAux)
          .fontColor('#CCFFFFFF')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph(SymRes.get('chevron_right'))
        .fontSize(14)
        .fontColor([Color.White])
    }
    .width('100%')
    .padding(Theme.cardPad)
    .borderRadius(Theme.cardRadius)
    .linearGradient({ angle: 135, colors: [[c0, 0.0], [c1, 1.0]] })
  }

  @Builder
  settingRow(item: MineGridItem, showDivider: boolean) {
    Column() {
      Row({ space: 12 }) {
        SymbolGlyph(SymRes.get(item.icon))
          .fontSize(18)
          .fontColor([Theme.cText2])
        Text(item.label)
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cText)
          .layoutWeight(1)
        SymbolGlyph(SymRes.get('chevron_right'))
          .fontSize(14)
          .fontColor([Theme.cText3])
      }
      .width('100%')
      .height(46)

      if (showDivider) {
        Divider()
          .color(Theme.cDivider)
          .margin({ left: 30 })
      }
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Stack() {
            SymbolGlyph(SymRes.get('person'))
              .fontSize(28)
              .fontColor([Color.White])
          }
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor(Theme.cBrand)

          Column({ space: 4 }) {
            Text('奇妙记账本用户')
              .fontSize(Theme.fontBody)
              .fontWeight(600)
              .fontColor(Theme.cText)
            Text('点击登录，同步数据')
              .fontSize(Theme.fontAux)
              .fontColor(Theme.cText2)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph(SymRes.get('chevron_right'))
            .fontSize(14)
            .fontColor([Theme.cText3])
        }
        .width('100%')
        .padding(Theme.cardPad)

        Column({ space: 10 }) {
          Swiper() {
            ForEach(this.pages(), (page: MineGridItem[], pIdx: number) => {
              Grid() {
                ForEach(page, (item: MineGridItem) => {
                  GridItem() {
                    this.gridCell(item)
                  }
                }, (item: MineGridItem, idx: number): string => `${item.label}_${idx}`)
              }
              .columnsTemplate('1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr')
              .columnsGap(0)
              .rowsGap(0)
              .width('100%')
              .height(168)
            }, (page: MineGridItem[], pIdx: number): string => `page_${pIdx}`)
          }
          .index(this.gridPage)
          .indicator(false)
          .loop(false)
          .width('100%')
          .onChange((idx: number) => {
            this.gridPage = idx;
          })

          Row({ space: 6 }) {
            ForEach(SeqUtil.strs(this.pageCount()), (s: string) => {
              Circle()
                .width(Number(s) === this.gridPage ? 16 : 6)
                .height(6)
                .fill(Number(s) === this.gridPage ? Theme.cBrand : Theme.cDivider)
                .borderRadius(3)
                .animation({ duration: 200 })
            }, (s: string): string => s)
          }
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .backgroundColor(Theme.cCard)
        .borderRadius(Theme.cardRadius)

        this.vipCard('订阅会员', '解锁全部高级功能', 'diamond', '#F7B733', '#FC6A4F')
        this.vipCard('奇妙全家桶', '一次订阅，多款应用畅享', 'gift', '#9C8BFF', '#6C58D6')

        Column() {
          ForEach(SETTINGS, (item: MineGridItem, idx: number) => {
            this.settingRow(item, idx < SETTINGS.length - 1)
          }, (item: MineGridItem, idx: number): string => `${item.label}_${idx}`)
        }
        .width('100%')
        .padding({ left: Theme.cardPad, right: Theme.cardPad, top: 4, bottom: 4 })
        .backgroundColor(Theme.cCard)
        .borderRadius(Theme.cardRadius)

        Text('退出登录')
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cRed)
          .height(48)
          .width('100%')
          .textAlign(TextAlign.Center)
          .backgroundColor(Theme.cCard)
          .borderRadius(Theme.cardRadius)
          .onClick(() => {
            this.getUIContext().showAlertDialog({ message: '确定退出登录吗？' });
          })
      }
      .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 10, bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }
}
