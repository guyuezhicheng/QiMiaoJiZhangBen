import { SummaryCardModel } from '../model/Models';
import { SymRes, Theme } from '../model/Theme';

@ComponentV2
export struct SummaryCardSwipe {
  @Param cards: SummaryCardModel[] = [];
  @Local curIndex: number = 0;

  private cardScale(idx: number): number {
    return idx === this.curIndex ? 1 : 0.95;
  }

  private cardOpacity(idx: number): number {
    return idx === this.curIndex ? 1 : 0.7;
  }

  @Builder
  cardInner(card: SummaryCardModel) {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        SymbolGlyph(SymRes.get(card.icon))
          .fontSize(16)
          .fontColor([Color.White])
        Text(card.title)
          .fontSize(Theme.fontBody)
          .fontWeight(600)
          .fontColor(Color.White)
      }

      Text(card.bigText)
        .fontSize(Theme.fontBigAmount)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .maxLines(1)

      Row() {
        Column({ space: 2 }) {
          Text(card.sub1Label)
            .fontSize(Theme.fontAux)
            .fontColor('#CCFFFFFF')
          Text(card.sub1Value)
            .fontSize(Theme.fontAux)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text(card.sub2Label)
            .fontSize(Theme.fontAux)
            .fontColor('#CCFFFFFF')
          Text(card.sub2Value)
            .fontSize(Theme.fontAux)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.SpaceBetween)
    .height(120)
    .width('100%')
    .padding(Theme.cardPad)
  }

  @Builder
  cardExpense(card: SummaryCardModel) {
    Column() {
      this.cardInner(card)
    }
    .borderRadius(20)
    .linearGradient({ angle: 135, colors: [['#FF8D8D', 0.0], ['#E4484E', 1.0]] })
  }

  @Builder
  cardBudget(card: SummaryCardModel) {
    Column() {
      this.cardInner(card)
    }
    .borderRadius(20)
    .linearGradient({ angle: 135, colors: [['#3FCFC6', 0.0], ['#1FA69E', 1.0]] })
  }

  @Builder
  cardBalance(card: SummaryCardModel) {
    Column() {
      this.cardInner(card)
    }
    .borderRadius(20)
    .linearGradient({ angle: 135, colors: [['#9C8BFF', 0.0], ['#6C58D6', 1.0]] })
  }

  @Builder
  cardIncome(card: SummaryCardModel) {
    Column() {
      this.cardInner(card)
    }
    .borderRadius(20)
    .linearGradient({ angle: 135, colors: [['#54D98F', 0.0], ['#24B372', 1.0]] })
  }

  @Builder
  cardOf(card: SummaryCardModel) {
    if (card.kind === 'expense') {
      this.cardExpense(card)
    } else if (card.kind === 'budget') {
      this.cardBudget(card)
    } else if (card.kind === 'balance') {
      this.cardBalance(card)
    } else {
      this.cardIncome(card)
    }
  }

  build() {
    Swiper() {
      ForEach(this.cards, (card: SummaryCardModel, idx: number) => {
        Column() {
          this.cardOf(card)
        }
        .width('100%')
        .scale({ x: this.cardScale(idx), y: this.cardScale(idx) })
        .opacity(this.cardOpacity(idx))
        .animation({ duration: 250, curve: Curve.EaseOut })
      }, (card: SummaryCardModel): string => `${card.kind}_${card.bigText}_${card.sub1Value}_${card.sub2Value}`)
    }
    .width('100%')
    .indicator(false)
    .loop(true)
    .prevMargin(12)
    .nextMargin(12)
    .onChange((idx: number) => {
      this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
        this.curIndex = idx;
      });
    })
  }
}
