import { DonutSegment } from '../model/Models';
import { Theme } from '../model/Theme';

@ComponentV2
export struct DonutChart {
  @Param segments: DonutSegment[] = [];
  @Param centerText: string = '';
  private ctx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));

  aboutToAppear(): void {
    this.redraw();
  }

  @Monitor('segments', 'centerText')
  onDataChanged(): void {
    this.redraw();
  }

  private redraw(): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    ctx.clearRect(0, 0, ctx.width, ctx.height);
    const cx: number = ctx.width / 2;
    const cy: number = ctx.height / 2;
    const radius: number = Math.min(ctx.width, ctx.height) / 2 - 18;
    if (radius <= 0) {
      return;
    }
    let total: number = 0;
    for (let i: number = 0; i < this.segments.length; i++) {
      total += this.segments[i].value;
    }
    ctx.lineWidth = 28;
    ctx.lineCap = 'butt';
    if (total <= 0) {
      ctx.beginPath();
      ctx.strokeStyle = '#F2F2F2';
      ctx.arc(cx, cy, radius, 0, Math.PI * 2);
      ctx.stroke();
      return;
    }
    let start: number = -Math.PI / 2;
    for (let i: number = 0; i < this.segments.length; i++) {
      const seg: DonutSegment = this.segments[i];
      const frac: number = seg.value / total;
      const end: number = start + frac * Math.PI * 2;
      ctx.beginPath();
      ctx.strokeStyle = seg.color;
      ctx.arc(cx, cy, radius, start, end);
      ctx.stroke();
      start = end;
    }
  }

  build() {
    Stack() {
      Canvas(this.ctx)
        .width('100%')
        .height(200)
        .onReady(() => {
          this.redraw();
        })
      Column({ space: 2 }) {
        Text(this.centerText)
          .fontSize(Theme.fontTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.cText)
          .maxLines(1)
      }
    }
    .width('100%')
    .height(200)
  }
}
