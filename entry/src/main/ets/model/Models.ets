export type BillType = 'expense' | 'income' | 'transfer';
export type RefundStatus = 'none' | 'refund' | 'pending';

@ObservedV2
export class Bill {
  id: number = 0;
  bookId: number = 0;
  @Trace type: BillType = 'expense';
  @Trace amount: number = 0;
  @Trace categoryId: string = 'other_exp';
  @Trace subId: string = '';
  @Trace remark: string = '';
  @Trace occurTime: number = 0;
  @Trace account: string = '现金';
  @Trace tags: string[] = [];
  @Trace excludeStat: boolean = false;
  @Trace refundStatus: RefundStatus = 'none';
}

@ObservedV2
export class Category {
  id: string = '';
  name: string = '';
  @Trace icon: string = 'ellipsis_circle';
  @Trace color: string = '#9AA0A6';
  @Trace bg: string = '#1A9AA0A6';
  type: BillType = 'expense';
  children: Category[] = [];

  constructor(id: string, name: string, icon: string, color: string, bg: string, type: BillType) {
    this.id = id;
    this.name = name;
    this.icon = icon;
    this.color = color;
    this.bg = bg;
    this.type = type;
  }
}

@ObservedV2
export class Book {
  id: number = 0;
  @Trace name: string = '';
  @Trace budget: number = 0;

  constructor(id: number, name: string, budget: number) {
    this.id = id;
    this.name = name;
    this.budget = budget;
  }
}

export type AccountType = 'cash' | 'wechat' | 'bank';

@ObservedV2
export class AssetAccount {
  id: number = 0;
  @Trace name: string = '';
  @Trace icon: string = 'wallet';
  @Trace type: AccountType = 'cash';
  @Trace balance: number = 0;
  @Trace hidden: boolean = false;

  constructor(id: number, name: string, icon: string, type: AccountType, balance: number) {
    this.id = id;
    this.name = name;
    this.icon = icon;
    this.type = type;
    this.balance = balance;
  }
}

@ObservedV2
export class BillGroupModel {
  dateKey: string = '';
  dateLabel: string = '';
  weekLabel: string = '';
  expenseSum: number = 0;
  incomeSum: number = 0;
  bills: Bill[] = [];
  @Trace collapsed: boolean = false;
}

export class SummaryCardModel {
  kind: string = 'expense';
  title: string = '';
  icon: string = '';
  bigText: string = '';
  sub1Label: string = '';
  sub1Value: string = '';
  sub2Label: string = '';
  sub2Value: string = '';
}

export class DonutSegment {
  label: string = '';
  value: number = 0;
  color: string = '#3D7BFA';

  constructor(label: string, value: number, color: string) {
    this.label = label;
    this.value = value;
    this.color = color;
  }
}

export class BarPointModel {
  label: string = '';
  expense: number = 0;
  income: number = 0;
}

export class CatStatRow {
  icon: string = 'ellipsis_circle';
  color: string = '#9AA0A6';
  name: string = '';
  amount: number = 0;
  percent: number = 0;
}

export class SummaryRowModel {
  label: string = '';
  expense: number = 0;
  income: number = 0;
  balance: number = 0;
}
