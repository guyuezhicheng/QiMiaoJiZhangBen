import { HomePage } from './HomePage';
import { CalendarPage } from './CalendarPage';
import { AssetPage } from './AssetPage';
import { StatisticsPage } from './StatisticsPage';
import { MinePage } from './MinePage';
import { BillSheet } from '../components/BillSheet';
import { SymRes, Theme } from '../model/Theme';
import { HdsTabs, DividerMode, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier, curves } from '@kit.ArkUI';

const TAB_ICONS: string[] = ['house', 'calendar', 'creditcard', 'data_line', 'person'];
const TAB_LABELS: string[] = ['首页', '日历', '资产', '统计', '我的'];
const HDS_BAR_H: number = 56;
const HDS_BAR_BOTTOM: number = 24;
const HDS_BAR_W: number = 328;
const HDS_ITEM_PAD: number = 12;
const HDS_ITEM_W: number = 60.8;
const CAP_W: number = 54;
const CAP_H: number = 44;
const FAB_RIGHT: number = 16;
const FAB_GAP: number = 16;

@Entry
@ComponentV2
struct Index {
  pathStack: NavPathStack = new NavPathStack();
  @Local currentTab: number = 0;
  @Local showBillSheet: boolean = false;
  @Local homeSelect: boolean = false;
  @Local refreshTick: number = 0;

  @Computed
  get showFab(): boolean {
    return (this.currentTab === 0 && !this.homeSelect) || this.currentTab === 1;
  }

  private tabStyle(idx: number): BottomTabBarStyle {
    return new BottomTabBarStyle({
      normal: new SymbolGlyphModifier(SymRes.get(TAB_ICONS[idx])).fontColor(['#999999']),
      selected: new SymbolGlyphModifier(SymRes.get(TAB_ICONS[idx])).fontColor([Theme.cBrand])
    }, TAB_LABELS[idx]);
  }

  private capX(idx: number): number {
    return HDS_ITEM_PAD + (HDS_ITEM_W - CAP_W) / 2 + HDS_ITEM_W * idx;
  }

  @Builder
  billSheetBuilder() {
    BillSheet({
      onSheetClose: () => {
        this.showBillSheet = false;
      }
    })
  }

  build() {
    Navigation(this.pathStack) {
      Stack({ alignContent: Alignment.Bottom }) {
        HdsTabs() {
          TabContent() {
            HomePage({
              navStack: this.pathStack,
              refreshTick: this.refreshTick,
              onSelectModeChange: (v: boolean) => {
                this.homeSelect = v;
              }
            })
          }
          .tabBar(this.tabStyle(0))
          .onWillShow(() => {
            this.refreshTick++;
          })

          TabContent() {
            CalendarPage({ refreshTick: this.refreshTick })
          }
          .tabBar(this.tabStyle(1))
          .onWillShow(() => {
            this.refreshTick++;
          })

          TabContent() {
            AssetPage({ refreshTick: this.refreshTick })
          }
          .tabBar(this.tabStyle(2))
          .onWillShow(() => {
            this.refreshTick++;
          })

          TabContent() {
            StatisticsPage({ refreshTick: this.refreshTick })
          }
          .tabBar(this.tabStyle(3))
          .onWillShow(() => {
            this.refreshTick++;
          })

          TabContent() {
            MinePage()
          }
          .tabBar(this.tabStyle(4))
        }
        .barPosition(BarPosition.End)
        .vertical(false)
        .scrollable(false)
        .barOverlap(true)
        .barFloatingStyle({
          barBottomMargin: HDS_BAR_BOTTOM,
          barOpacity: 0.72,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .divider({ mode: DividerMode.NONE })
        .onChange((idx: number) => {
          this.currentTab = idx;
        })
        .width('100%')
        .height('100%')

        Stack() {
          Stack() {
            Stack()
              .width(CAP_W)
              .height(CAP_H)
              .borderRadius(CAP_H / 2)
              .linearGradient({
                angle: 135,
                colors: [
                  ['#338FE7FF', 0],
                  ['#33A8C8FF', 0.28],
                  ['#339A9AFF', 0.52],
                  ['#33B49AFF', 0.76],
                  ['#33C89AFF', 1]
                ]
              })
              .shadow({ radius: 22, color: '#739AC8FF', offsetX: 0, offsetY: 3 })

            Stack()
              .width(CAP_W)
              .height(CAP_H)
              .borderRadius(CAP_H / 2)
              .border({ width: 1.3, color: '#80A8B8FF' })

            Stack()
              .width(CAP_W - 3)
              .height(CAP_H - 3)
              .borderRadius((CAP_H - 3) / 2)
              .backgroundColor('#0FFFFFFF')
              .border({ width: 0.8, color: '#73FFFFFF' })
              .shadow({ radius: 5, color: '#2EFFFFFF', offsetX: 0, offsetY: -1 })
          }
          .width(CAP_W)
          .height(CAP_H)
          .position({ x: this.capX(this.currentTab), y: (HDS_BAR_H - CAP_H) / 2 })
          .animation({ duration: 400, curve: curves.springMotion(0.38, 0.9) })
        }
        .width(HDS_BAR_W)
        .height(HDS_BAR_H)
        .margin({ bottom: HDS_BAR_BOTTOM })
        .hitTestBehavior(HitTestMode.Transparent)

        if (this.showFab) {
          Row() {
            Stack() {
              SymbolGlyph(SymRes.get('plus'))
                .fontSize(24)
                .fontColor([Color.White])
            }
            .width(Theme.fabSize)
            .height(Theme.fabSize)
            .borderRadius(Theme.fabSize / 2)
            .backgroundColor(Theme.cBrand)
            .shadow({ radius: 12, color: Theme.cFabShadow, offsetX: 0, offsetY: 4 })
            .onClick(() => {
              this.showBillSheet = true;
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .padding({ right: FAB_RIGHT })
          .margin({ bottom: HDS_BAR_BOTTOM + HDS_BAR_H + FAB_GAP })
          .transition(TransitionEffect.OPACITY
            .combine(TransitionEffect.scale({ x: 0.6, y: 0.6 }))
            .animation({ duration: 220, curve: Curve.EaseOut }))
        }
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page_bottom'))
    .bindSheet(this.showBillSheet!!, this.billSheetBuilder(), {
      height: '75%',
      showClose: false,
      dragBar: false,
      onDisappear: () => {
        this.showBillSheet = false;
      }
    })
  }
}
