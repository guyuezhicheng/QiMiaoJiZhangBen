import { Bill, BarPointModel, CatStatRow, Category, SummaryRowModel } from '../model/Models';
import { CategoryData } from '../model/CategoryData';
import { Store } from '../model/Rdb';
import { DateUtil, DisplayMode, HomePeriod, PeriodRange } from './HomeVM';

export type StatMode = 'week' | 'month' | 'year' | 'range';

export class StatSummary {
  expense: number = 0;
  income: number = 0;
  balance: number = 0;
  dayAvg: number = 0;
  excludeStat: number = 0;
  excludeBudget: number = 0;
  pendingRefund: number = 0;
  refunded: number = 0;
}

export class StatCalc {
  static summary(bills: Bill[], start: number, end: number): StatSummary {
    const s: StatSummary = new StatSummary();
    const days: number = Math.max(1, Math.round((end - start) / 86400000));
    for (let i: number = 0; i < bills.length; i++) {
      const b: Bill = bills[i];
      if (b.occurTime < start || b.occurTime >= end) {
        continue;
      }
      if (b.type === 'income') {
        s.income += b.amount;
      } else if (b.type === 'expense') {
        s.expense += b.amount;
      }
      if (b.excludeStat) {
        s.excludeStat += b.amount;
      }
      if (b.refundStatus === 'pending') {
        s.pendingRefund += b.amount;
      }
      if (b.refundStatus === 'refund') {
        s.refunded += b.amount;
      }
    }
    s.balance = s.income - s.expense;
    s.dayAvg = Math.round(s.expense / days);
    s.excludeBudget = s.excludeStat;
    return s;
  }

  static weekdayBars(bills: Bill[], start: number, end: number): BarPointModel[] {
    const points: BarPointModel[] = [];
    const names: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    for (let i: number = 0; i < 7; i++) {
      const p: BarPointModel = new BarPointModel();
      p.label = names[i];
      points.push(p);
    }
    for (let i: number = 0; i < bills.length; i++) {
      const b: Bill = bills[i];
      if (b.occurTime < start || b.occurTime >= end) {
        continue;
      }
      const idx: number = new Date(b.occurTime).getDay();
      if (b.type === 'expense') {
        points[idx].expense += b.amount;
      } else if (b.type === 'income') {
        points[idx].income += b.amount;
      }
    }
    return points;
  }

  static categoryStats(bills: Bill[], type: string, start: number, end: number): CatStatRow[] {
    const store: Store = Store.get();
    const amounts: Map<string, number> = new Map<string, number>();
    let total: number = 0;
    for (let i: number = 0; i < bills.length; i++) {
      const b: Bill = bills[i];
      if (b.occurTime < start || b.occurTime >= end) {
        continue;
      }
      if (b.type !== type) {
        continue;
      }
      const id: string = b.subId !== '' ? b.subId : b.categoryId;
      const cur: number = amounts.get(id) ?? 0;
      amounts.set(id, cur + b.amount);
      total += b.amount;
    }
    const rows: CatStatRow[] = [];
    amounts.forEach((amount: number, id: string) => {
      const cat: Category = CategoryData.findCategory(store.categories, id);
      const row: CatStatRow = new CatStatRow();
      row.icon = cat.icon;
      row.color = cat.color;
      row.name = cat.name;
      row.amount = amount;
      row.percent = total > 0 ? amount / total : 0;
      rows.push(row);
    });
    rows.sort((a: CatStatRow, b: CatStatRow): number => b.amount - a.amount);
    return rows;
  }

  static tableRows(bills: Bill[], mode: DisplayMode, start: number, end: number): SummaryRowModel[] {
    const map: Map<string, SummaryRowModel> = new Map<string, SummaryRowModel>();
    for (let i: number = 0; i < bills.length; i++) {
      const b: Bill = bills[i];
      if (b.occurTime < start || b.occurTime >= end) {
        continue;
      }
      let key: string = '';
      let label: string = '';
      if (mode === 'year') {
        const d: Date = new Date(b.occurTime);
        const m: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString();
        key = `${d.getFullYear()}-${m}`;
        label = `${m}月`;
      } else if (mode === 'month') {
        key = DateUtil.dateKey(b.occurTime);
        label = DateUtil.dateLabel(b.occurTime);
      } else {
        key = DateUtil.dateKey(b.occurTime);
        label = `${new Date(b.occurTime).getMonth() + 1}.${new Date(b.occurTime).getDate()}`;
      }
      let row: SummaryRowModel | undefined = map.get(key);
      if (row === undefined) {
        row = new SummaryRowModel();
        row.label = label;
        map.set(key, row);
      }
      if (b.type === 'income') {
        row.income += b.amount;
      } else if (b.type === 'expense') {
        row.expense += b.amount;
      }
    }
    const keys: string[] = Array.from(map.keys()).sort((a: string, b: string): number => a < b ? 1 : -1);
    const out: SummaryRowModel[] = [];
    for (let i: number = 0; i < keys.length; i++) {
      const row: SummaryRowModel = map.get(keys[i])!;
      row.balance = row.income - row.expense;
      out.push(row);
    }
    return out;
  }
}
