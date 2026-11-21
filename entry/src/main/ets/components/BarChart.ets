import { BarPointModel } from '../model/Models';
import { Fmt, Theme } from '../model/Theme';

@ComponentV2
export struct BarChart {
  @Param points: BarPointModel[] = [];
  @Param mode: string = 'expense';
  @Local highlight: number = -1;
  private ctx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));

  aboutToAppear(): void {
    this.redraw();
  }

  @Monitor('points', 'mode')
  onDataChanged(): void {
    this.highlight = -1;
    this.redraw();
  }

  private redraw(): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    ctx.clearRect(0, 0, ctx.width, ctx.height);
    const w: number = ctx.width;
    const h: number = ctx.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    const padX: number = 8;
    const bottom: number = h - 18;
    const top: number = 16;
    const usable: number = bottom - top;
    const count: number = this.points.length > 0 ? this.points.length : 7;
    const slot: number = (w - padX * 2) / count;
    let maxValue: number = 0;
    for (let i: number = 0; i < this.points.length; i++) {
      const p: BarPointModel = this.points[i];
      if (p.expense > maxValue) {
        maxValue = p.expense;
      }
      if (p.income > maxValue) {
        maxValue = p.income;
      }
    }
    if (maxValue <= 0) {
      maxValue = 1;
    }
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    for (let i: number = 0; i < this.points.length; i++) {
      const p: BarPointModel = this.points[i];
      const cx: number = padX + slot * i + slot / 2;
      const barW: number = Math.min(10, slot / 3);
      const expH: number = p.expense / maxValue * usable;
      const incH: number = p.income / maxValue * usable;
      const isHi: boolean = i === this.highlight;

      ctx.globalAlpha = this.mode === 'expense' ? 1 : 0.35;
      ctx.fillStyle = '#F5453C';
      ctx.fillRect(cx - barW - 1, bottom - expH, barW, expH);
      if (isHi && this.mode === 'expense' && p.expense > 0) {
        ctx.fillStyle = '#1F1F1F';
        ctx.fillText(Fmt.yuanStr(p.expense), cx - barW - 1, bottom - expH - 4);
      }

      ctx.globalAlpha = this.mode === 'income' ? 1 : 0.35;
      ctx.fillStyle = '#0EC26C';
      ctx.fillRect(cx + 1, bottom - incH, barW, incH);
      if (isHi && this.mode === 'income' && p.income > 0) {
        ctx.fillStyle = '#1F1F1F';
        ctx.fillText(Fmt.yuanStr(p.income), cx + 1, bottom - incH - 4);
      }

      ctx.globalAlpha = 1;
      ctx.fillStyle = isHi ? '#3D7BFA' : '#999999';
      ctx.fillText(p.label, cx, h - 4);
    }
    ctx.globalAlpha = 1;
  }

  build() {
    Stack() {
      Canvas(this.ctx)
        .width('100%')
        .height(180)
        .onReady(() => {
          this.redraw();
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down || event.type === TouchType.Move) {
            const w: number = this.ctx.width;
            const x: number = event.touches[0].x;
            const count: number = this.points.length > 0 ? this.points.length : 7;
            const slot: number = (w - 16) / count;
            let idx: number = Math.floor((x - 8) / slot);
            if (idx < 0) {
              idx = 0;
            }
            if (idx > count - 1) {
              idx = count - 1;
            }
            if (idx !== this.highlight) {
              this.highlight = idx;
              this.redraw();
            }
          }
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.highlight = -1;
            this.redraw();
          }
        })
    }
    .width('100%')
    .height(180)
  }
}
