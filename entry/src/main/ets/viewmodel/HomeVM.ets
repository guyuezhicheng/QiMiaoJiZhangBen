import { Bill, BillGroupModel, SummaryCardModel, Book } from '../model/Models';
import { CategoryData } from '../model/CategoryData';
import { Fmt } from '../model/Theme';
import { Store } from '../model/Rdb';

export type DisplayMode = 'year' | 'month' | 'week';

export class DateUtil {
  static startOfDay(ts: number): number {
    const d: Date = new Date(ts);
    return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  }

  static dateKey(ts: number): string {
    const d: Date = new Date(ts);
    const m: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString();
    const day: string = d.getDate() < 10 ? '0' + d.getDate().toString() : d.getDate().toString();
    return `${d.getFullYear()}-${m}-${day}`;
  }

  static dateLabel(ts: number): string {
    const d: Date = new Date(ts);
    const m: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString();
    const day: string = d.getDate() < 10 ? '0' + d.getDate().toString() : d.getDate().toString();
    return `${m}月${day}日`;
  }

  static mdLabel(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getMonth() + 1}月${d.getDate()}日`;
  }

  static weekLabel(ts: number): string {
    const names: string[] = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return names[new Date(ts).getDay()];
  }

  static hhmm(ts: number): string {
    const d: Date = new Date(ts);
    const h: string = d.getHours() < 10 ? '0' + d.getHours().toString() : d.getHours().toString();
    const m: string = d.getMinutes() < 10 ? '0' + d.getMinutes().toString() : d.getMinutes().toString();
    return `${h}:${m}`;
  }

  static weekIndexInYear(ts: number): number {
    const d: Date = new Date(ts);
    const start: Date = new Date(d.getFullYear(), 0, 1);
    const diff: number = DateUtil.startOfDay(ts) - start.getTime();
    return Math.floor(diff / 86400000 / 7) + 1;
  }
}

export class PeriodRange {
  start: number = 0;
  end: number = 0;

  constructor(start: number, end: number) {
    this.start = start;
    this.end = end;
  }
}

export class HomePeriod {
  static rangeOf(mode: DisplayMode, anchor: number): PeriodRange {
    const d: Date = new Date(anchor);
    if (mode === 'year') {
      return new PeriodRange(new Date(d.getFullYear(), 0, 1).getTime(),
        new Date(d.getFullYear() + 1, 0, 1).getTime());
    }
    if (mode === 'month') {
      return new PeriodRange(new Date(d.getFullYear(), d.getMonth(), 1).getTime(),
        new Date(d.getFullYear(), d.getMonth() + 1, 1).getTime());
    }
    const day: number = d.getDay();
    const start: number = DateUtil.startOfDay(anchor) - day * 86400000;
    return new PeriodRange(start, start + 7 * 86400000);
  }

  static step(mode: DisplayMode, anchor: number, dir: number): number {
    const d: Date = new Date(anchor);
    if (mode === 'year') {
      return new Date(d.getFullYear() + dir, d.getMonth(), 1).getTime();
    }
    if (mode === 'month') {
      return new Date(d.getFullYear(), d.getMonth() + dir, 1).getTime();
    }
    return anchor + dir * 7 * 86400000;
  }

  static title(mode: DisplayMode, anchor: number): string {
    const d: Date = new Date(anchor);
    if (mode === 'year') {
      return `${d.getFullYear()}年`;
    }
    if (mode === 'month') {
      const m: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString();
      return `${d.getFullYear()}年${m}月`;
    }
    const range: PeriodRange = HomePeriod.rangeOf('week', anchor);
    return `${DateUtil.mdLabel(range.start)} ~ ${DateUtil.mdLabel(range.end - 86400000)}`;
  }

  static modeLabel(mode: DisplayMode): string {
    if (mode === 'year') {
      return '按年显示';
    }
    if (mode === 'month') {
      return '按月显示';
    }
    return '按周显示';
  }
}

export class HomeCalc {
  static filterBills(mode: DisplayMode, anchor: number, bookId: number, searchText: string): Bill[] {
    const range: PeriodRange = HomePeriod.rangeOf(mode, anchor);
    const store: Store = Store.get();
    return store.bills.filter((b: Bill): boolean => {
      if (b.bookId !== bookId) {
        return false;
      }
      if (b.occurTime < range.start || b.occurTime >= range.end) {
        return false;
      }
      if (searchText.length > 0) {
        const cat = CategoryData.findCategory(store.categories, b.subId !== '' ? b.subId : b.categoryId);
        const hit: boolean = b.remark.indexOf(searchText) >= 0 || cat.name.indexOf(searchText) >= 0;
        if (!hit) {
          return false;
        }
      }
      return true;
    });
  }

  static buildGroups(bills: Bill[]): BillGroupModel[] {
    const map: Map<string, BillGroupModel> = new Map<string, BillGroupModel>();
    for (let i: number = 0; i < bills.length; i++) {
      const b: Bill = bills[i];
      const key: string = DateUtil.dateKey(b.occurTime);
      let g: BillGroupModel | undefined = map.get(key);
      if (g === undefined) {
        g = new BillGroupModel();
        g.dateKey = key;
        g.dateLabel = DateUtil.dateLabel(b.occurTime);
        g.weekLabel = DateUtil.weekLabel(b.occurTime);
        map.set(key, g);
      }
      if (b.type === 'income') {
        g.incomeSum += b.amount;
      } else {
        g.expenseSum += b.amount;
      }
      g.bills.push(b);
    }
    const keys: string[] = Array.from(map.keys()).sort((a: string, b: string): number => a < b ? 1 : -1);
    const out: BillGroupModel[] = [];
    for (let i: number = 0; i < keys.length; i++) {
      out.push(map.get(keys[i])!);
    }
    return out;
  }

  static buildCards(mode: DisplayMode, anchor: number, bills: Bill[]): SummaryCardModel[] {
    let expense: number = 0;
    let income: number = 0;
    let pendingRefund: number = 0;
    for (let i: number = 0; i < bills.length; i++) {
      const b: Bill = bills[i];
      if (b.type === 'income') {
        income += b.amount;
      } else if (b.type === 'expense') {
        expense += b.amount;
      }
      if (b.refundStatus === 'pending') {
        pendingRefund += b.amount;
      }
    }
    const balance: number = income - expense;
    const store: Store = Store.get();
    let budget: number = 0;
    if (store.books.length > 0) {
      budget = store.books[0].budget;
    }
    const range: PeriodRange = HomePeriod.rangeOf(mode, anchor);
    const days: number = Math.max(1, Math.round((range.end - range.start) / 86400000));

    const cards: SummaryCardModel[] = [];

    const cExpense: SummaryCardModel = new SummaryCardModel();
    cExpense.kind = 'expense';
    cExpense.title = '支出';
    cExpense.icon = 'arrow_up_circle';
    cExpense.bigText = Fmt.signedMoney(-expense, false);
    cExpense.sub1Label = '收入';
    cExpense.sub1Value = '¥' + Fmt.yuanStr(income);
    cExpense.sub2Label = '结余';
    cExpense.sub2Value = Fmt.money(balance);
    cards.push(cExpense);

    const cBudget: SummaryCardModel = new SummaryCardModel();
    cBudget.kind = 'budget';
    cBudget.title = '预算';
    cBudget.icon = 'calculator';
    const remain: number = budget - expense;
    const usedPct: number = budget > 0 ? Math.round(expense / budget * 100) : 0;
    cBudget.bigText = Fmt.signedMoney(remain, false);
    cBudget.sub1Label = '总预算';
    cBudget.sub1Value = '¥' + Fmt.yuanStr(budget);
    cBudget.sub2Label = '已用';
    cBudget.sub2Value = `${usedPct}%`;
    cards.push(cBudget);

    const cBalance: SummaryCardModel = new SummaryCardModel();
    cBalance.kind = 'balance';
    cBalance.title = '结余';
    cBalance.icon = 'wallet';
    cBalance.bigText = Fmt.signedMoney(balance, true);
    cBalance.sub1Label = '日均支出';
    cBalance.sub1Value = '¥' + Fmt.yuanStr(Math.round(expense / days));
    cBalance.sub2Label = '待报销';
    cBalance.sub2Value = '¥' + Fmt.yuanStr(pendingRefund);
    cards.push(cBalance);

    const cIncome: SummaryCardModel = new SummaryCardModel();
    cIncome.kind = 'income';
    cIncome.title = '收入';
    cIncome.icon = 'arrow_down_circle';
    cIncome.bigText = Fmt.signedMoney(income, true);
    cIncome.sub1Label = '支出';
    cIncome.sub1Value = '¥' + Fmt.yuanStr(expense);
    cIncome.sub2Label = '结余';
    cIncome.sub2Value = Fmt.money(balance);
    cards.push(cIncome);

    return cards;
  }

  static allBillIds(groups: BillGroupModel[]): number[] {
    const ids: number[] = [];
    for (let i: number = 0; i < groups.length; i++) {
      const g: BillGroupModel = groups[i];
      for (let j: number = 0; j < g.bills.length; j++) {
        ids.push(g.bills[j].id);
      }
    }
    return ids;
  }
}
