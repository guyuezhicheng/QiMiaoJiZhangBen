import { emitter } from '@kit.BasicServicesKit';
import { Book } from '../model/Models';
import { EVT_DATA_CHANGED, Store } from '../model/Rdb';
import { SymRes, Theme } from '../model/Theme';

@Builder
export function BookManageBuilder() {
  BookManagePage()
}

@ComponentV2
struct BookManagePage {
  @Local books: Book[] = [];
  @Local newName: string = '';
  @Local editingId: number = -1;
  @Local editingName: string = '';
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
    this.books = Store.get().books.slice(0);
  }

  private async createBook(): Promise<void> {
    const name: string = this.newName.trim();
    if (name.length === 0) {
      return;
    }
    const store: Store = Store.get();
    await store.addBook(name, 500000);
    store.emitChange();
    this.newName = '';
  }

  private async saveRename(id: number): Promise<void> {
    const name: string = this.editingName.trim();
    const store: Store = Store.get();
    if (name.length > 0) {
      await store.renameBook(id, name);
      store.emitChange();
    }
    this.editingId = -1;
    this.editingName = '';
  }

  private confirmDelete(id: number): void {
    this.getUIContext().showAlertDialog({
      message: '删除后该账本下的账单将一并删除，确定删除吗？',
      autoCancel: true,
      confirm: {
        value: '删除',
        action: (): void => {
          const store: Store = Store.get();
          store.deleteBook(id).then(() => {
            store.emitChange();
          });
        }
      },
      cancel: (): void => {
      }
    });
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '输入新账本名称', text: this.newName })
            .fontSize(Theme.fontAux)
            .fontColor(Theme.cText)
            .placeholderFont({ size: Theme.fontAux })
            .placeholderColor(Theme.cText2)
            .backgroundColor(Theme.cSearch)
            .borderRadius(12)
            .height(40)
            .layoutWeight(1)
            .onChange((v: string) => {
              this.newName = v;
            })
          Text('创建')
            .fontSize(Theme.fontAux)
            .fontWeight(600)
            .fontColor(Color.White)
            .height(40)
            .padding({ left: 16, right: 16 })
            .backgroundColor(Theme.cBrand)
            .borderRadius(12)
            .onClick(() => {
              this.createBook();
            })
        }
        .width('100%')

        Column({ space: 2 }) {
          ForEach(this.books, (bk: Book) => {
            Row({ space: 10 }) {
              SymbolGlyph(SymRes.get('book'))
                .fontSize(18)
                .fontColor([Theme.cBrand])

              if (this.editingId === bk.id) {
                TextInput({ text: this.editingName })
                  .fontSize(Theme.fontBody)
                  .fontColor(Theme.cText)
                  .backgroundColor(Theme.cSearch)
                  .borderRadius(10)
                  .height(36)
                  .layoutWeight(1)
                  .onChange((v: string) => {
                    this.editingName = v;
                  })
                  .onSubmit(() => {
                    this.saveRename(bk.id);
                  })
                SymbolGlyph(SymRes.get('check'))
                  .fontSize(18)
                  .fontColor([Theme.cGreen])
                  .onClick(() => {
                    this.saveRename(bk.id);
                  })
              } else {
                Text(bk.name)
                  .fontSize(Theme.fontBody)
                  .fontColor(Theme.cText)
                  .layoutWeight(1)
                SymbolGlyph(SymRes.get('ellipsis_circle'))
                  .fontSize(18)
                  .fontColor([Theme.cText2])
                  .onClick(() => {
                    this.editingId = bk.id;
                    this.editingName = bk.name;
                  })
              }

              SymbolGlyph(SymRes.get('trash'))
                .fontSize(18)
                .fontColor([Theme.cRed])
                .onClick(() => {
                  this.confirmDelete(bk.id);
                })
            }
            .width('100%')
            .height(52)
            .padding({ left: Theme.cardPad, right: Theme.cardPad })
            .backgroundColor(Theme.cCard)
            .borderRadius(14)
          }, (bk: Book): string => `bk_${bk.id}_${bk.name}`)
        }
        .width('100%')
      }
      .padding({ left: Theme.pagePad, right: Theme.pagePad, top: 12, bottom: 20 })
      .width('100%')
      .height('100%')
    }
    .title('管理账本')
    .backgroundColor($r('app.color.bg_page_bottom'))
  }
}
