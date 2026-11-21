import { AssetAccount, Bill, Book, Category } from '../model/Models';
import { Store } from '../model/Rdb';
import { CategoryData } from '../model/CategoryData';
import { SymRes, Theme } from '../model/Theme';
import { DateUtil } from '../viewmodel/HomeVM';
import { CategoryGrid } from './CategoryGrid';
import { NumberPad } from './NumberPad';
import { WheelDatePicker } from './WheelDatePicker';

const TABS: string[] = ['支出', '收入', '转账', '模板'];

@ComponentV2
export struct BillSheet {
  @Event onSheetClose: () => void = () => {};

  @Local sheetTab: string = 'expense';
  @Local catId: string = 'canyin';
  @Local subId: string = '';
  @Local remark: string = '';
  @Local amountText: string = '';
  @Local plusAcc: number = 0;
  @Local occurTime: number = Date.now();
  @Local bookId: number = 1;
  @Local selectedTags: string[] = [];
  @Local refundMode: boolean = false;
  @Local showDatePicker: boolean = false;
  @Local showBookMenu: boolean = false;
  @Local showTagBar: boolean = false;

  aboutToAppear(): void {
    const store: Store = Store.get();
    if (store.books.length > 0) {
      this.bookId = store.books[0].id;
    }
  }

  private cats(): Category[] {
    const store: Store = Store.get();
    if (this.sheetTab === 'expense') {
      return CategoryData.treeOf(store.categories, 'expense');
    }
    if (this.sheetTab === 'income') {
      return CategoryData.treeOf(store.categories, 'income');
    }
    return [];
  }

  private currentBookName(): string {
    const store: Store = Store.get();
    const bk = store.books.find((b): boolean => b.id === this.bookId);
    if (bk !== undefined) {
      return bk.name;
    }
    return store.books.length > 0 ? store.books[0].name : '我的账本';
  }

  private parseCents(text: string): number {
    if (text.length === 0) {
      return 0;
    }
    const parts: string[] = text.split('.');
    let intPart: number = 0;
    if (parts.length > 0 && parts[0].length > 0) {
      intPart = parseInt(parts[0]);
    }
    let fracPart: number = 0;
    if (parts.length > 1) {
      let frac: string = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];
      if (frac.length === 1) {
        frac = frac + '0';
      }
      if (frac.length > 0) {
        fracPart = parseInt(frac);
      }
    }
    return intPart * 100 + fracPart;
  }

  private totalCents(): number {
    return this.plusAcc + this.parseCents(this.amountText);
  }

  private amountDisplay(): string {
    if (this.amountText.length === 0 && this.plusAcc === 0) {
      return '0.00';
    }
    if (this.amountText.length === 0) {
      return FmtAmount(this.plusAcc);
    }
    return this.amountText;
  }

  private amountColor(): ResourceColor {
    if (this.sheetTab === 'income') {
      return Theme.cGreen;
    }
    if (this.sheetTab === 'transfer') {
      return Theme.cBrand;
    }
    return Theme.cRed;
  }

  private dateChipText(): string {
    const now: number = Date.now();
    if (DateUtil.dateKey(this.occurTime) === DateUtil.dateKey(now)) {
      return `今日 ${DateUtil.hhmm(this.occurTime)}`;
    }
    return DateUtil.dateLabel(this.occurTime);
  }

  private onPadKey(key: string): void {
    if (key === 'del') {
      this.amountText = this.amountText.substring(0, this.amountText.length - 1);
      return;
    }
    if (key === 'plus') {
      this.plusAcc += this.parseCents(this.amountText);
      this.amountText = '';
      return;
    }
    if (key === 'minus') {
      this.plusAcc -= this.parseCents(this.amountText);
      this.amountText = '';
      return;
    }
    if (key === '.') {
      if (this.amountText.indexOf('.') < 0) {
        this.amountText = this.amountText.length === 0 ? '0.' : this.amountText + '.';
      }
      return;
    }
    if (this.amountText.indexOf('.') >= 0) {
      const frac: string = this.amountText.split('.')[1];
      if (frac.length < 2) {
        this.amountText += key;
      }
    } else {
      if (this.amountText === '0') {
        this.amountText = key;
      } else if (this.amountText.length < 9) {
        this.amountText += key;
      }
    }
  }

  private resetEntryState(): void {
    this.amountText = '';
    this.plusAcc = 0;
    this.remark = '';
    this.selectedTags = [];
    this.refundMode = false;
    this.showTagBar = false;
    this.occurTime = Date.now();
  }

  private buildBill(cents: number): Bill {
    const bill: Bill = new Bill();
    bill.bookId = this.bookId;
    if (this.sheetTab === 'expense') {
      bill.type = 'expense';
      bill.categoryId = this.catId;
      bill.subId = this.subId;
    } else if (this.sheetTab === 'income') {
      bill.type = 'income';
      bill.categoryId = this.catId;
      bill.subId = this.subId;
    } else if (this.sheetTab === 'transfer') {
      bill.type = 'transfer';
      bill.categoryId = 'other_exp';
      bill.subId = '';
    } else {
      bill.type = 'expense';
      bill.categoryId = 'other_exp';
      bill.subId = '';
    }
    bill.amount = cents;
    bill.remark = this.remark;
    bill.occurTime = this.occurTime;
    const store: Store = Store.get();
    bill.account = store.accounts.length > 0 ? store.accounts[0].name : '现金';
    const tags: string[] = this.selectedTags.slice(0);
    if (this.refundMode && tags.indexOf('报销') < 0) {
      tags.push('报销');
    }
    bill.tags = tags;
    bill.refundStatus = this.refundMode ? 'pending' : 'none';
    return bill;
  }

  private onDone(): void {
    const cents: number = this.totalCents();
    if (cents <= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入金额', duration: 1500 });
      return;
    }
    Store.get().addBill(this.buildBill(cents));
    this.onSheetClose();
  }

  private onAgain(): void {
    const cents: number = this.totalCents();
    if (cents <= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入金额', duration: 1500 });
      return;
    }
    Store.get().addBill(this.buildBill(cents));
    this.resetEntryState();
    this.getUIContext().getPromptAction().showToast({ message: '已记一笔', duration: 1200 });
  }

  @Builder
  tabPill(label: string, tab: string) {
    Text(label)
      .fontSize(Theme.fontBody)
      .fontWeight(this.sheetTab === tab ? 600 : FontWeight.Normal)
      .fontColor(this.sheetTab === tab ? Theme.cText : Theme.cText2)
      .height(34)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.sheetTab === tab ? Theme.cCard : Color.Transparent)
      .borderRadius(17)
      .onClick(() => {
        this.sheetTab = tab;
        if (tab === 'expense') {
          this.catId = 'canyin';
        } else if (tab === 'income') {
          this.catId = 'gongzi';
        }
        this.subId = '';
      })
  }

  @Builder
  chipRowInner() {
    Row({ space: 8 }) {
      Row({ space: 4 }) {
        SymbolGlyph(SymRes.get('clock'))
          .fontSize(14)
          .fontColor([Theme.cText2])
        Text(this.dateChipText())
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText)
      }
      .height(30)
      .padding({ left: 10, right: 10 })
      .backgroundColor(this.showDatePicker ? Theme.cBrandLight : Theme.cChip)
      .borderRadius(15)
      .onClick(() => {
        this.showDatePicker = !this.showDatePicker;
      })

      Row({ space: 4 }) {
        Text(this.currentBookName())
          .fontSize(Theme.fontAux)
          .fontColor(Theme.cText)
        SymbolGlyph(SymRes.get('chevron_down'))
          .fontSize(12)
          .fontColor([Theme.cText2])
      }
      .height(30)
      .padding({ left: 10, right: 10 })
      .backgroundColor(Theme.cChip)
      .borderRadius(15)
      .bindPopup(this.showBookMenu!!, {
        builder: this.bookMenuBuilder(),
        placement: Placement.Bottom,
        popupColor: Color.Transparent,
        autoCancel: true,
        onStateChange: (state) => {
          this.showBookMenu = state.isVisible;
        }
      })
      .onClick(() => {
        this.showBookMenu = !this.showBookMenu;
      })

      Text(this.refundMode ? '可报销' : '报销')
        .fontSize(Theme.fontAux)
        .fontColor(this.refundMode ? Color.White : Theme.cText)
        .height(30)
        .padding({ left: 10, right: 10 })
        .backgroundColor(this.refundMode ? Theme.cOrange : Theme.cChip)
        .borderRadius(15)
        .onClick(() => {
          this.refundMode = !this.refundMode;
          this.showTagBar = this.refundMode;
        })
    }
  }

  @Builder
  bookMenuBuilder() {
    Column({ space: 4 }) {
      ForEach(Store.get().books, (bk: Book) => {
        Text(bk.name)
          .fontSize(Theme.fontBody)
          .fontColor(bk.id === this.bookId ? Theme.cBrand : Theme.cText)
          .height(38)
          .width(160)
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .onClick(() => {
            this.bookId = bk.id;
            this.showBookMenu = false;
          })
      }, (bk: Book): string => bk.id.toString())
      Divider()
        .color(Theme.cDivider)
      Text('创建账本')
        .fontSize(Theme.fontBody)
        .fontColor(Theme.cBrand)
        .height(38)
        .width(160)
        .textAlign(TextAlign.Center)
        .borderRadius(10)
        .onClick(() => {
          Store.get().addBook('新账本', 0).then((bk: Book): void => {
            this.bookId = bk.id;
            this.showBookMenu = false;
          });
        })
    }
    .padding(8)
  }

  @Builder
  tagBarInner() {
    Row({ space: 8 }) {
      ForEach(['报销', '商家', '成员', '标记', 'emoji', '旅行', '饮食', '网购'], (tag: string) => {
        Text(tag)
          .fontSize(Theme.fontAux)
          .fontColor(this.selectedTags.indexOf(tag) >= 0 ? Color.White : Theme.cText2)
          .height(26)
          .padding({ left: 10, right: 10 })
          .backgroundColor(this.selectedTags.indexOf(tag) >= 0 ? Theme.cBrand : Theme.cChip)
          .borderRadius(13)
          .onClick(() => {
            if (this.selectedTags.indexOf(tag) >= 0) {
              this.selectedTags = this.selectedTags.filter((t: string): boolean => t !== tag);
            } else {
              const next: string[] = this.selectedTags.slice(0);
              next.push(tag);
              this.selectedTags = next;
            }
          })
      }, (tag: string): string => tag)
    }
  }

  build() {
    Column() {
      Row() {
        Stack() {
          SymbolGlyph(SymRes.get('close'))
            .fontSize(16)
            .fontColor([Theme.cText2])
        }
        .width(30)
        .height(30)
        .borderRadius(15)
        .backgroundColor(Theme.cChip)
        .onClick(() => {
          this.onSheetClose();
        })

        Blank()
      }
      .width('100%')
      .padding({ top: 2, bottom: 6 })

      Row({ space: 6 }) {
        ForEach(TABS, (label: string, idx: number) => {
          if (idx === 0) {
            this.tabPill(label, 'expense')
          } else if (idx === 1) {
            this.tabPill(label, 'income')
          } else if (idx === 2) {
            this.tabPill(label, 'transfer')
          } else {
            this.tabPill(label, 'template')
          }
        }, (label: string): string => label)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 6, bottom: 10 })
      .backgroundColor(Theme.cChip)
      .borderRadius(22)
      .margin({ top: 10, bottom: 10 })

      if (this.sheetTab === 'expense' || this.sheetTab === 'income') {
        CategoryGrid({
          cats: this.cats(),
          selectedId: this.catId,
          selectedSubId: this.subId,
          onSelectCat: (cat: Category) => {
            this.catId = cat.id;
            this.subId = '';
          },
          onSelectSub: (sub: Category) => {
            this.subId = sub.id;
          }
        })
      } else if (this.sheetTab === 'transfer') {
        Column({ space: 8 }) {
          Text('选择账户')
            .fontSize(Theme.fontBody)
            .fontWeight(600)
            .fontColor(Theme.cText)
          Row({ space: 8 }) {
            ForEach(Store.get().accounts, (acc: AssetAccount) => {
              Text(acc.name)
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText)
                .height(30)
                .padding({ left: 10, right: 10 })
                .backgroundColor(Theme.cChip)
                .borderRadius(15)
            }, (acc: AssetAccount): string => acc.id.toString())
          }
        }
        .width('100%')
        .padding(12)
      } else {
        Text('模板功能即将上线')
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cText2)
          .width('100%')
          .height(80)
          .textAlign(TextAlign.Center)
      }

      Row({ space: 8 }) {
        SymbolGlyph(SymRes.get('camera'))
          .fontSize(20)
          .fontColor([Theme.cText2])
        TextInput({ placeholder: '点击填写备注', text: this.remark })
          .placeholderColor(Theme.cText2)
          .placeholderFont({ size: Theme.fontBody })
          .fontSize(Theme.fontBody)
          .fontColor(Theme.cText)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .layoutWeight(1)
          .onChange((v: string) => {
            this.remark = v;
          })
        Text(this.amountDisplay())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.amountColor())
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })

      Scroll() {
        Row() {
          this.chipRowInner()
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      if (this.showTagBar) {
        Scroll() {
          Row() {
            this.tagBarInner()
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .margin({ top: 6 })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }

      if (this.showDatePicker) {
        WheelDatePicker({
          currentTime: this.occurTime,
          onPickOk: (t: number) => {
            this.occurTime = t;
            this.showDatePicker = false;
          },
          onPickCancel: () => {
            this.showDatePicker = false;
          }
        })
          .margin({ top: 8 })
          .transition(TransitionEffect.translate({ y: 40 }).animation({ duration: 250 })
            .combine(TransitionEffect.OPACITY.animation({ duration: 250 })))
      }

      Blank()

      NumberPad({
        onPadKey: (key: string) => this.onPadKey(key),
        onAgain: () => this.onAgain(),
        onDone: () => this.onDone()
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 20 })
  }
}

function FmtAmount(cents: number): string {
  const abs: number = Math.abs(cents);
  const intPart: number = Math.floor(abs / 100);
  const frac: number = abs % 100;
  const fracStr: string = frac < 10 ? '0' + frac.toString() : frac.toString();
  return intPart.toString() + '.' + fracStr;
}
