import { emitter } from '@kit.BasicServicesKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BillGroupModel, SummaryCardModel } from '../model/Models';
import { EVT_DATA_CHANGED, Store } from '../model/Rdb';
import { SymRes, Theme } from '../model/Theme';
import { DisplayMode, HomeCalc, HomePeriod } from '../viewmodel/HomeVM';
import { BillGroup } from '../components/BillGroup';
import { SelectBar } from '../components/SelectBar';
import { SummaryCardSwipe } from '../components/SummaryCardSwipe';
import { BookMenuPanel } from '../dialogs/BookMenu';
import { DisplayModeMenuPanel } from '../dialogs/DisplayModeMenu';
import { DeleteConfirm } from '../dialogs/DeleteConfirm';

@ComponentV2
export struct HomePage {
  @Param navStack: NavPathStack = new NavPathStack();
  @Event onSelectModeChange: (v: boolean) => void = () => {};
  @Local mode: DisplayMode = 'week';
  @Local anchor: number = Date.now();
  @Local currentBookId: number = 0;
  @Local currentBookName: string = '我的账本';
  @Local searchText: string = '';
  @Local cards: SummaryCardModel[] = [];
  @Local selectMode: boolean = false;
  @Local selectedIds: number[] = [];
  @Local showBookMenu: boolean = false;
  @Local showModeMenu: boolean = false;
  @Local listEmpty: boolean = true;
  @Local groups: BillGroupModel[] = [];
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
    if (store.books.length === 0) {
      return;
    }
    let bookExists: boolean = false;
    for (let i: number = 0; i < store.books.length; i++) {
      if (store.books[i].id === this.currentBookId) {
        bookExists = true;
        this.currentBookName = store.books[i].name;
      }
    }
    if (!bookExists) {
      this.currentBookId = store.books[0].id;
      this.currentBookName = store.books[0].name;
    }
    const bills = HomeCalc.filterBills(this.mode, this.anchor, this.currentBookId, this.searchText);
    this.cards = HomeCalc.buildCards(this.mode, this.anchor, bills);
    const groups: BillGroupModel[] = HomeCalc.buildGroups(bills);
    this.groups = groups;
    this.listEmpty = groups.length === 0;
  }

  private haptic(): void {
    try {
      const effect: vibrator.VibrateTime = { type: 'time', duration: 12 };
      const attr: vibrator.VibrateAttribute = { id: 0, usage: 'touch' };
      vibrator.startVibration(effect, attr);
    } catch (err) {
    }
  }

  private move(dir: number): void {
    this.anchor = HomePeriod.step(this.mode, this.anchor, dir);
    this.rebuild();
  }

  private isGroupSelected(g: BillGroupModel): boolean {
    for (let i: number = 0; i < g.bills.length; i++) {
      if (this.selectedIds.indexOf(g.bills[i].id) < 0) {
        return false;
      }
    }
    return g.bills.length > 0;
  }

  private allIds(): number[] {
    const ids: number[] = [];
    for (let i: number = 0; i < this.groups.length; i++) {
      const g: BillGroupModel = this.groups[i];
      for (let j: number = 0; j < g.bills.length; j++) {
        ids.push(g.bills[j].id);
      }
    }
    return ids;
  }

  private toggleId(id: number): void {
    if (this.selectedIds.indexOf(id) >= 0) {
      this.selectedIds = this.selectedIds.filter((x: number): boolean => x !== id);
    } else {
      const next: number[] = this.selectedIds.slice(0);
      next.push(id);
      this.selectedIds = next;
    }
  }

  private toggleGroup(g: BillGroupModel): void {
    if (this.isGroupSelected(g)) {
      const removeIds: number[] = [];
      for (let j: number = 0; j < g.bills.length; j++) {
        removeIds.push(g.bills[j].id);
      }
      this.selectedIds = this.selectedIds.filter((x: number): boolean => removeIds.indexOf(x) < 0);
    } else {
      const next: number[] = this.selectedIds.slice(0);
      for (let j: number = 0; j < g.bills.length; j++) {
        if (next.indexOf(g.bills[j].id) < 0) {
          next.push(g.bills[j].id);
        }
      }
      this.selectedIds = next;
    }
  }

  private onBillTap(id: number): void {
    if (this.selectMode) {
      this.toggleId(id);
    }
  }

  private onBillLongPress(id: number): void {
    this.haptic();
    this.selectMode = true;
    this.onSelectModeChange(true);
    this.selectedIds = [id];
  }

  private exitSelect(): void {
    this.selectMode = false;
    this.onSelectModeChange(false);
    this.selectedIds = [];
  }

  private selectAll(): void {
    const all: number[] = this.allIds();
    if (this.selectedIds.length === all.length && all.length > 0) {
      this.selectedIds = [];
    } else {
      this.selectedIds = all;
    }
  }

  private deleteSelected(): void {
    const count: number = this.selectedIds.length;
    DeleteConfirm.show(this.getUIContext(), count, () => {
      const ids: number[] = this.selectedIds.slice(0);
      Store.get().deleteBills(ids).then(() => {
        this.exitSelect();
      });
    });
  }

  @Builder
  bookMenuBuilder() {
    BookMenuPanel({
      books: Store.get().books,
      currentBookId: this.currentBookId,
      onPickBook: (id: number) => {
        this.currentBookId = id;
        this.showBookMenu = false;
        this.rebuild();
      },
      onManageBooks: () => {
        this.showBookMenu = false;
        this.navStack.pushPathByName('bookManage', null);
      }
    })
  }

  @Builder
  modeMenuBuilder() {
    DisplayModeMenuPanel({
      mode: this.mode,
      onPickMode: (m: DisplayMode) => {
        this.mode = m;
        this.showModeMenu = false;
        this.rebuild();
      }
    })
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
        Column() {
          Row({ space: 8 }) {
          Row({ space: 4 }) {
            Text(this.currentBookName)
              .fontSize(Theme.fontTitle)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.cText)
            SymbolGlyph(SymRes.get('chevron_down'))
              .fontSize(16)
              .fontColor([Theme.cText])
          }
          .onClick(() => {
            this.showBookMenu = !this.showBookMenu;
          })
          .bindPopup(this.showBookMenu!!, {
            builder: this.bookMenuBuilder(),
            placement: Placement.BottomLeft,
            popupColor: Color.Transparent,
            autoCancel: true,
            onStateChange: (state) => {
              this.showBookMenu = state.isVisible;
            }
          })

          Blank()

          Stack() {
            SymbolGlyph(SymRes.get('bell'))
              .fontSize(18)
              .fontColor([Theme.cText])
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(Theme.cGlassCircle)
          .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
          .border({ width: 0.8, color: Theme.cGlassBorder })

          Stack() {
            SymbolGlyph(SymRes.get('headphones'))
              .fontSize(18)
              .fontColor([Theme.cText])
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(Theme.cGlassCircle)
          .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
          .border({ width: 0.8, color: Theme.cGlassBorder })
        }
        .width('100%')
        .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 10, bottom: 8 })

        Row({ space: 8 }) {
          SymbolGlyph(SymRes.get('search'))
            .fontSize(16)
            .fontColor([Theme.cText2])
          TextInput({ placeholder: '搜索' })
            .placeholderColor(Theme.cText2)
            .placeholderFont({ size: Theme.fontBody })
            .fontSize(Theme.fontBody)
            .fontColor(Theme.cText)
            .backgroundColor(Color.Transparent)
            .padding(0)
            .layoutWeight(1)
            .onChange((v: string) => {
              this.searchText = v;
              this.rebuild();
            })
        }
        .width('90%')
        .height(36)
        .padding({ left: 12, right: 12 })
        .backgroundColor(Theme.cGlassSearch)
        .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
        .border({ width: 0.8, color: Theme.cGlassBorder })
        .borderRadius(18)
        .margin({ left: '5%' })

        Row() {
          Text(HomePeriod.title(this.mode, this.anchor))
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
            .onClick(() => this.move(-1))

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
            .onClick(() => this.move(1))
          }
          .margin({ left: 10 })

          Blank()

          Row({ space: 2 }) {
            Text(HomePeriod.modeLabel(this.mode))
              .fontSize(Theme.fontAux)
              .fontColor(Theme.cText2)
            SymbolGlyph(SymRes.get('chevron_down'))
              .fontSize(12)
              .fontColor([Theme.cText2])
          }
          .onClick(() => {
            this.showModeMenu = !this.showModeMenu;
          })
          .bindPopup(this.showModeMenu!!, {
            builder: this.modeMenuBuilder(),
            placement: Placement.BottomRight,
            popupColor: Color.Transparent,
            autoCancel: true,
            onStateChange: (state) => {
              this.showModeMenu = state.isVisible;
            }
          })
        }
        .width('100%')
        .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 12, bottom: 8 })

        SummaryCardSwipe({ cards: this.cards })
          .margin({ bottom: 6 })

          if (this.listEmpty) {
            Column() {
              Text('暂无账单')
                .fontSize(Theme.fontBody)
                .fontColor(Theme.cText2)
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 8 }) {
              ForEach(this.groups, (g: BillGroupModel) => {
                BillGroup({
                  group: g,
                  selectMode: this.selectMode,
                  groupSelected: this.isGroupSelected(g),
                  selectedIds: this.selectedIds,
                  onHeaderTap: () => {
                    g.collapsed = !g.collapsed;
                  },
                  onGroupCheckTap: () => this.toggleGroup(g),
                  onBillTap: (id: number) => this.onBillTap(id),
                  onBillLongPress: (id: number) => this.onBillLongPress(id)
                })
              }, (g: BillGroupModel): string =>
                g.dateKey + '_' + g.bills.length + '_' + g.expenseSum + '_' + g.incomeSum)
            }
            .width('100%')
            .padding({ left: Theme.pagePad, right: Theme.pagePad })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: 120 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)

      if (this.selectMode) {
        SelectBar({
          count: this.selectedIds.length,
          allSelected: this.selectedIds.length === this.allIds().length && this.selectedIds.length > 0,
          onClose: () => this.exitSelect(),
          onSelectAll: () => this.selectAll(),
          onDelete: () => this.deleteSelected()
        })
          .margin({ left: Theme.pagePad, right: Theme.pagePad, bottom: 92 })
      }
  }
}
