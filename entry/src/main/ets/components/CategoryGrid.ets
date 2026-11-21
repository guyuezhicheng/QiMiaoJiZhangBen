import { Category } from '../model/Models';
import { SymRes, Theme } from '../model/Theme';

@ComponentV2
export struct CategoryGrid {
  @Param cats: Category[] = [];
  @Param selectedId: string = '';
  @Param selectedSubId: string = '';
  @Param showChildren: boolean = true;
  @Event onSelectCat: (cat: Category) => void = (_cat: Category) => {};
  @Event onSelectSub: (sub: Category) => void = (_sub: Category) => {};

  private activeChildren(): Category[] {
    if (!this.showChildren) {
      return [];
    }
    const sel: Category | undefined =
      this.cats.find((c: Category): boolean => c.id === this.selectedId);
    if (sel === undefined) {
      return [];
    }
    return sel.children;
  }

  build() {
    Scroll() {
      Grid() {
        ForEach(this.cats, (cat: Category) => {
          GridItem() {
            Column({ space: 6 }) {
              Stack() {
                SymbolGlyph(SymRes.get(cat.icon))
                  .fontSize(22)
                  .fontColor([Color.White])
              }
              .width(48)
              .height(48)
              .borderRadius(24)
              .backgroundColor(this.selectedId === cat.id ? Theme.cCatSel : cat.bg)
              .scale({ x: this.selectedId === cat.id ? 1 : 1, y: 1 })
              Text(cat.name)
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText)
                .maxLines(1)
            }
            .onClick(() => this.onSelectCat(cat))
          }
        }, (cat: Category): string => cat.id)

        ForEach(this.activeChildren(), (sub: Category) => {
          GridItem() {
            Column({ space: 6 }) {
              Stack() {
                SymbolGlyph(SymRes.get(sub.icon))
                  .fontSize(16)
                  .fontColor([Color.White])
              }
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor(this.selectedSubId === sub.id ? Theme.cCatSel : sub.bg)
              Text(sub.name)
                .fontSize(Theme.fontAux)
                .fontColor(Theme.cText)
                .maxLines(1)
            }
            .onClick(() => this.onSelectSub(sub))
          }
        }, (sub: Category): string => sub.id)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(10)
      .width('100%')
    }
    .width('100%')
    .constraintSize({ maxHeight: 260 })
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
  }
}
